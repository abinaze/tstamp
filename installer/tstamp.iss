; TStamp Windows installer (Inno Setup 6).
; Build:  ISCC.exe /DMyAppVersion=0.1.0 installer\tstamp.iss
; Run installer/stage.sh first: it fills dist\stage with the files to install.

#ifndef MyAppVersion
  #define MyAppVersion "0.1.0-dev"
#endif

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
OutputDir=..\dist
OutputBaseFilename=tstamp-setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=TStamp

[Messages]
FinishedLabel=Setup has installed [name] on your computer.%n%nOpen a new Git Bash window, then type tstamp-a to timestamp every terminal, or tstamp for just one.
FinishedLabelNoIcons=Setup has installed [name] on your computer.%n%nOpen a new Git Bash window, then type tstamp-a to timestamp every terminal, or tstamp for just one.

[Tasks]
Name: "bashhook"; Description: "Load TStamp in every new Git Bash window (edits ~/.bashrc after making a backup)"; GroupDescription: "Git Bash integration:"

[Files]
Source: "..\dist\stage\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

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
