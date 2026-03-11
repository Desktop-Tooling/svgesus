/**
 * SVG Thumbnail Provider: COM IInitializeWithStream + IThumbnailProvider.
 * Single vtable; we always return the same this pointer from QI.
 */
module thumbnail_handler;

import core.sys.windows.windows;
import core.stdc.string;
import core.stdc.stdlib;
import nanosvg_bind;

// GUIDs
immutable GUID IID_IUnknown_GUID = { 0x00000000, 0x0000, 0x0000, [ 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 ] };
immutable GUID IID_IInitializeWithStream_GUID = { 0xB824B49D, 0x22AC, 0x4161, [ 0xAC, 0x8A, 0x99, 0x16, 0xB8, 0xCE, 0x96, 0xFF ] };
immutable GUID IID_IThumbnailProvider_GUID = { 0xE357FCCD, 0xA995, 0x4576, [ 0xB0, 0x1F, 0x23, 0x46, 0x30, 0x15, 0x4E, 0x96 ] };
immutable GUID CLSID_SvgThumbnailProvider_GUID = { 0xB8D43B9D, 0x2A1E, 0x4F3C, [ 0x8D, 0x5E, 0x6A, 0x7B, 0x8C, 0x9D, 0x0E, 0x1F ] };
immutable GUID IID_IClassFactory_GUID = { 0x00000001, 0x0000, 0x0000, [ 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 ] };

enum WTSAT_UNKNOWN = 0;
enum WTSAT_ARGB = 2;

// Provider object: vtable ptr then our data
struct SvgProvider {
    void* vtbl;
    LONG refCount;
    ubyte* svgData;
    size_t svgLen;
    NSVGrasterizer rast;
}

// One vtable: QI, AddRef, Release, Initialize, GetThumbnail
__gshared void*[5] g_providerVtbl;

static this() {
    g_providerVtbl[0] = &providerQueryInterface;
    g_providerVtbl[1] = &providerAddRef;
    g_providerVtbl[2] = &providerRelease;
    g_providerVtbl[3] = &providerInitialize;
    g_providerVtbl[4] = &providerGetThumbnail;
}

private int guidEquals(const GUID* a, const GUID* b) {
    return (a.data1 == b.data1 && a.data2 == b.data2 && a.data3 == b.data3 &&
        a.data4[0] == b.data4[0] && a.data4[1] == b.data4[1] && a.data4[2] == b.data4[2] && a.data4[3] == b.data4[3] &&
        a.data4[4] == b.data4[4] && a.data4[5] == b.data4[5] && a.data4[6] == b.data4[6] && a.data4[7] == b.data4[7]) ? 1 : 0;
}

extern(Windows) HRESULT providerQueryInterface(void* thisPtr, const GUID* riid, void** ppv) {
    if (ppv is null) return E_POINTER;
    *ppv = null;
    SvgProvider* p = cast(SvgProvider*)thisPtr;
    if (guidEquals(riid, &IID_IUnknown_GUID) || guidEquals(riid, &IID_IInitializeWithStream_GUID) || guidEquals(riid, &IID_IThumbnailProvider_GUID)) {
        *ppv = thisPtr;
        InterlockedIncrement(&p.refCount);
        return S_OK;
    }
    return E_NOINTERFACE;
}
extern(Windows) ULONG providerAddRef(void* thisPtr) {
    return InterlockedIncrement(&(cast(SvgProvider*)thisPtr).refCount);
}
extern(Windows) ULONG providerRelease(void* thisPtr) {
    SvgProvider* p = cast(SvgProvider*)thisPtr;
    LONG r = InterlockedDecrement(&p.refCount);
    if (r == 0) {
        if (p.svgData) free(p.svgData);
        if (p.rast) nsvgDeleteRasterizer(p.rast);
        free(p);
    }
    return r;
}

// IStream::Stat and Read - use vtable indices (Read=3, Stat=12 typically)
extern(Windows) HRESULT providerInitialize(void* thisPtr, void* pstream, DWORD grfMode) {
    SvgProvider* p = cast(SvgProvider*)thisPtr;
    if (pstream is null) return E_INVALIDARG;
    alias StatFn = HRESULT function(void* self, void* pstatstg, DWORD grfStatFlag);
    alias ReadFn = HRESULT function(void* self, void* pv, ULONG cb, ULONG* pcbRead);
    void** vt = cast(void**)pstream;
    // IStream vtable: 0 QI, 1 AddRef, 2 Release, 3 Read, 4 Write, 5 Seek, ... 12 Stat
    ReadFn readFn = cast(ReadFn)vt[3];
    StatFn statFn = cast(StatFn)vt[12];
    ubyte[72] statstgBuf = void;
    if (statFn(pstream, &statstgBuf[0], 0) != S_OK) return E_FAIL;
    // STATSTG.cbSize is LARGE_INTEGER at offset 16 (after pwcsName pointer + DWORD type)
    ULONGLONG* pcb = cast(ULONGLONG*)(&statstgBuf[0] + 16);
    ULONGLONG cb = *pcb;
    if (cb <= 0 || cb > 0x7FFF_FFFF) return E_FAIL;
    size_t n = cast(size_t)cb;
    if (p.svgData) free(p.svgData);
    p.svgData = cast(ubyte*)malloc(n + 1);
    if (p.svgData is null) return E_OUTOFMEMORY;
    p.svgData[n] = 0;
    ULONG read;
    if (readFn(pstream, p.svgData, cast(ULONG)n, &read) != S_OK || read != cast(ULONG)n) {
        free(p.svgData);
        p.svgData = null;
        return E_FAIL;
    }
    p.svgLen = n;
    return S_OK;
}

