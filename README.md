<a id="readme-top"></a>
<div align="center">
  <a href="https://github.com/AMDphreak/svgesus/graphs/contributors"><img src="https://img.shields.io/github/contributors/AMDphreak/svgesus.svg?style=for-the-badge" alt="Contributors"></a>
  <a href="https://github.com/AMDphreak/svgesus/network/members"><img src="https://img.shields.io/github/forks/AMDphreak/svgesus.svg?style=for-the-badge" alt="Forks"></a>
  <a href="https://github.com/AMDphreak/svgesus/stargazers"><img src="https://img.shields.io/github/stars/AMDphreak/svgesus.svg?style=for-the-badge" alt="Stargazers"></a>
  <a href="https://github.com/AMDphreak/svgesus/issues"><img src="https://img.shields.io/github/issues/AMDphreak/svgesus.svg?style=for-the-badge" alt="Issues"></a>

  <h1>svgesus — SVG Jesus</h1>
  <p>Windows SVG thumbnail shell extension (D + NanoSVG). Implements COM <code>IThumbnailProvider</code> + <code>IInitializeWithStream</code>.</p>
  <p>
    <a href="https://desktop-tooling.github.io/docs/svgesus/"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/AMDphreak/svgesus/issues">Report Bug</a>
    &middot;
    <a href="https://github.com/AMDphreak/svgesus/issues">Request Feature</a>
  </p>
</div>

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

## About The Project

Thread-safe thumbnail provider designed so Windows can cache SVG previews consistently. Rasterization uses NanoSVG (C); the shell extension is written in D.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

* **Shell extension** — [![D][Dlang.org]][Dlang-url] (dmd / ldc)
* **Rasterization** — [![NanoSVG][NanoSVG.badge]][NanoSVG-url] (C)
* **Toolchain** — Visual Studio Build Tools (`cl`)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Getting Started

### Prerequisites

* Windows 10/11 x64
* D compiler (dmd or ldc)
* Visual Studio Build Tools with `cl` in PATH
* Run once: `scripts/fetch_nanosvg.ps1` to download NanoSVG headers

Optional Build Tools install:

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools -e
```

### Build

```powershell
.\scripts\fetch_nanosvg.ps1
dub build
# Optional:
.\scripts\build_dmd.ps1
.\scripts\build_llvm.ps1
```

Output: `bin/svgesus.dll`.

### Install (manual)

1. Copy `bin/svgesus.dll` to a permanent location (e.g. `C:\Program Files\svgesus\svgesus.dll`).
2. Run as Administrator: `regsvr32 "C:\Program Files\svgesus\svgesus.dll"`.
3. Restart Explorer or log off and back on.

Uninstall: `regsvr32 /u "C:\Program Files\svgesus\svgesus.dll"` (as Admin).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

After registration, SVG files should show thumbnails in Explorer. If caching fails:

* Handler may be failing intermittently (Explorer skips cache).
* OneDrive Files On-Demand can block local thumbnail generation.
* Folder Options → View → ensure “Always show icons, never thumbnails” is unchecked.

Registered with `DisableProcessIsolation = 1` for in-process reliability.

See `docs/LANGUAGE_CHOICE.adoc` for language/design notes.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contributing

Fork, branch, and open a pull request.

### Top contributors

<a href="https://github.com/AMDphreak/svgesus/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=AMDphreak/svgesus" alt="contributors" />
</a>

For per-person profile links, prefer [all-contributors](https://allcontributors.org/).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the project history.

## License

MIT.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

Ryan Johnson — [@amdphreak](https://twitter.com/amdphreak)

Project Link: [https://github.com/AMDphreak/svgesus](https://github.com/AMDphreak/svgesus)

Site: [https://ryanjohnson.dev](https://ryanjohnson.dev)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
[Dlang.org]: https://img.shields.io/badge/D-B03931?style=for-the-badge&logo=d&logoColor=white
[Dlang-url]: https://dlang.org/
[NanoSVG.badge]: https://img.shields.io/badge/NanoSVG-00599C?style=for-the-badge&logo=c&logoColor=white
[NanoSVG-url]: https://github.com/memononen/nanosvg
