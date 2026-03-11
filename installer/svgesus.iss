[Setup]
AppId={{2F9A4F4C-8F73-4A9B-9B1B-7C2D3A4B5C6D}
AppName=svgesus (SVG Jesus)
AppVersion=1.0.0
AppPublisher=AMDphreak
DefaultDirName={autopf}\svgesus
DefaultGroupName=svgesus
DisableDirPage=yes
DisableProgramGroupPage=yes
OutputBaseFilename=svgesus-setup-x64
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64
Compression=lzma
SolidCompression=yes

[Files]
; Install the 64-bit DLL and automatically call DllRegisterServer / DllUnregisterServer
Source: "..\bin\svgesus.dll"; DestDir: "{app}"; Flags: regserver uninsregserver ignoreversion

[Icons]
; No start menu icon needed; this is a shell extension only.

[Run]
; Nothing to run; registration is handled by regserver flag.

