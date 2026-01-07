unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn,
  Buttons, ExtCtrls, ComCtrls, Process, LCLIntf, FileUtil, JSONConf, LazFileUtils,
  ProjectCreator, ErrorDialog, Executer;

type

  { TForm1 }

  TForm1 = class(TForm)
    BtnCreate: TButton;
    BtnOpenExplorer: TButton;
    BtnOpenLazarus: TButton;
    BtnOpenConsole: TButton;
    BtnEditor1: TButton;
    BtnEditor2: TButton;
    BtnEditor3: TButton;
    BtnBuild: TButton;
    BtnRunExecutable: TButton;
    BtnOpenProject: TButton;
    DirectoryEditProjectRoot: TDirectoryEdit;
    EditProjectName: TEdit;
    FileNameEditLazbuild: TFileNameEdit;
    FileNameEditEditor1: TFileNameEdit;
    FileNameEditEditor2: TFileNameEdit;
    FileNameEditEditor3: TFileNameEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    PageControl1: TPageControl;
    PanelMain: TPanel;
    PanelCreate: TPanel;
    PanelLaunch: TPanel;
    RadioGroupProjectType: TRadioGroup;
    TabSheetMain: TTabSheet;
    TabSheetSettings: TTabSheet;
    EditEditor1Name: TEdit;
    EditEditor2Name: TEdit;
    EditEditor3Name: TEdit;
    DirectoryEditDefaultProjectRoot: TDirectoryEdit;
    StatusBar1: TStatusBar;
    CheckBoxShowConsole: TCheckBox;
    procedure BtnCreateClick(Sender: TObject);
    procedure BtnEditor1Click(Sender: TObject);
    procedure BtnEditor2Click(Sender: TObject);
    procedure BtnEditor3Click(Sender: TObject);
    procedure BtnOpenConsoleClick(Sender: TObject);
    procedure BtnOpenExplorerClick(Sender: TObject);
    procedure BtnOpenLazarusClick(Sender: TObject);
    procedure BtnBuildClick(Sender: TObject);
    procedure BtnRunExecutableClick(Sender: TObject);
    function BuildProject: Boolean;
    procedure BtnOpenProjectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TabSheetMainShow(Sender: TObject);
  private
    FConfig: TJSONConfig;
    FCurrentProjectPath: string;
    FCurrentProjectName: string;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure UpdateEditorButtons;
    function GetConfigPath: string;
    procedure LaunchEditor(const EditorPath: string);
    function GetProjectPath: string;
    procedure HandleProjectError(const Title, ErrorMessage: string);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FConfig := TJSONConfig.Create(nil);
  FConfig.Filename := GetConfigPath;
  LoadSettings;
  UpdateEditorButtons;
  PageControl1.ActivePage := TabSheetMain;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  SaveSettings;
  FConfig.Free;
end;

function TForm1.GetConfigPath: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'config.json';
end;

procedure TForm1.LoadSettings;
begin
  // Lazbuildパス
  FileNameEditLazbuild.Text := FConfig.GetValue('LazbuildPath', 'C:\Lazarus\Lazbuild.exe');
  
  // エディタ設定
  EditEditor1Name.Text := FConfig.GetValue('Editor1/Name', 'VSCode');
  FileNameEditEditor1.Text := FConfig.GetValue('Editor1/Path', 'Code');
  
  EditEditor2Name.Text := FConfig.GetValue('Editor2/Name', 'Cursor');
  FileNameEditEditor2.Text := FConfig.GetValue('Editor2/Path', 'Cursor');
  
  EditEditor3Name.Text := FConfig.GetValue('Editor3/Name', 'Antigravity');
  FileNameEditEditor3.Text := FConfig.GetValue('Editor3/Path', 'Antigravity');
  
  // 既定のプロジェクトルート（設定タブ）
  DirectoryEditDefaultProjectRoot.Text := FConfig.GetValue('DefaultProjectRoot', '');
  // メインタブのプロジェクトルートに初期値を設定
  DirectoryEditProjectRoot.Text := DirectoryEditDefaultProjectRoot.Text;
end;

