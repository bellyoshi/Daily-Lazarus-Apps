unit Executer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

type
  TErrorCallback = procedure(const Title, ErrorMessage: string) of object;

procedure ProcessExecute(const Executable: string; const Parameters: array of string; 
  const WorkingDirectory: string; OnError: TErrorCallback);

procedure CmdExecute(const CmdPath: string; 
  const WorkingDirectory: string; const AdditionalParams: array of const; 
  OnError: TErrorCallback);

implementation

procedure ProcessExecute(const Executable: string; const Parameters: array of string; 
  const WorkingDirectory: string; OnError: TErrorCallback);
var
  Process: TProcess;
  i: Integer;
begin
  Process := TProcess.Create(nil);
  try
    try
      Process.Executable := Executable;
      for i := Low(Parameters) to High(Parameters) do
        Process.Parameters.Add(Parameters[i]);
      
      Process.CurrentDirectory := WorkingDirectory;
      
      // poNoConsole: 黒い画面を表示させない
      Process.Options := [poNoConsole];
      
      Process.Execute;
    except
      on E: Exception do
      begin
        if Assigned(OnError) then
          OnError('エラー', 'コマンドの実行に失敗しました。'#13#10 +
                    '実行ファイル: ' + Executable + #13#10 +
                    '作業ディレクトリ: ' + WorkingDirectory + #13#10 +
                    'エラー詳細: ' + E.Message);
      end;
    end;
  finally
    Process.Free;
  end;
end;

procedure CmdExecute(const CmdPath: string; 
  const WorkingDirectory: string; const AdditionalParams: array of const; 
  OnError: TErrorCallback);
var
  Executable: string;
  Parameters: array of string;
  i: Integer;
  BaseParamCount: Integer;
  CommandStr: string;
begin
  {
    Windowsの場合、cmd.exe /c [コマンド] を使用することで、
    環境変数PATHの解決や、.cmd / .bat ファイルの実行をOSに任せることができます。
  }
  {$IFDEF WINDOWS}
  Executable := 'cmd.exe';
  BaseParamCount := 2; // /c, CmdPath
  SetLength(Parameters, BaseParamCount + Length(AdditionalParams));
  Parameters[0] := '/c';
  // CmdPathが "cursor" なら、"cmd /c cursor [params...]" という構造になります
  Parameters[1] := CmdPath;
  
  // 追加パラメータを追加
  for i := 0 to High(AdditionalParams) do
  begin
    case AdditionalParams[i].VType of
      vtAnsiString: Parameters[BaseParamCount + i] := string(AdditionalParams[i].VAnsiString);
      vtString: Parameters[BaseParamCount + i] := AdditionalParams[i].VString^;
      vtPChar: Parameters[BaseParamCount + i] := string(AdditionalParams[i].VPChar);
      vtChar: Parameters[BaseParamCount + i] := AdditionalParams[i].VChar;
      vtWideString: Parameters[BaseParamCount + i] := string(AdditionalParams[i].VWideString);
      vtUnicodeString: Parameters[BaseParamCount + i] := string(AdditionalParams[i].VUnicodeString);
      vtInteger: Parameters[BaseParamCount + i] := IntToStr(AdditionalParams[i].VInteger);
      vtInt64: Parameters[BaseParamCount + i] := IntToStr(AdditionalParams[i].VInt64^);
      else
        Parameters[BaseParamCount + i] := '';
    end;
  end;
  {$ELSE}
  // Linux/macOS等の場合は sh -c を検討
  Executable := '/bin/sh';
  BaseParamCount := 2; // -c, command string
  CommandStr := CmdPath;
  
  // 追加パラメータをコマンド文字列に含める
  for i := 0 to High(AdditionalParams) do
  begin
    case AdditionalParams[i].VType of
      vtAnsiString: CommandStr := CommandStr + ' "' + string(AdditionalParams[i].VAnsiString) + '"';
      vtString: CommandStr := CommandStr + ' "' + AdditionalParams[i].VString^ + '"';
      vtPChar: CommandStr := CommandStr + ' "' + string(AdditionalParams[i].VPChar) + '"';
      vtChar: CommandStr := CommandStr + ' ' + AdditionalParams[i].VChar;
      vtWideString: CommandStr := CommandStr + ' "' + string(AdditionalParams[i].VWideString) + '"';
      vtUnicodeString: CommandStr := CommandStr + ' "' + string(AdditionalParams[i].VUnicodeString) + '"';
      vtInteger: CommandStr := CommandStr + ' ' + IntToStr(AdditionalParams[i].VInteger);
      vtInt64: CommandStr := CommandStr + ' ' + IntToStr(AdditionalParams[i].VInt64^);
    end;
  end;
  
  SetLength(Parameters, BaseParamCount);
  Parameters[0] := '-c';
  Parameters[1] := CommandStr;
  {$ENDIF}

  ProcessExecute(Executable, Parameters, WorkingDirectory, OnError);
end;

end.

