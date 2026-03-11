/**
 * D bindings to NanoSVG C API (parser + rasterizer).
 * NanoSVG headers must be in vendor/nanosvg/ and built via nanosvg_impl.c.
 */
module nanosvg_bind;

extern(C):

// Opaque types (structs are in C headers)
alias NSVGimage = void*;
alias NSVGrasterizer = void*;

// Parser
NSVGimage nsvgParseFromFile(const char* filename, const char* units, float dpi);
NSVGimage nsvgParse(char* input, const char* units, float dpi);
void nsvgDelete(NSVGimage image);

// Rasterizer
NSVGrasterizer nsvgCreateRasterizer();
void nsvgRasterize(NSVGrasterizer rast, NSVGimage image, float tx, float ty, float scale,
    ubyte* dst, int w, int h, int stride);
void nsvgDeleteRasterizer(NSVGrasterizer rast);