procedure TForm1.SaveSettings;
begin
  // Lazbuildパス
  FConfig.SetValue('LazbuildPath', FileNameEditLazbuild.Text);
  
  // エディタ設定
  FConfig.SetValue('Editor1/Name', EditEditor1Name.Text);
  FConfig.SetValue('Editor1/Path', FileNameEditEditor1.Text);
  
  FConfig.SetValue('Editor2/Name', EditEditor2Name.Text);
  FConfig.SetValue('Editor2/Path', FileNameEditEditor2.Text);
  
  FConfig.SetValue('Editor3/Name', EditEditor3Name.Text);
  FConfig.SetValue('Editor3/Path', FileNameEditEditor3.Text);
  
  // 既定のプロジェクトルート（設定タブ）
  FConfig.SetValue('DefaultProjectRoot', DirectoryEditDefaultProjectRoot.Text);
  
  FConfig.Flush;
end;

procedure TForm1.UpdateEditorButtons;
  function IsValidEditorPath(const Path: string): Boolean;
  begin
    Result := Path <> '';
    if Result and (Pos(PathDelim, Path) > 0) then
    begin
      // フルパスの場合はファイルが存在するかチェック
      Result := FileExists(Path);
    end;
    // パスが通っているアプリ名のみの場合は、常に有効とする
  end;
begin
  BtnEditor1.Caption := EditEditor1Name.Text;
  BtnEditor1.Enabled := IsValidEditorPath(FileNameEditEditor1.Text);
  
  BtnEditor2.Caption := EditEditor2Name.Text;
  BtnEditor2.Enabled := IsValidEditorPath(FileNameEditEditor2.Text);
  
  BtnEditor3.Caption := EditEditor3Name.Text;
  BtnEditor3.Enabled := IsValidEditorPath(FileNameEditEditor3.Text);
end;

procedure TForm1.BtnCreateClick(Sender: TObject);
var
  ProjectName, ProjectRoot: string;
  ProjectType: Integer;
begin
  // 入力チェック
  ProjectName := Trim(EditProjectName.Text);
  if ProjectName = '' then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'プロジェクト名を入力してください。');
    Exit;
  end;
  
  // ローマ字チェック（簡易版）
  if not (ProjectName[1] in ['a'..'z', 'A'..'Z']) then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'プロジェクト名はローマ字で始まる必要があります。');
    Exit;
  end;
  
  ProjectRoot := Trim(DirectoryEditProjectRoot.Text);
  if ProjectRoot = '' then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'プロジェクトルートを指定してください。');
    Exit;
  end;
  
  if not DirectoryExists(ProjectRoot) then
  begin
    if MessageDlg('確認', 'プロジェクトルートフォルダが存在しません。作成しますか？', 
       mtConfirmation, [mbYes, mbNo], 0) = mrNo then
      Exit;
  end;
  
  ProjectType := RadioGroupProjectType.ItemIndex;
  
  // プロジェクト作成
  if CreateLazarusProject(ProjectName, ProjectRoot, 
     TProjectType(ProjectType), @HandleProjectError) then
  begin
    FCurrentProjectName := ProjectName;
    FCurrentProjectPath := GetProjectPath;
    // 起動パネルを活性化
    PanelLaunch.Enabled := True;
  end
  else
  begin
    // エラーメッセージはCreateProject内で既に表示されている
  end;
end;

procedure TForm1.HandleProjectError(const Title, ErrorMessage: string);
begin
  ErrorDialog.ShowErrorDialog(Title, ErrorMessage);
end;

function TForm1.GetProjectPath: string;
begin
  Result := IncludeTrailingPathDelimiter(Trim(DirectoryEditProjectRoot.Text)) + 
            Trim(EditProjectName.Text);
end;

procedure TForm1.LaunchEditor(const EditorPath: string);
var
  ProjectPath: string;
begin
  // プロジェクトパスの確定
  if FCurrentProjectPath = '' then
    ProjectPath := GetProjectPath
  else
    ProjectPath := FCurrentProjectPath;

  if not DirectoryExists(ProjectPath) then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'プロジェクトフォルダが見つかりません。'#13#10 +
                  'パス: ' + ProjectPath);
    Exit;
  end;

  // プロセス作成・実行はExecuterユニットに委譲
  try
    CmdExecute(EditorPath, ProjectPath, [ProjectPath]);
  except
    on E: Exception do
      ErrorDialog.ShowErrorDialog('エラー', E.Message);
  end;
end;

procedure TForm1.BtnEditor1Click(Sender: TObject);
begin
  SaveSettings; // 設定を保存してから起動
  UpdateEditorButtons;
  LaunchEditor(FileNameEditEditor1.Text);
end;

procedure TForm1.BtnEditor2Click(Sender: TObject);
begin
  SaveSettings;
  UpdateEditorButtons;
  LaunchEditor(FileNameEditEditor2.Text);
