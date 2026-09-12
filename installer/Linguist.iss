#ifndef SourceDir
  #error SourceDir must point to the staged application directory
#endif
#ifndef OutputDir
  #define OutputDir "..\artifacts"
#endif
#ifndef AppVersion
  #define AppVersion "0.2.0"
#endif

[Setup]
AppId={{9CF921A5-0B4B-4F54-AF18-12F7B8745E31}
AppName=Linguist
AppVersion={#AppVersion}
AppPublisher=Linguist
AppPublisherURL=https://github.com/musuixin01/lingust-desktop
AppSupportURL=https://github.com/musuixin01/lingust-desktop/issues
DefaultDirName={localappdata}\Programs\Linguist
DefaultGroupName=Linguist
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=Linguist-Setup-{#AppVersion}-win64
SetupIconFile=..\resources\app.ico
UninstallDisplayIcon={app}\app.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
ChangesAssociations=no
VersionInfoVersion={#AppVersion}.0
VersionInfoProductName=Linguist
VersionInfoDescription=Linguist desktop translator installer
VersionInfoCompany=Linguist
VersionInfoCopyright=Copyright (c) 2026 Linguist contributors

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加快捷方式："; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Linguist"; Filename: "{app}\lingust.exe"; WorkingDir: "{app}"; IconFilename: "{app}\app.ico"
Name: "{autodesktop}\Linguist"; Filename: "{app}\lingust.exe"; WorkingDir: "{app}"; IconFilename: "{app}\app.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\lingust.exe"; Description: "启动 Linguist"; Flags: nowait postinstall skipifsilent
