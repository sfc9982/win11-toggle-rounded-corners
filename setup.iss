; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Win11 Toggle Rounded Corners"
#define MyAppVersion "1.3"
#define MyAppPublisher "oberrich, sfc9982"
#define MyAppURL "https://github.com/sfc9982/win11-toggle-rounded-corners"

[Setup]
AppId={{F26B8DCE-5C19-4A98-A136-E343BF325C85}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
AppCopyright=Copyright (C) 2024 oberrich, MIT License
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=LICENSE
PrivilegesRequired=admin
OutputBaseFilename=win11-toggle-rounded-corners-setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
MissingRunOnceIdsWarning=no
OutputDir=build

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Place any regular files here
Source: "LICENSE"; DestDir: "{app}";
Source: "build\win11-toggle-rounded-corners.exe"; DestDir: "{app}"

[Run]
Filename: "schtasks"; \
  Parameters: "/Create /F /RL highest /SC onlogon /TN ""Run win11-toggle-rounded-corners as admin on logon"" /TR ""'{app}\win11-toggle-rounded-corners.exe' --disable"""; \
  Description: "Automatically run on logon"; \
  Flags: runhidden runascurrentuser postinstall
Filename: "{app}\win11-toggle-rounded-corners.exe"; \
  Description: "Run now"; \
  Parameters: "--disable"; \
  Flags: runhidden runascurrentuser nowait postinstall

[UninstallRun]
Filename: "schtasks"; \
  Parameters: "/Delete /F /TN ""Run win11-toggle-rounded-corners as admin on logon"""; \
  Flags: runhidden runascurrentuser
