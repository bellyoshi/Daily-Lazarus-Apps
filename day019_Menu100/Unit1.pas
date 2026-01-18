unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, fpjson, jsonparser,
  Process, FileUtil, LazFileUtils, ComCtrls, jsonconf;

type
  TAppInfo = record
    FolderName: string;
    Title: string;
    BlogUrl: string;
    Notes: TStringList;
    Enabled: Boolean;
  end;

  TAppInfoArray = array of TAppInfo;

  { TAppConfig }

  TAppConfig = class
  private
    FJsonFileName: string;
    FBaseDir: string;
    FLazManager: string;
    FApps: TAppInfoArray;
    function ParseJsonFile(const FileName: string): TJSONData;
    procedure LoadApps(const JsonData: TJSONData);
    function ExtractDayNumber(const FolderName: string): Integer;
  public
    constructor Create(const JsonFileName: string);
    destructor Destroy; override;
    function GetEnabledApps: TAppInfoArray;
    function GetAppByFolderName(const FolderName: string): TAppInfo;
    procedure UpdateAppNotes(const FolderName: string; const Notes: TStrings);
    function SaveToFile: Boolean;
    property BaseDir: string read FBaseDir;
    property LazManager: string read FLazManager;
    property Apps: TAppInfoArray read FApps;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    ListViewApps: TListView;
    ButtonRun: TButton;
    ButtonBlog: TButton;
    ButtonManager: TButton;
    MemoNotes: TMemo;
    ButtonSave: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonRunClick(Sender: TObject);
    procedure ButtonBlogClick(Sender: TObject);
    procedure ButtonManagerClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure ListViewAppsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure MemoNotesChange(Sender: TObject);
  private
    FAppConfig: TAppConfig;
    FApps: TAppInfoArray;
    FCurrentAppIndex: Integer;
    FNotesChanged: Boolean;
    procedure LoadAppList;
    procedure UpdateNotes;
    function GetSelectedAppIndex: Integer;
    procedure SaveCurrentNotes;
  public

  end;

var
  Form1: TForm1;

// exe 探索関数
function FindExeInFolder(const FolderPath: string): string;

// LazBuild でビルドする関数
function BuildWithLazBuild(const ProjectFolder: string): Boolean;

implementation

{$R *.lfm}

{ TAppConfig }

constructor TAppConfig.Create(const JsonFileName: string);
var
  JsonData: TJSONData;
  i: Integer;
begin
  FJsonFileName := JsonFileName;
  FBaseDir := '';
  FLazManager := '';
  SetLength(FApps, 0);
  
  try
    JsonData := ParseJsonFile(JsonFileName);
    try
      if JsonData is TJSONObject then
      begin
        FBaseDir := TJSONObject(JsonData).Get('baseDir', '');
        FLazManager := TJSONObject(JsonData).Get('LazManager', '');
        LoadApps(JsonData);
      end;
    finally
      JsonData.Free;
    end;
  except
    on E: Exception do
    begin
      MessageDlg('エラー', 'JSON ファイルの読み込みに失敗しました:' + LineEnding + E.Message,
        mtError, [mbOK], 0);
    end;
  end;
end;

destructor TAppConfig.Destroy;
var
  i: Integer;
begin
  for i := 0 to Length(FApps) - 1 do
    FApps[i].Notes.Free;
  inherited Destroy;
end;

function TAppConfig.ParseJsonFile(const FileName: string): TJSONData;
var
  JsonText: string;
  Parser: TJSONParser;
begin
  if not FileExists(FileName) then
    raise Exception.Create('JSON ファイルが見つかりません: ' + FileName);
    
  JsonText := '';
  try
    JsonText := ReadFileToString(FileName);
    Parser := TJSONParser.Create(JsonText);
    try
      Result := Parser.Parse;
    finally
      Parser.Free;
    end;
  except
    on E: Exception do
      raise Exception.Create('JSON の解析に失敗しました: ' + E.Message);
  end;
end;

procedure TAppConfig.LoadApps(const JsonData: TJSONData);
var
  AppsObj: TJSONObject;
  AppName: string;
  AppData: TJSONObject;
  AppInfo: TAppInfo;
  NotesArray: TJSONArray;
  i, j: Integer;