private float getSvgWidth(NSVGimage img) { return (cast(float*)img)[0]; }
private float getSvgHeight(NSVGimage img) { return (cast(float*)img)[1]; }

private HBITMAP createBitmapFromRgba(ubyte* rgba, int w, int h, int stride) {
    BITMAPINFO bmi = void;
    bmi.bmiHeader.biSize = BITMAPINFOHEADER.sizeof;
    bmi.bmiHeader.biWidth = w;
    bmi.bmiHeader.biHeight = -h;
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;
    void* bits = null;
    HBITMAP hbm = CreateDIBSection(null, &bmi, DIB_RGB_COLORS, &bits, null, 0);
    if (hbm is null || bits is null) return null;
    int dstStride = (w * 4 + 3) & ~3;
    for (int y = 0; y < h; y++) {
        ubyte* src = rgba + y * stride;
        ubyte* dst = cast(ubyte*)bits + y * dstStride;
        for (int x = 0; x < w; x++) {
            dst[0] = src[2]; dst[1] = src[1]; dst[2] = src[0]; dst[3] = src[3];
            src += 4; dst += 4;
        }
    }
    return hbm;
}

extern(Windows) HRESULT providerGetThumbnail(void* thisPtr, UINT cx, HBITMAP* phbmp, uint* pdwAlpha) {
    SvgProvider* p = cast(SvgProvider*)thisPtr;
    if (phbmp is null || pdwAlpha is null) return E_POINTER;
    *phbmp = null;
    *pdwAlpha = WTSAT_UNKNOWN;
    if (p.svgData is null || p.svgLen == 0) return E_FAIL;

    char* str = cast(char*)p.svgData;
    NSVGimage img = nsvgParse(str, "px".ptr, 96);
    if (img is null) return E_FAIL;
    scope(exit) nsvgDelete(img);

    float w = getSvgWidth(img);
    float h = getSvgHeight(img);
    if (w <= 0 || h <= 0) return E_FAIL;
    float scale = cast(float)cx / (w > h ? w : h);
    if (scale > 1) scale = 1;
    int outW = cast(int)(w * scale);
    int outH = cast(int)(h * scale);
    if (outW < 1) outW = 1;
    if (outH < 1) outH = 1;

    int stride = (outW * 4 + 3) & ~3;
    ubyte* pixels = cast(ubyte*)malloc(stride * outH);
    if (pixels is null) return E_OUTOFMEMORY;
    scope(exit) free(pixels);
    nsvgRasterize(p.rast, img, 0, 0, scale, pixels, outW, outH, stride);

    HBITMAP hbm = createBitmapFromRgba(pixels, outW, outH, stride);
    if (hbm is null) return E_FAIL;
    *phbmp = hbm;
    *pdwAlpha = WTSAT_ARGB;
    return S_OK;
}

SvgProvider* createSvgProvider() {
    SvgProvider* p = cast(SvgProvider*)malloc(SvgProvider.sizeof);
    if (p is null) return null;
    memset(p, 0, SvgProvider.sizeof);
    p.vtbl = &g_providerVtbl[0];
    p.refCount = 1;
    p.rast = nsvgCreateRasterizer();
    if (p.rast is null) { free(p); return null; }
    return p;
}

// Class factory for DllGetClassObject
struct ClassFactory {
    void* vtbl;
    LONG refCount;
}
__gshared void*[5] g_factoryVtbl;
__gshared ClassFactory g_factory;

extern(Windows) HRESULT factoryQueryInterface(void* thisPtr, const GUID* riid, void** ppv) {
    if (ppv is null) return E_POINTER;
    *ppv = null;
    if (guidEquals(riid, &IID_IUnknown_GUID) || guidEquals(riid, &IID_IClassFactory_GUID)) {
        *ppv = thisPtr;
        InterlockedIncrement(&g_factory.refCount);
        return S_OK;
    }
    return E_NOINTERFACE;
}
extern(Windows) ULONG factoryAddRef(void* thisPtr) { return InterlockedIncrement(&g_factory.refCount); }
extern(Windows) ULONG factoryRelease(void* thisPtr) { return InterlockedDecrement(&g_factory.refCount); }
extern(Windows) HRESULT factoryCreateInstance(void* thisPtr, void* pUnkOuter, const GUID* riid, void** ppv) {
    if (pUnkOuter !is null) return CLASS_E_NOAGGREGATION;
    SvgProvider* p = createSvgProvider();
    if (p is null) return E_OUTOFMEMORY;
    HRESULT hr = providerQueryInterface(p, riid, ppv);
    if (hr != S_OK) providerRelease(p);
    return hr;
}
extern(Windows) HRESULT factoryLockServer(void* thisPtr, BOOL fLock) { return S_OK; }

static this() {
    g_factoryVtbl[0] = &factoryQueryInterface;
    g_factoryVtbl[1] = &factoryAddRef;
    g_factoryVtbl[2] = &factoryRelease;
    g_factoryVtbl[3] = &factoryCreateInstance;
    g_factoryVtbl[4] = &factoryLockServer;
    g_factory.vtbl = &g_factoryVtbl[0];
    g_factory.refCount = 1;
}

GUID getClsidSvgThumbnailProvider() { return CLSID_SvgThumbnailProvider_GUID; }
void* getClassFactory() { return &g_factory; }
