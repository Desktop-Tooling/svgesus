/**
 * svgesus DLL entry points: DllGetClassObject, DllCanUnloadNow, DllRegisterServer, DllUnregisterServer.
 */
module app;

import core.sys.windows.windows;
import core.stdc.stdio;
import core.stdc.string;
import core.stdc.wchar_;
import thumbnail_handler;

// DLL ref count for DllCanUnloadNow (we don't lock server, so 0 when no active objects)
__gshared LONG g_lockCount = 0;

export extern(Windows) BOOL DllMain(HINSTANCE hinstDLL, DWORD fdwReason, void* lpvReserved) {
    if (fdwReason == DLL_PROCESS_ATTACH)
        DisableThreadLibraryCalls(hinstDLL);
    return TRUE;
}

export extern(Windows) HRESULT DllGetClassObject(const GUID* rclsid, const GUID* riid, void** ppv) {
    if (ppv is null) return E_POINTER;
    *ppv = null;
    immutable GUID clsid = getClsidSvgThumbnailProvider();
    if (rclsid.data1 != clsid.data1 || rclsid.data2 != clsid.data2 || rclsid.data3 != clsid.data3)
        return CLASS_E_CLASSNOTAVAILABLE;
    for (int i = 0; i < 8; i++)
        if (rclsid.data4[i] != clsid.data4[i]) return CLASS_E_CLASSNOTAVAILABLE;
    void* factory = getClassFactory();
    return factoryQueryInterface(factory, riid, ppv);
}

export extern(Windows) HRESULT DllCanUnloadNow() {
    return (g_lockCount == 0) ? S_OK : S_FALSE;
}

// Registry helpers
private void setRegStr(HKEY hk, const wchar* name, const wchar* value) {
    size_t len = (wcslen(value) + 1) * 2;
    RegSetValueExW(hk, name, 0, REG_SZ, cast(const ubyte*)value, cast(DWORD)len);
}

private void registerServer() {
    wchar[64] clsidStr;
    GUID c = getClsidSvgThumbnailProvider();
    swprintf(&clsidStr[0], 64, "{%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X}",
        c.data1, c.data2, c.data3,
        c.data4[0], c.data4[1], c.data4[2], c.data4[3],
        c.data4[4], c.data4[5], c.data4[6], c.data4[7]);
    wchar[256] keyPath;
    swprintf(&keyPath[0], 256, "CLSID\\%s", &clsidStr[0]);
    HKEY hkClsid;
    if (RegCreateKeyExW(HKEY_CLASSES_ROOT, &keyPath[0], 0, null, 0, KEY_WRITE, null, &hkClsid, null) != 0)
        return;
    wchar[MAX_PATH] dllPath;
    GetModuleFileNameW(null, &dllPath[0], MAX_PATH);
    setRegStr(hkClsid, null, "svgesus SVG Thumbnail Provider");
    HKEY hkInproc;
    if (RegCreateKeyExW(hkClsid, "InprocServer32", 0, null, 0, KEY_WRITE, null, &hkInproc, null) == 0) {
        setRegStr(hkInproc, null, &dllPath[0]);
        setRegStr(hkInproc, "ThreadingModel", "Apartment");
        RegCloseKey(hkInproc);
    }
    RegCloseKey(hkClsid);
    // Disable process isolation so we can use in-proc (optional; remove for out-of-proc)
    HKEY hkOpt;
    if (RegOpenKeyExW(HKEY_CLASSES_ROOT, &keyPath[0], 0, KEY_WRITE, &hkOpt) == 0) {
        DWORD one = 1;
        RegSetValueExW(hkOpt, "DisableProcessIsolation", 0, REG_DWORD, cast(ubyte*)&one, 4);
        RegCloseKey(hkOpt);
    }
    // Associate .svg with our handler: .svg -> svgfile -> ShellEx handler
    HKEY hkSvg;
    if (RegOpenKeyExW(HKEY_CLASSES_ROOT, ".svg", 0, KEY_READ, &hkSvg) == 0) {
        wchar[64] defaultVal;
        DWORD len = 64 * 2;
        if (RegQueryValueExW(hkSvg, null, null, null, cast(ubyte*)&defaultVal[0], &len) == 0) {
            RegCloseKey(hkSvg);
            wchar[256] shellexPath;
            swprintf(&shellexPath[0], 256, "%s\\ShellEx\\%s", &defaultVal[0], "{E357FCCD-A995-4576-B01F-234630154E96}");
            HKEY hkHandler;
            if (RegCreateKeyExW(HKEY_CLASSES_ROOT, &shellexPath[0], 0, null, 0, KEY_WRITE, null, &hkHandler, null) == 0) {
                setRegStr(hkHandler, null, &clsidStr[0]);
                RegCloseKey(hkHandler);
            }
            return;
        }
        RegCloseKey(hkSvg);
    }
    // If .svg has no default, use "svgfile"
    HKEY hkSvgFile;
    if (RegCreateKeyExW(HKEY_CLASSES_ROOT, "svgfile\\ShellEx\\{E357FCCD-A995-4576-B01F-234630154E96}", 0, null, 0, KEY_WRITE, null, &hkSvgFile, null) == 0) {
        setRegStr(hkSvgFile, null, &clsidStr[0]);
        RegCloseKey(hkSvgFile);
    }
    HKEY hkDotSvg;
    if (RegOpenKeyExW(HKEY_CLASSES_ROOT, ".svg", 0, KEY_WRITE, &hkDotSvg) == 0) {
        setRegStr(hkDotSvg, null, "svgfile");
        RegCloseKey(hkDotSvg);
    }
}

private void unregisterServer() {
    wchar[64] clsidStr;
    GUID c = getClsidSvgThumbnailProvider();
    swprintf(&clsidStr[0], 64, "{%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X}",
        c.data1, c.data2, c.data3,
        c.data4[0], c.data4[1], c.data4[2], c.data4[3],
        c.data4[4], c.data4[5], c.data4[6], c.data4[7]);
    wchar[256] keyPath;
    swprintf(&keyPath[0], 256, "CLSID\\%s", &clsidStr[0]);
    RegDeleteTreeW(HKEY_CLASSES_ROOT, &keyPath[0]);
    wchar[256] shellexPath;
    swprintf(&shellexPath[0], 256, "svgfile\\ShellEx\\%s", "{E357FCCD-A995-4576-B01F-234630154E96}");
    RegDeleteTreeW(HKEY_CLASSES_ROOT, &shellexPath[0]);
}

export extern(Windows) HRESULT DllRegisterServer() {
    registerServer();
    return S_OK;
}

export extern(Windows) HRESULT DllUnregisterServer() {
    unregisterServer();
    return S_OK;
}