end;

procedure TForm1.BtnEditor3Click(Sender: TObject);
begin
  SaveSettings;
  UpdateEditorButtons;
  LaunchEditor(FileNameEditEditor3.Text);
end;

procedure TForm1.BtnOpenConsoleClick(Sender: TObject);
var
  Process: TProcess;
  ProjectPath: string;
begin
  if FCurrentProjectPath = '' then
    ProjectPath := GetProjectPath
  else
    ProjectPath := FCurrentProjectPath;
  
  if not DirectoryExists(ProjectPath) then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'プロジェクトフォルダが見つかりません。'#13#10 +
                  'パス: ' + ProjectPath);
    Exit;
  end;
  
  Process := TProcess.Create(nil);
  try
    Process.Executable := 'cmd.exe';
    Process.Parameters.Add('/k');
    Process.Parameters.Add('cd /d "' + ProjectPath + '"');
    Process.Options := [];
    Process.ShowWindow := swoShow;
    Process.Execute;
  finally
    Process.Free;
  end;
end;

procedure TForm1.BtnOpenLazarusClick(Sender: TObject);
var
  LpiPath: string;
  ProjectPath: string;
begin
  if FCurrentProjectPath = '' then
    ProjectPath := GetProjectPath
  else
    ProjectPath := FCurrentProjectPath;
  
  LpiPath := IncludeTrailingPathDelimiter(ProjectPath) + 
             ExtractFileName(ProjectPath) + '.lpi';
  
  if not FileExists(LpiPath) then
  begin
    // プロジェクト名から推測
    LpiPath := IncludeTrailingPathDelimiter(ProjectPath) + 
               Trim(EditProjectName.Text) + '.lpi';
  end;
  
  if not FileExists(LpiPath) then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'LPIファイルが見つかりません。'#13#10 +
                  'パス: ' + LpiPath);
    Exit;
  end;
  
  OpenDocument(LpiPath);
end;

procedure TForm1.BtnOpenExplorerClick(Sender: TObject);
var
  ProjectPath: string;
begin
  if FCurrentProjectPath = '' then
    ProjectPath := GetProjectPath
  else
    ProjectPath := FCurrentProjectPath;
  
  if not DirectoryExists(ProjectPath) then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'プロジェクトフォルダが見つかりません。'#13#10 +
                  'パス: ' + ProjectPath);
    Exit;
  end;
  
  OpenDocument(ProjectPath);
end;

function TForm1.BuildProject: Boolean;
var
  ProjectPath, ProjectName, LpiPath, LazbuildPath: string;
  Process: TProcess;
  Output: TStringList;
  MemStream: TMemoryStream; // 読み取り用の一時バッファ
  BytesRead: Integer;
  Buffer: array[1..2048] of Byte; // 2KBずつのバッファ
  HasError: Boolean;
  i: Integer;
