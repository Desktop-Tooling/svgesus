/**
 * Simple performance runner for svgesus / NanoSVG.
 *
 * Builds an executable via: dub build --config=perf [--compiler=ldc2]
 * It scans tests/svg-samples for .svg files and measures parse+raster time.
 */
module tests.perf_runner;

import std.file : dirEntries, SpanMode, isFile;
import std.path : extension;
import std.stdio : writeln;
import std.datetime.stopwatch : StopWatch;
import std.algorithm : filter, map, sum;
import std.array : array;
import std.conv : to;
import std.string : toStringz;

import nanosvg_bind;

void main() {
    enum samplesDir = "tests/svg-samples";
    auto entries = dirEntries(samplesDir, SpanMode.breadth)
        .filter!(e => e.isFile && e.name.extension.toLower == ".svg")
        .array;

    if (entries.length == 0) {
        writeln("No SVG files in ", samplesDir, ". Run scripts/collect_svgs.ps1 first.");
        return;
    }

    writeln("Found ", entries.length, " SVG files. Running perf test...");

    auto swTotal = StopWatch(AutoStart.yes);
    double[] timesMs;
    timesMs.length = entries.length;

    foreach (i, e; entries) {
        auto sw = StopWatch(AutoStart.yes);

        // Parse from file and rasterize at a fixed max size (e.g. 256)
        NSVGimage img = nsvgParseFromFile(e.name.toStringz.ptr, "px".ptr, 96);
        if (img is null) {
            writeln("Failed parse: ", e.name);
            continue;
        }
        scope(exit) nsvgDelete(img);

        // Read width/height from NSVGimage (first two floats)
        float w = (cast(float*)img)[0];
        float h = (cast(float*)img)[1];
        if (w <= 0 || h <= 0) {
            writeln("Bad size: ", e.name);
            continue;
        }
        float maxSide = w > h ? w : h;
        float scale = 256.0f / maxSide;

        int outW = cast(int)(w * scale);
        int outH = cast(int)(h * scale);
        if (outW < 1) outW = 1;
        if (outH < 1) outH = 1;

        auto stride = (outW * 4 + 3) & ~3;
        ubyte[] pixels;
        pixels.length = stride * outH;

        NSVGrasterizer rast = nsvgCreateRasterizer();
        if (rast is null) {
            writeln("No rasterizer: ", e.name);
            continue;
        }
        scope(exit) nsvgDeleteRasterizer(rast);

        nsvgRasterize(rast, img, 0, 0, scale, pixels.ptr, outW, outH, cast(int)stride);

        auto dt = sw.peek.total!"msecs";
        timesMs[i] = dt;
    }

    auto totalMs = swTotal.peek.total!"msecs";
    auto valid = timesMs.filter!(t => t > 0).array;
    double avgMs = valid.length ? valid.sum / valid.length : 0;

    writeln("Total time: ", totalMs, " ms");
    writeln("Average per SVG: ", avgMs, " ms (", valid.length, " successful)");
}

