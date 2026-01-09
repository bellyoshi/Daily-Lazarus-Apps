unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, FileUtil,
  Zipper, IniFiles;

type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonCreateZip: TButton;
    ButtonSelectDestFolder: TButton;
    ButtonSelectFolder: TButton;
    EditDestFolder: TEdit;
    EditSourceFolder: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    procedure ButtonCreateZipClick(Sender: TObject);
    procedure ButtonSelectDestFolderClick(Sender: TObject);
    procedure ButtonSelectFolderClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    ConfigFileName: String;
    procedure LoadSettings;
    procedure SaveSettings;
    function IsExecutableFile(const FileName: String): Boolean;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  ConfigFileName := ExtractFilePath(Application.ExeName) + 'config.ini';
  LoadSettings;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  SaveSettings;
end;

procedure TForm1.LoadSettings;
var
  IniFile: TIniFile;
begin
  if FileExists(ConfigFileName) then
  begin
    IniFile := TIniFile.Create(ConfigFileName);
    try
      EditDestFolder.Text := IniFile.ReadString('Settings', 'DestFolder', '');
    finally
      IniFile.Free;
    end;
  end;
end;

procedure TForm1.SaveSettings;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(ConfigFileName);
  try
    IniFile.WriteString('Settings', 'DestFolder', EditDestFolder.Text);
  finally
    IniFile.Free;
  end;
end;

procedure TForm1.ButtonSelectFolderClick(Sender: TObject);
begin
  if SelectDirectoryDialog1.Execute then
  begin
    EditSourceFolder.Text := SelectDirectoryDialog1.FileName;
  end;
end;

procedure TForm1.ButtonSelectDestFolderClick(Sender: TObject);
begin
  if SelectDirectoryDialog1.Execute then
  begin
    EditDestFolder.Text := SelectDirectoryDialog1.FileName;
    SaveSettings; // 保存先フォルダを選択したら即座に保存
  end;
end;

function TForm1.IsExecutableFile(const FileName: String): Boolean;
var
  Ext: String;
begin
  Ext := LowerCase(ExtractFileExt(FileName));
  Result := (Ext = '.exe') or (Ext = '.dll') or (Ext = '.so') or 
            (Ext = '.dylib') or (Ext = '.app') or (Ext = '.bat') or 
            (Ext = '.cmd') or (Ext = '.com') or (Ext = '.scr');
end;

procedure TForm1.ButtonCreateZipClick(Sender: TObject);
var
  SourceFolder, DestFolder, ZipFileName, FolderName: String;
  ZipFile: TZipper;
  FileList: TStringList;
  i: Integer;
  RelativePath: String;
begin
  SourceFolder := Trim(EditSourceFolder.Text);
  DestFolder := Trim(EditDestFolder.Text);

  if SourceFolder = '' then
  begin
    ShowMessage('圧縮フォルダを選択してください。');
    Exit;
  end;

  if not DirectoryExists(SourceFolder) then
  begin
    ShowMessage('圧縮フォルダが存在しません。');
    Exit;
  end;

  if DestFolder = '' then
  begin
    ShowMessage('保存先フォルダを選択してください。');
    Exit;
  end;

  if not DirectoryExists(DestFolder) then
  begin
    if not ForceDirectories(DestFolder) then
    begin
      ShowMessage('保存先フォルダを作成できませんでした。');
      Exit;
    end;
  end;

  // フォルダ名を取得
  FolderName := ExtractFileName(ExcludeTrailingPathDelimiter(SourceFolder));
  if FolderName = '' then
    FolderName := 'Archive';

  ZipFileName := IncludeTrailingPathDelimiter(DestFolder) + FolderName + '.zip';

  // 既存のZipファイルを削除
  if FileExists(ZipFileName) then
    DeleteFile(ZipFileName);

  ZipFile := TZipper.Create;
  FileList := TStringList.Create;
  try
    // すべてのファイルを再帰的に取得
    FindAllFiles(FileList, SourceFolder, '*', True);

    // 実行ファイルを除外してZipに追加
    for i := 0 to FileList.Count - 1 do
    begin
      if not IsExecutableFile(FileList[i]) then
      begin
        RelativePath := ExtractRelativePath(IncludeTrailingPathDelimiter(SourceFolder), FileList[i]);
        ZipFile.Entries.AddFileEntry(FileList[i], RelativePath);
      end;
    end;

    ZipFile.FileName := ZipFileName;
    ZipFile.ZipAllFiles;
    
    ShowMessage('圧縮が完了しました。' + #13#10 + ZipFileName);
  finally
    FileList.Free;
    ZipFile.Free;
  end;
end;

end.