begin
  Result := False;

  // パスとプロジェクト名の初期設定
  if FCurrentProjectPath = '' then ProjectPath := GetProjectPath else ProjectPath := FCurrentProjectPath;
  if FCurrentProjectName <> '' then ProjectName := FCurrentProjectName else ProjectName := Trim(EditProjectName.Text);

  if not DirectoryExists(ProjectPath) then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'プロジェクトフォルダが見つかりません。' + ProjectPath);
    Exit;
  end;

  if ProjectName = '' then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'プロジェクト名が指定されていません。');
    Exit;
  end;

  LpiPath := IncludeTrailingPathDelimiter(ProjectPath) + ProjectName + '.lpi';
  if not FileExists(LpiPath) then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'LPIファイルが見つかりません。' + LpiPath);
    Exit;
  end;

  LazbuildPath := Trim(FileNameEditLazbuild.Text);
  if LazbuildPath = '' then LazbuildPath := 'C:\Lazarus\Lazbuild.exe';

  if not FileExists(LazbuildPath) then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'Lazbuildが見つかりません。' + LazbuildPath);
    Exit;
  end;

  // ビルド開始をステータスバーに表示
  StatusBar1.SimpleText := 'ビルド開始...';
  Application.ProcessMessages;

  // --- ビルド実行セクション ---
  Process := TProcess.Create(nil);
  Output := TStringList.Create;
  MemStream := TMemoryStream.Create;
  try
    try
      Process.Executable := LazbuildPath;
      Process.Parameters.Add(LpiPath);
      Process.CurrentDirectory := ProjectPath;

      // ポイント：poWaitOnExitを外し、パイプを利用する
      Process.Options := [poUsePipes, poStderrToOutPut];
      Process.ShowWindow := swoHide;

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
        if BytesRead > 0 then MemStream.Write(Buffer, BytesRead);
      until BytesRead <= 0;

      // メインストリームの内容をStringListに変換
      MemStream.Position := 0;
      Output.LoadFromStream(MemStream);

      // エラーの有無を判定
      HasError := False;
      if Process.ExitStatus <> 0 then
      begin
        HasError := True;
      end
      else
      begin
        // 出力にエラーキーワードが含まれているかチェック
        for i := 0 to Output.Count - 1 do
        begin
          if (Pos('Error', Output[i]) > 0) or 
             (Pos('error', Output[i]) > 0) or
             (Pos('エラー', Output[i]) > 0) or
             (Pos('Fatal', Output[i]) > 0) or
             (Pos('fatal', Output[i]) > 0) then
          begin
            HasError := True;
            Break;
          end;
        end;
      end;

      if HasError then
      begin
        StatusBar1.SimpleText := 'ビルド完了 - コンパイルエラーあり';
        ErrorDialog.ShowErrorDialog('ビルドエラー', 'ビルドに失敗しました。'#13#10#13#10 +
                          '終了コード: ' + IntToStr(Process.ExitStatus) + #13#10 +
                          '出力:'#13#10 + Output.Text);
        Exit;
      end
      else
      begin
        StatusBar1.SimpleText := 'ビルド完了 - コンパイルエラーなし';
        Result := True;
      end;
    except
      on E: Exception do
      begin
        StatusBar1.SimpleText := 'ビルド完了 - エラー発生';
        ErrorDialog.ShowErrorDialog('例外エラー', '実行中にエラーが発生しました: ' + E.Message);
        Exit;
      end;
    end;
  finally
    // リソースの確実な解放
    MemStream.Free;
    Output.Free;
    Process.Free;
  end;
end;

procedure TForm1.BtnBuildClick(Sender: TObject);
begin
  if BuildProject then
  begin
    // ビルド成功時はメッセージなし（ユーザー要求）
  end;
end;

procedure TForm1.BtnRunExecutableClick(Sender: TObject);
var
  ProjectPath, ExePath, ProjectName: string;
  Process: TProcess;
begin
  if FCurrentProjectPath = '' then
    ProjectPath := GetProjectPath
  else
    ProjectPath := FCurrentProjectPath;
  
  if not DirectoryExists(ProjectPath) then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'プロジェクトフォルダが見つかりません。'#13#10 +
                  'パス: ' + ProjectPath);
    Exit;
  end;
  
  // プロジェクト名を取得
  if FCurrentProjectName <> '' then
    ProjectName := FCurrentProjectName
  else
    ProjectName := Trim(EditProjectName.Text);
  
  if ProjectName = '' then
  begin
    ErrorDialog.ShowErrorDialog('エラー', 'プロジェクト名が指定されていません。');
    Exit;
  end;
  
  // 実行ファイルのパス（プロジェクトフォルダ直下）
  ExePath := IncludeTrailingPathDelimiter(ProjectPath) + ProjectName + '.exe';
  
  // 実行ファイルが見つからない場合、libフォルダ内を検索
  if not FileExists(ExePath) then
  begin
    ExePath := IncludeTrailingPathDelimiter(ProjectPath) + 
               'lib\x86_64-win64\' + ProjectName + '.exe';
  end;
  
  if not FileExists(ExePath) then
  begin
    // 実行ファイルが見つからない場合、ビルドを実行
    if not BuildProject then
    begin
      Exit; // ビルド失敗時はエラーダイアログはBuildProject内で表示済み
    end;
    
    // ビルド後、再度実行ファイルを検索
    ExePath := IncludeTrailingPathDelimiter(ProjectPath) + ProjectName + '.exe';
    if not FileExists(ExePath) then
    begin
      ExePath := IncludeTrailingPathDelimiter(ProjectPath) + 
                 'lib\x86_64-win64\' + ProjectName + '.exe';
    end;
    
    // ビルド後もファイルが見つからない場合はエラー
    if not FileExists(ExePath) then
    begin
      ErrorDialog.ShowErrorDialog('エラー', 'ビルドを実行しましたが、実行ファイルが見つかりません。'#13#10#13#10 +
                    'プロジェクト名: ' + ProjectName + #13#10 +
                    '期待されるファイル: ' + ProjectName + '.exe'#13#10 +
                    'プロジェクトフォルダ: ' + ProjectPath + #13#10#13#10 +
                    'ビルドエラーが発生した可能性があります。');
      Exit;
    end;
  end;
  
  // 実行ファイルを起動
  Process := TProcess.Create(nil);
  try
    Process.Executable := ExePath;
    Process.CurrentDirectory := ProjectPath;
    if CheckBoxShowConsole.Checked then
    begin
      // コンソールを表示する場合
      Process.Options := [];
      Process.ShowWindow := swoShow;
    end
    else
    begin
      // コンソールを表示しない場合
      Process.Options := [poNoConsole];
    end;
    Process.Execute;
  finally
    Process.Free;
  end;