begin
  if not (JsonData is TJSONObject) then
    Exit;
    
  AppsObj := TJSONObject(JsonData).Get('apps', TJSONObject(nil));
  if AppsObj = nil then
    Exit;
    
  SetLength(FApps, 0);
  
  for i := 0 to AppsObj.Count - 1 do
  begin
    AppName := AppsObj.Names[i];
    AppData := AppsObj.Objects[AppName];
    
    if AppData = nil then
      Continue;
      
    AppInfo.FolderName := AppName;
    AppInfo.Title := AppData.Get('title', '');
    AppInfo.BlogUrl := AppData.Get('blogUrl', '');
    AppInfo.Enabled := AppData.Get('enabled', False);
    AppInfo.Notes := TStringList.Create;
    
    NotesArray := AppData.Get('notes', TJSONArray(nil));
    if NotesArray <> nil then
    begin
      for j := 0 to NotesArray.Count - 1 do
        AppInfo.Notes.Add(NotesArray.Strings[j]);
    end;
    
    SetLength(FApps, Length(FApps) + 1);
    FApps[Length(FApps) - 1] := AppInfo;
  end;
end;

function TAppConfig.ExtractDayNumber(const FolderName: string): Integer;
var
  i: Integer;
  DayStr: string;
begin
  Result := 0;
  DayStr := '';
  
  // "day" の後に続く数字を抽出
  i := Pos('day', LowerCase(FolderName));
  if i > 0 then
  begin
    i := i + 3; // "day" の後
    while (i <= Length(FolderName)) and (FolderName[i] in ['0'..'9']) do
    begin
      DayStr := DayStr + FolderName[i];
      Inc(i);
    end;
    if DayStr <> '' then
      Result := StrToIntDef(DayStr, 0);
  end;
end;

function TAppConfig.GetEnabledApps: TAppInfoArray;
var
  EnabledApps: TAppInfoArray;
  i, j: Integer;
  Temp: TAppInfo;
begin
  SetLength(EnabledApps, 0);
  
  // enabled = true のアプリのみ抽出
  for i := 0 to Length(FApps) - 1 do
  begin
    if FApps[i].Enabled then
    begin
      SetLength(EnabledApps, Length(EnabledApps) + 1);
      EnabledApps[Length(EnabledApps) - 1] := FApps[i];
    end;
  end;
  
  // day 番号順にソート（バブルソート）
  for i := 0 to Length(EnabledApps) - 2 do
  begin
    for j := 0 to Length(EnabledApps) - 2 - i do
    begin
      if ExtractDayNumber(EnabledApps[j].FolderName) > ExtractDayNumber(EnabledApps[j + 1].FolderName) then
      begin
        Temp := EnabledApps[j];
        EnabledApps[j] := EnabledApps[j + 1];
        EnabledApps[j + 1] := Temp;
      end;
    end;
  end;
  
  Result := EnabledApps;
end;

function TAppConfig.GetAppByFolderName(const FolderName: string): TAppInfo;
var
  i: Integer;
begin
  // デフォルト値で初期化
  Result.FolderName := '';
  Result.Title := '';
  Result.BlogUrl := '';
  Result.Notes := nil;
  Result.Enabled := False;
  
  for i := 0 to Length(FApps) - 1 do
  begin
    if FApps[i].FolderName = FolderName then
    begin
      Result := FApps[i];
      Exit;
    end;
  end;
end;

procedure TAppConfig.UpdateAppNotes(const FolderName: string; const Notes: TStrings);
var
  i: Integer;
begin
  for i := 0 to Length(FApps) - 1 do
  begin
    if FApps[i].FolderName = FolderName then
    begin
      FApps[i].Notes.Assign(Notes);
      Exit;
    end;
  end;
end;

function TAppConfig.SaveToFile: Boolean;
var
  JsonObj: TJSONObject;
  AppsObj: TJSONObject;
  AppObj: TJSONObject;
  NotesArray: TJSONArray;
  i, j: Integer;
  JsonText: string;
