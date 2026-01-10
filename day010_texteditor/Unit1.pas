unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus;

type

  { TForm1 }

  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    MenuFile: TMenuItem;
    MenuNew: TMenuItem;
    MenuOpen: TMenuItem;
    MenuSave: TMenuItem;
    MenuSaveAs: TMenuItem;
    Separator1: TMenuItem;
    MenuExit: TMenuItem;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure MenuExitClick(Sender: TObject);
    procedure MenuNewClick(Sender: TObject);
    procedure MenuOpenClick(Sender: TObject);
    procedure MenuSaveAsClick(Sender: TObject);
    procedure MenuSaveClick(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
  private
    FFileName: string;
    FModified: Boolean;
    procedure UpdateCaption;
    function SaveFile: Boolean;
    function SaveFileAs: Boolean;
    procedure LoadFile(const AFileName: string);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.UpdateCaption;
var
  Title: string;
begin
  if FFileName <> '' then
    Title := ExtractFileName(FFileName)
  else
    Title := '無題';
  
  if FModified then
    Title := Title + ' *';
  
  Caption := Title + ' - シンプルテキストエディター';
end;

function TForm1.SaveFile: Boolean;
begin
  Result := True;
  if FFileName = '' then
    Result := SaveFileAs
  else
  begin
    try
      Memo1.Lines.SaveToFile(FFileName);
      FModified := False;
      UpdateCaption;
    except
      on E: Exception do
      begin
        ShowMessage('ファイルの保存に失敗しました: ' + E.Message);
        Result := False;
      end;
    end;
  end;
end;

function TForm1.SaveFileAs: Boolean;
begin
  Result := False;
  if SaveDialog1.Execute then
  begin
    FFileName := SaveDialog1.FileName;
    Result := SaveFile;
  end;
end;

procedure TForm1.LoadFile(const AFileName: string);
begin
  try
    Memo1.Lines.LoadFromFile(AFileName);
    FFileName := AFileName;
    FModified := False;
    UpdateCaption;
  except
    on E: Exception do
      ShowMessage('ファイルの読み込みに失敗しました: ' + E.Message);
  end;
end;

procedure TForm1.MenuNewClick(Sender: TObject);
begin
  if FModified then
  begin
    case MessageDlg('変更が保存されていません。保存しますか？',
      mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
      mrYes:
        if not SaveFile then
          Exit;
      mrCancel:
        Exit;
    end;
  end;
  
  Memo1.Clear;
  FFileName := '';
  FModified := False;
  UpdateCaption;
end;

procedure TForm1.MenuOpenClick(Sender: TObject);
begin
  if FModified then
  begin
    case MessageDlg('変更が保存されていません。保存しますか？',
      mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
      mrYes:
        if not SaveFile then
          Exit;
      mrCancel:
        Exit;
    end;
  end;
  
  if OpenDialog1.Execute then
    LoadFile(OpenDialog1.FileName);
end;

procedure TForm1.MenuSaveClick(Sender: TObject);
begin
  SaveFile;
end;

procedure TForm1.MenuSaveAsClick(Sender: TObject);
begin
  SaveFileAs;
end;

procedure TForm1.MenuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.Memo1Change(Sender: TObject);
begin
  if not FModified then
  begin
    FModified := True;
    UpdateCaption;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if FModified then
  begin
    case MessageDlg('変更が保存されていません。保存しますか？',
      mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
      mrYes:
        if not SaveFile then
          CloseAction := caNone;
      mrCancel:
        CloseAction := caNone;
    end;
  end;
end;

end.
