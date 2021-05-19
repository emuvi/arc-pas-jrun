program jrun;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Classes,
  SysUtils,
  Process,
  FileUtil,
  StrUtils;

{$R *.res}

var
  ip: integer;
  verbose: boolean;
  folder: string;
  folderJava: string;
  folderJavaInside: string;
  execName: string;
  execJava: string;
  execJar: string;
  proc: TProcess;
  buffer: array[0..127] of char;
  Count: integer;
begin
  verbose := False;
  for ip := 0 to ParamCount do
  begin
    if (ParamStr(ip) = '--verbose') or (ParamStr(ip) = '-V') then
    begin
      verbose := True;
    end;
  end;
  execName := ExtractFileName(ParamStr(0));
  WriteLn('Execution: ' + execName);
  folder := ExtractFileDir(ParamStr(0));
  if folder = '.' then
  begin
    folder := GetCurrentDir;
  end;
  WriteLn('Folder: ' + folder);
  folderJava := folder + DirectorySeparator + 'jvm';
  WriteLn('Folder Java: ' + folderJava);
  if DirectoryExists(folderJava) then
  begin
    WriteLn('Folder Java exists.');
    folderJavaInside := 'bin';
    if DirectoryExists(folderJava + DirectorySeparator + 'Contents') then
    begin
      folderJavaInside := 'Contents' + DirectorySeparator + 'Home' +
        DirectorySeparator + 'bin';
    end;
    execJava := folderJava + DirectorySeparator + folderJavaInside +
      DirectorySeparator + 'java';
    if not FileExists(execJava) then
    begin
      execJava := execJava + '.exe';
    end;
    if not FileExists(execJava) then
    begin
      WriteLn('Exec Java: "' + execJava + '" does not exist.');
      execJava := FindDefaultExecutablePath('java');
    end;
  end
  else
  begin
    WriteLn('Folder Java does not exists.');
    execJava := FindDefaultExecutablePath('java');
  end;
  execJar := folder + DirectorySeparator + execName;
  if AnsiEndsStr('.exe', execJar) then
  begin
    execJar := Copy(execJar, 0, Length(execJar) - 4);
  end;
  execJar := execJar + '.jar';
  Write('Execution ');
  if verbose then
  begin
    Write('verbose ');
  end;
  WriteLn('of:');
  WriteLn('Java: ' + execJava);
  WriteLn('Jar: ' + execJar);
  proc := TProcess.Create(nil);
  proc.Executable := execJava;
  proc.Parameters.Add('-jar');
  proc.Parameters.Add(execJar);
  proc.Parameters.Add('-Duser.dir');
  proc.Parameters.Add(folder);
  for ip := 1 to ParamCount do
  begin
    proc.Parameters.Add(ParamStr(ip));
  end;
  if verbose then
  begin
    proc.Options := [poWaitOnExit, poUsePipes, poStderrToOutPut];
    proc.Execute;
    while (proc.Running) or (proc.Output.NumBytesAvailable > 0) do
    begin
      Count := proc.Output.NumBytesAvailable;
      if Count > 0 then
      begin
        if Count > sizeof(buffer) then
        begin
          Count := sizeof(buffer);
        end;
        Count := proc.Output.Read(buffer[0], Count);
        Write(PChar(buffer));
      end;
    end;
  end
  else
  begin
    proc.Options := [poNoConsole];
    proc.Execute;
    halt(0);
  end;
end.