begin
  Result := False;
  
  try
    JsonObj := TJSONObject.Create;
    try
      JsonObj.Add('baseDir', FBaseDir);
      JsonObj.Add('LazManager', FLazManager);
      
      AppsObj := TJSONObject.Create;
      JsonObj.Add('apps', AppsObj);
      
      // すべてのアプリを保存（enabled=falseも含む）
      for i := 0 to Length(FApps) - 1 do
      begin
        AppObj := TJSONObject.Create;
        AppObj.Add('title', FApps[i].Title);
        AppObj.Add('blogUrl', FApps[i].BlogUrl);
        AppObj.Add('enabled', FApps[i].Enabled);
        
        NotesArray := TJSONArray.Create;
        AppObj.Add('notes', NotesArray);
        for j := 0 to FApps[i].Notes.Count - 1 do
          NotesArray.Add(FApps[i].Notes[j]);
        
        AppsObj.Add(FApps[i].FolderName, AppObj);
      end;
      
      // JSONを文字列に変換
      JsonText := JsonObj.FormatJSON([], 2);
      
      // ファイルに保存
      with TStringList.Create do
      try
        Text := JsonText;
        SaveToFile(FJsonFileName);
      finally
        Free;
      end;
      
      Result := True;
    finally
      JsonObj.Free;
    end;
  except
    on E: Exception do
    begin
      MessageDlg('エラー', 'JSON ファイルの保存に失敗しました:' + LineEnding + E.Message,
        mtError, [mbOK], 0);
    end;
  end;
end;

{ exe 探索関数 }

function FindExeInFolder(const FolderPath: string): string;
var
  SearchRec: TSearchRec;
  ExePath: string;
