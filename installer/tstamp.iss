; TStamp Windows installer (Inno Setup 6).
; Build:  ISCC.exe /DMyAppVersion=0.1.0 installer\tstamp.iss
; Run installer/stage.sh first: it fills dist\stage with the files to install.

#ifndef MyAppVersion
  #define MyAppVersion "0.1.0-dev"
#endif
; The numeric part of the version, for the file properties: 0.2.0 gives 0.2.0, 0.2.0-rc1 gives 0.2.0.
#define MyBaseVersion Copy(MyAppVersion, 1, Pos("-", MyAppVersion + "-") - 1)

[Setup]
AppId={{7C2D9E41-5B3A-4F68-9E0D-A1B4C6D8E2F3}
AppName=TStamp
AppVersion={#MyAppVersion}
AppPublisher=abinaze
AppPublisherURL=https://github.com/abinaze/tstamp
AppSupportURL=https://github.com/abinaze/tstamp/issues
DefaultDirName={autopf}\TStamp
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=yes
PrivilegesRequired=lowest
ChangesEnvironment=yes
OutputDir=..\dist
OutputBaseFilename=tstamp-windows-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=TStamp
UninstallDisplayIcon={app}\tstamp.ico
SetupIconFile=assets\tstamp.ico
WizardImageFile=assets\wizard-100.bmp,assets\wizard-125.bmp,assets\wizard-150.bmp,assets\wizard-200.bmp
WizardSmallImageFile=assets\small-100.bmp,assets\small-125.bmp,assets\small-150.bmp,assets\small-200.bmp
DisableWelcomePage=no
LicenseFile=..\LICENSE
AppCopyright=Copyright (c) 2026 Abinaze Binoy
VersionInfoVersion={#MyBaseVersion}.0
VersionInfoCompany=abinaze
VersionInfoProductName=TStamp
VersionInfoDescription=TStamp Setup
VersionInfoCopyright=Copyright (c) 2026 Abinaze Binoy

[Messages]
WelcomeLabel1=Welcome to TStamp
WelcomeLabel2=TStamp prints a START and an END line around every command in your terminal, with the exit code and how long it took.%n%nIt runs only on your computer: no internet, no account, no background program.%n%nTStamp runs inside Git Bash, which this setup checks for.
FinishedHeadingLabel=TStamp is installed
FinishedLabel=Setup has installed [name] on your computer.%n%nOpen a new Git Bash, PowerShell or Command Prompt window, then type tstamp-a. Git Bash and PowerShell windows are timed automatically. In Command Prompt, tstamp-a also turns that window into a tracked session; to time one command only, use: tstamp run COMMAND%n%nIf PowerShell says scripts are disabled, run this once in PowerShell:%nSet-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
FinishedLabelNoIcons=Setup has installed [name] on your computer.%n%nOpen a new Git Bash, PowerShell or Command Prompt window, then type tstamp-a. Git Bash and PowerShell windows are timed automatically. In Command Prompt, tstamp-a also turns that window into a tracked session; to time one command only, use: tstamp run COMMAND%n%nIf PowerShell says scripts are disabled, run this once in PowerShell:%nSet-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

[Tasks]
Name: "bashhook"; Description: "Git Bash: load TStamp in every new window (edits ~/.bashrc after making a backup)"; GroupDescription: "Terminals:"
Name: "powershellhook"; Description: "PowerShell: load TStamp in every new window (edits your PowerShell profile after making a backup)"; GroupDescription: "Terminals:"
Name: "addtopath"; Description: "CMD and PowerShell commands: use tstamp, tstamp-a and tstamp run anywhere (adds the install folder to your user PATH)"; GroupDescription: "Terminals:"
Name: "cmdautorun"; Description: "Command Prompt: open new windows as a TStamp session while tracking is on (adds an AutoRun entry for your user, removed on uninstall)"; GroupDescription: "Terminals:"; Flags: unchecked

[Files]
Source: "..\dist\stage\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "assets\tstamp.ico"; DestDir: "{app}"; Flags: ignoreversion

[Code]
function GitBashPath: string;
var
  base: string;
  i: Integer;
  cand: array[0..2] of string;
begin
  Result := '';
  if RegQueryStringValue(HKCU, 'SOFTWARE\GitForWindows', 'InstallPath', base) or
     RegQueryStringValue(HKLM, 'SOFTWARE\GitForWindows', 'InstallPath', base) then
  begin
    if FileExists(base + '\bin\bash.exe') then
    begin
      Result := base + '\bin\bash.exe';
      Exit;
    end;
  end;
  cand[0] := GetEnv('ProgramW6432') + '\Git\bin\bash.exe';
  cand[1] := ExpandConstant('{localappdata}') + '\Programs\Git\bin\bash.exe';
  cand[2] := GetEnv('ProgramFiles(x86)') + '\Git\bin\bash.exe';
  for i := 0 to 2 do
  begin
    if FileExists(cand[i]) then
    begin
      Result := cand[i];
      Exit;
    end;
  end;
end;

{ Runs "tstamp hook add|remove --yes" through Git Bash. True on success. }
function RunTstamp(const action: string): Boolean;
var
  bash, app, params: string;
  code: Integer;
begin
  Result := False;
  bash := GitBashPath;
  if bash = '' then
    Exit;
  app := ExpandConstant('{app}');
  StringChangeEx(app, '\', '/', True);
  params := '-l -c "''' + app + '/bin/tstamp'' hook ' + action + ' --yes"';
  Result := Exec(bash, params, '', SW_HIDE, ewWaitUntilTerminated, code) and (code = 0);
end;

{ Runs "tstamp hook add|remove --powershell --yes" through Git Bash. }
function RunTstampPS(const action: string): Boolean;
var
  bash, app, params: string;
  code: Integer;
begin
  Result := False;
  bash := GitBashPath;
  if bash = '' then
    Exit;
  app := ExpandConstant('{app}');
  StringChangeEx(app, '\', '/', True);
  params := '-l -c "''' + app + '/bin/tstamp'' hook ' + action + ' --powershell --yes"';
  Result := Exec(bash, params, '', SW_HIDE, ewWaitUntilTerminated, code) and (code = 0);
end;

function PathContains(const path, dir: string): Boolean;
begin
  Result := Pos(';' + Lowercase(dir) + ';', ';' + Lowercase(path) + ';') > 0;
end;

// Adds the install folder to the user PATH (no administrator rights needed).
procedure AddToUserPath;
var
  p, d: string;
begin
  d := ExpandConstant('{app}\bin');
  if not RegQueryStringValue(HKCU, 'Environment', 'Path', p) then
    p := '';
  if PathContains(p, d) then
    Exit;
  if (p <> '') and (Copy(p, Length(p), 1) <> ';') then
    p := p + ';';
  RegWriteExpandStringValue(HKCU, 'Environment', 'Path', p + d);
end;

{ Removes only the entry that AddToUserPath wrote. }
procedure RemoveFromUserPath;
var
  p, d, q: string;
begin
  d := ExpandConstant('{app}\bin');
  if not RegQueryStringValue(HKCU, 'Environment', 'Path', p) then
    Exit;
  q := ';' + p + ';';
  StringChangeEx(q, ';' + d + ';', ';', True);
  while Copy(q, 1, 1) = ';' do
    Delete(q, 1, 1);
  while Copy(q, Length(q), 1) = ';' do
    Delete(q, Length(q), 1);
  if q = '' then
    RegDeleteValue(HKCU, 'Environment', 'Path')
  else
    RegWriteExpandStringValue(HKCU, 'Environment', 'Path', q);
end;

const
  AutoRunKey = 'Software\Microsoft\Command Processor';
  TStampKey = 'Software\TStamp';

// The command added to the Command Prompt AutoRun value. It does nothing if the file is gone.
function AutoRunCommand: string;
var
  f: string;
begin
  f := ExpandConstant('{app}\bin\tstamp-autorun.cmd');
  Result := 'if exist "' + f + '" call "' + f + '"';
end;

// Adds the AutoRun command after any value that is already there (no administrator rights needed).
procedure AddCmdAutoRun;
var
  p, c: string;
begin
  c := AutoRunCommand;
  if not RegQueryStringValue(HKCU, AutoRunKey, 'AutoRun', p) then
    p := '';
  if Pos(Lowercase(c), Lowercase(p)) > 0 then
    Exit;
  if p <> '' then
  begin
    RegWriteStringValue(HKCU, TStampKey, 'AutoRunBefore', p);
    p := p + ' & ' + c;
  end
  else
    p := c;
  RegWriteExpandStringValue(HKCU, AutoRunKey, 'AutoRun', p);
end;

// Removes only the command that AddCmdAutoRun wrote and leaves the rest of the value as it was.
procedure RemoveCmdAutoRun;
var
  p, q, c: string;
begin
  c := AutoRunCommand;
  if RegQueryStringValue(HKCU, AutoRunKey, 'AutoRun', p) then
  begin
    q := p;
    StringChangeEx(q, ' & ' + c, '', True);
    StringChangeEx(q, c + ' & ', '', True);
    StringChangeEx(q, c, '', True);
    q := Trim(q);
    if q <> p then
    begin
      if q = '' then
        RegDeleteValue(HKCU, AutoRunKey, 'AutoRun')
      else
        RegWriteExpandStringValue(HKCU, AutoRunKey, 'AutoRun', q);
    end;
  end;
  RegDeleteKeyIncludingSubkeys(HKCU, TStampKey);
end;

function InitializeSetup: Boolean;
begin
  Result := True;
  if GitBashPath = '' then
  begin
    MsgBox('TStamp runs inside Git Bash, which was not found on this PC.' + #13#10 + #13#10 +
      'Install Git for Windows (https://git-scm.com/download/win), then run this installer again.',
      mbError, MB_OK);
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if WizardIsTaskSelected('bashhook') then
    begin
      if not RunTstamp('add') then
        MsgBox('TStamp was installed, but adding it to ~/.bashrc failed.' + #13#10 + #13#10 +
          'Open Git Bash and run:  tstamp hook add', mbInformation, MB_OK);
    end;
    if WizardIsTaskSelected('powershellhook') then
    begin
      if not RunTstampPS('add') then
        MsgBox('TStamp was installed, but adding it to your PowerShell profile failed.' + #13#10 + #13#10 +
          'Open Git Bash and run:  tstamp hook add --powershell', mbInformation, MB_OK);
    end;
    if WizardIsTaskSelected('addtopath') then
      AddToUserPath;
    if WizardIsTaskSelected('cmdautorun') then
      AddCmdAutoRun;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  state: string;
begin
  if CurUninstallStep = usUninstall then
  begin
    if not RunTstamp('remove') then
      MsgBox('TStamp could not remove its block from ~/.bashrc automatically.' + #13#10 + #13#10 +
        'Open ~/.bashrc and delete the lines between "# >>> tstamp >>>" and "# <<< tstamp <<<".',
        mbInformation, MB_OK);
    RunTstampPS('remove');
    RemoveFromUserPath;
    RemoveCmdAutoRun;
  end;
  if CurUninstallStep = usPostUninstall then
  begin
    if not UninstallSilent then
    begin
      state := ExpandConstant('{%USERPROFILE}') + '\.tstamp';
      if DirExists(state) then
      begin
        if MsgBox('Also delete your TStamp settings and logs?' + #13#10 + #13#10 + state,
          mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES then
          DelTree(state, True, True, True);
      end;
    end;
  end;
end;