end;

procedure TForm1.BtnOpenProjectClick(Sender: TObject);
var
  ProjectPath, LpiPath, LprPath, ProjectName: string;
  SearchRec: TSearchRec;
  Found: Boolean;
begin
  // プロジェクトフォルダを選択
  ProjectPath := '';
  if SelectDirectory('プロジェクトフォルダを選択', '', ProjectPath) then
  begin
    if not DirectoryExists(ProjectPath) then
    begin
      ErrorDialog.ShowErrorDialog('エラー', '選択されたフォルダが見つかりません。'#13#10 +
                    'パス: ' + ProjectPath);
      Exit;
    end;
    
    // LPIファイルを検索
    LpiPath := '';
    Found := False;
    ProjectName := ExtractFileName(ExcludeTrailingPathDelimiter(ProjectPath));
    
    // まず、フォルダ名と同じ名前のLPIファイルを探す
    LpiPath := IncludeTrailingPathDelimiter(ProjectPath) + ProjectName + '.lpi';
    if FileExists(LpiPath) then
    begin
      Found := True;
    end
    else
    begin
      // フォルダ内のすべてのLPIファイルを検索
      if FindFirst(IncludeTrailingPathDelimiter(ProjectPath) + '*.lpi', faAnyFile, SearchRec) = 0 then
      begin
        try
          repeat
            if (SearchRec.Attr and faDirectory) = 0 then
            begin
              LpiPath := IncludeTrailingPathDelimiter(ProjectPath) + SearchRec.Name;
              ProjectName := ChangeFileExt(SearchRec.Name, '');
              Found := True;
              Break;
            end;
          until FindNext(SearchRec) <> 0;
        finally
          FindClose(SearchRec);
        end;
      end;
    end;
    
    // LPIファイルが見つからない場合、.lprファイルを検索（コンソールプロジェクト対応）
    if not Found then
    begin
      // フォルダ名と同じ名前のLPRファイルを探す
      LprPath := IncludeTrailingPathDelimiter(ProjectPath) + ProjectName + '.lpr';
      if FileExists(LprPath) then
      begin
        Found := True;
      end
      else
      begin
        // フォルダ内のすべてのLPRファイルを検索
        if FindFirst(IncludeTrailingPathDelimiter(ProjectPath) + '*.lpr', faAnyFile, SearchRec) = 0 then
        begin
          try
            repeat
              if (SearchRec.Attr and faDirectory) = 0 then
              begin
                LprPath := IncludeTrailingPathDelimiter(ProjectPath) + SearchRec.Name;
                ProjectName := ChangeFileExt(SearchRec.Name, '');
                Found := True;
                Break;
              end;
            until FindNext(SearchRec) <> 0;
          finally
            FindClose(SearchRec);
          end;
        end;
      end;
    end;
    
    if not Found then
    begin
      ErrorDialog.ShowErrorDialog('エラー', 'プロジェクトファイル（.lpi または .lpr）が見つかりません。'#13#10 +
                    'パス: ' + ProjectPath);
      Exit;
    end;
    
    // プロジェクト情報を設定
    FCurrentProjectPath := ProjectPath;
    FCurrentProjectName := ProjectName;
    EditProjectName.Text := ProjectName;
    DirectoryEditProjectRoot.Text := ExtractFilePath(ExcludeTrailingPathDelimiter(ProjectPath));
    
    // 起動パネルを活性化
    PanelLaunch.Enabled := True;
  end;
end;

procedure TForm1.TabSheetMainShow(Sender: TObject);
begin
  // 設定タブで変更された可能性があるので、メインタブのプロジェクトルートを更新
  DirectoryEditProjectRoot.Text := DirectoryEditDefaultProjectRoot.Text;
  // エディタボタンも更新
  UpdateEditorButtons;
end;

end.