begin
  Result := '';
  
  if not DirectoryExists(FolderPath) then
    Exit;
    
  if FindFirst(IncludeTrailingPathDelimiter(FolderPath) + '*.exe', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then
        begin
          ExePath := IncludeTrailingPathDelimiter(FolderPath) + SearchRec.Name;
          Result := ExePath;
          Break; // 最初の exe を見つけたら終了
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;

function BuildWithLazBuild(const ProjectFolder: string): Boolean;
var
  Process: TProcess;
  LazBuildPath: string;
  LpiFile: string;
  SearchRec: TSearchRec;
  Output: TStringList;
  MemStream: TMemoryStream;
  BytesRead: Integer;
  Buffer: array[1..2048] of Byte;
begin
  Result := False;
  LazBuildPath := 'C:\Lazarus\lazbuild.exe';
  
  if not FileExists(LazBuildPath) then
  begin
    MessageDlg('エラー', 'LazBuild が見つかりません:' + LineEnding + LazBuildPath,
      mtError, [mbOK], 0);
    Exit;
  end;
  
  // プロジェクトフォルダ内の .lpi ファイルを探す
  LpiFile := '';
  if FindFirst(IncludeTrailingPathDelimiter(ProjectFolder) + '*.lpi', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then
        begin
          LpiFile := IncludeTrailingPathDelimiter(ProjectFolder) + SearchRec.Name;
          Break;
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
  
  if LpiFile = '' then
  begin
    MessageDlg('エラー', 'プロジェクトファイル (.lpi) が見つかりません:' + LineEnding + ProjectFolder,
      mtError, [mbOK], 0);
    Exit;
  end;
  
  Process := TProcess.Create(nil);
  Output := TStringList.Create;
  MemStream := TMemoryStream.Create;
  try
    try
      Process.Executable := LazBuildPath;
      Process.Parameters.Add(LpiFile);
      Process.CurrentDirectory := ProjectFolder;
      
      // ポイント：poWaitOnExitを外し、パイプを利用する
      Process.Options := [poUsePipes, poStderrToOutPut];
      Process.ShowWindow := swoHide;
      
      MessageDlg('情報', 'ビルドを開始します...' + LineEnding + LpiFile,
        mtInformation, [mbOK], 0);
      
      Process.Execute;
      
      // プロセスが動いている間、出力を吸い出し続ける（デッドロック防止）
      while Process.Running do
      begin
        // パイプから読み取れるデータがあるか確認
        BytesRead := Process.Output.Read(Buffer, SizeOf(Buffer));
        if BytesRead > 0 then
          MemStream.Write(Buffer, BytesRead)
        else
          Sleep(10); // データがない場合は少し待機してCPU負荷を抑える
          
        Application.ProcessMessages; // アプリがフリーズするのを防ぐ
      end;
      
      // 終了後、最後に残ったデータを読み取る
      repeat
        BytesRead := Process.Output.Read(Buffer, SizeOf(Buffer));
        if BytesRead > 0 then
          MemStream.Write(Buffer, BytesRead);
      until BytesRead <= 0;
      
      // メモリストリームの内容をStringListに変換
      MemStream.Position := 0;
      Output.LoadFromStream(MemStream);
      
      if Process.ExitStatus <> 0 then
      begin
        MessageDlg('ビルドエラー', 'ビルドに失敗しました。' + LineEnding + LineEnding +
          '終了コード: ' + IntToStr(Process.ExitStatus) + LineEnding +
          '出力:' + LineEnding + Output.Text,
          mtError, [mbOK], 0);
        Exit;
      end;
      
      Result := True;
      MessageDlg('成功', 'ビルドが完了しました', mtInformation, [mbOK], 0);
    except
      on E: Exception do
      begin
        MessageDlg('エラー', 'ビルド処理中にエラーが発生しました:' + LineEnding + E.Message,
          mtError, [mbOK], 0);
      end;
    end;
  finally
    // リソースの確実な解放
    MemStream.Free;
    Output.Free;
    Process.Free;
  end;
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  Col: TListColumn;
begin
  FCurrentAppIndex := -1;
  FNotesChanged := False;
  
  // ListViewの列を設定
  ListViewApps.ViewStyle := vsReport;
  ListViewApps.RowSelect := True;
  
  Col := ListViewApps.Columns.Add;
  Col.Caption := 'ID';
  Col.Width := 150;
  
  Col := ListViewApps.Columns.Add;
  Col.Caption := 'タイトル';
  Col.Width := 300;
  
  try
    FAppConfig := TAppConfig.Create('apps.json');
    LoadAppList;
  except
    on E: Exception do
    begin
      MessageDlg('エラー', 'アプリケーションの初期化に失敗しました:' + LineEnding + E.Message,
        mtError, [mbOK], 0);
    end;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  // 変更があれば保存
  if FNotesChanged and (FCurrentAppIndex >= 0) then
  begin
    if MessageDlg('確認', 'メモに変更があります。保存しますか？',
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      SaveCurrentNotes;
      FAppConfig.SaveToFile;
    end;
  end;
  FAppConfig.Free;
end;

procedure TForm1.LoadAppList;
var
  i: Integer;
  Item: TListItem;
begin
  FApps := FAppConfig.GetEnabledApps;
  ListViewApps.Items.Clear;
  
  for i := 0 to Length(FApps) - 1 do
  begin
    Item := ListViewApps.Items.Add;
    Item.Caption := FApps[i].FolderName;
    Item.SubItems.Add(FApps[i].Title);
    Item.Data := Pointer(i); // インデックスを保存
  end;
    
  if ListViewApps.Items.Count > 0 then
  begin
    ListViewApps.Items[0].Selected := True;
    ListViewApps.ItemIndex := 0;
  end;
    
  UpdateNotes;
end;

procedure TForm1.UpdateNotes;
var
  Index: Integer;
begin
  // 前のアプリのメモを保存
  if (FCurrentAppIndex >= 0) and (FCurrentAppIndex < Length(FApps)) and FNotesChanged then
  begin
    SaveCurrentNotes;
  end;
  
  Index := GetSelectedAppIndex;
  FCurrentAppIndex := Index;
  FNotesChanged := False;
  
  MemoNotes.Clear;
  MemoNotes.ReadOnly := False;
  
  if (Index >= 0) and (Index < Length(FApps)) then
  begin
    MemoNotes.Lines.Assign(FApps[Index].Notes);
  end;
  
  ButtonSave.Enabled := False;
end;

function TForm1.GetSelectedAppIndex: Integer;
var
  Item: TListItem;
begin
  Result := -1;
  Item := ListViewApps.Selected;
  if Item <> nil then
    Result := Integer(Item.Data);
end;

procedure TForm1.SaveCurrentNotes;
var
  Index: Integer;
begin
  Index := FCurrentAppIndex;
  if (Index >= 0) and (Index < Length(FApps)) then
  begin
    // FAppsのコピーを更新
    FApps[Index].Notes.Assign(MemoNotes.Lines);
    // FAppConfigの元データも更新
    FAppConfig.UpdateAppNotes(FApps[Index].FolderName, MemoNotes.Lines);
  end;
end;



procedure TForm1.ButtonRunClick(Sender: TObject);
var
  Index: Integer;
  AppFolder: string;
  ExePath: string;
  Process: TProcess;
begin
  Index := GetSelectedAppIndex;
  if (Index < 0) or (Index >= Length(FApps)) then
  begin
    MessageDlg('エラー', 'アプリが選択されていません', mtError, [mbOK], 0);
    Exit;
  end;
  
  AppFolder := IncludeTrailingPathDelimiter(FAppConfig.BaseDir) + FApps[Index].FolderName;
  ExePath := FindExeInFolder(AppFolder);
  
  if ExePath = '' then
  begin
    // 実行ファイルが見つからない場合、LazBuild でビルドを試みる
    if MessageDlg('確認', '実行ファイルが見つかりません。' + LineEnding +
      'LazBuild でビルドしますか？' + LineEnding + AppFolder,
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if BuildWithLazBuild(AppFolder) then
      begin
        // ビルド成功後、再度 exe を探す
        ExePath := FindExeInFolder(AppFolder);
        if ExePath = '' then
        begin
          MessageDlg('エラー', 'ビルド後も実行ファイルが見つかりません:' + LineEnding + AppFolder,
            mtError, [mbOK], 0);
          Exit;
        end;
      end
      else
      begin
        Exit; // ビルド失敗
      end;
    end
    else
    begin
      Exit; // ユーザーがキャンセル
    end;
  end;
  
  try
    Process := TProcess.Create(nil);
    try
      Process.Executable := ExePath;
      Process.Options := Process.Options + [poNoConsole];
      Process.Execute;
    finally
      Process.Free;
    end;
  except
    on E: Exception do
    begin
      MessageDlg('エラー', 'アプリケーションの起動に失敗しました:' + LineEnding + E.Message,
        mtError, [mbOK], 0);
    end;
  end;
end;

procedure TForm1.ButtonBlogClick(Sender: TObject);
var
  Index: Integer;
  BlogUrl: string;
  Process: TProcess;
begin
  Index := GetSelectedAppIndex;
  if (Index < 0) or (Index >= Length(FApps)) then
    Exit;
    
  BlogUrl := FApps[Index].BlogUrl;
  if BlogUrl = '' then
    Exit;
    
  try
    Process := TProcess.Create(nil);
    try
      Process.Executable := 'cmd.exe';
      Process.Parameters.Add('/c');
      Process.Parameters.Add('start');
      Process.Parameters.Add('""');
      Process.Parameters.Add(BlogUrl);
      Process.Options := Process.Options + [poNoConsole];
      Process.Execute;
    finally
      Process.Free;
    end;
  except
    on E: Exception do
    begin
      MessageDlg('エラー', 'ブラウザの起動に失敗しました:' + LineEnding + E.Message,
        mtError, [mbOK], 0);
    end;
  end;
end;

procedure TForm1.ButtonManagerClick(Sender: TObject);
var
  LazManagerPath: string;
  Process: TProcess;
begin
  LazManagerPath := FAppConfig.LazManager;
  
  if LazManagerPath = '' then
  begin
    MessageDlg('エラー', 'LazManager のパスが設定されていません', mtError, [mbOK], 0);
    Exit;
  end;
  
  if not FileExists(LazManagerPath) then
  begin
    MessageDlg('エラー', 'LazManager が見つかりません:' + LineEnding + LazManagerPath,
      mtError, [mbOK], 0);
    Exit;
  end;
  
  try
    Process := TProcess.Create(nil);
    try
      Process.Executable := LazManagerPath;
      Process.Options := Process.Options + [poNoConsole];
      Process.Execute;
    finally
      Process.Free;
    end;
  except
    on E: Exception do
    begin
      MessageDlg('エラー', 'LazManager の起動に失敗しました:' + LineEnding + E.Message,
        mtError, [mbOK], 0);
    end;
  end;
end;

procedure TForm1.ButtonSaveClick(Sender: TObject);
begin
  // 現在のメモを保存
  SaveCurrentNotes;
  FNotesChanged := False;
  ButtonSave.Enabled := False;
  
  // apps.jsonに保存
  if FAppConfig.SaveToFile then
    MessageDlg('成功', 'apps.json を保存しました', mtInformation, [mbOK], 0);
end;

procedure TForm1.ListViewAppsSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  Index: Integer;
begin
  if not Selected then
    Exit;

  UpdateNotes;
  Index := GetSelectedAppIndex;
  ButtonBlog.Enabled := (Index >= 0) and
    (Index < Length(FApps)) and
    (FApps[Index].BlogUrl <> '');
end;

procedure TForm1.MemoNotesChange(Sender: TObject);
begin
  FNotesChanged := True;
  ButtonSave.Enabled := True;
end;

end.
