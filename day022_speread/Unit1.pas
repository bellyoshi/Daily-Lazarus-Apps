unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
  fpspreadsheet, fpspreadsheetgrid, fpsallformats, fpstypes;

type

  { TForm1 }

  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    MenuItemFile: TMenuItem;
    MenuItemLoad: TMenuItem;
    MenuItemExit: TMenuItem;
    OpenDialog1: TOpenDialog;
    sWorksheetGrid1: TsWorksheetGrid;
    procedure MenuItemLoadClick(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private

  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}


{ --- 読み込み処理 --- }
procedure TForm1.MenuItemLoadClick(Sender: TObject);
begin
  if not OpenDialog1.Execute then
  begin
    Exit;
  end;

  if not FileExists(OpenDialog1.FileName) then
  begin
    ShowMessage('ファイルが見つかりません: ' + OpenDialog1.FileName);
    Exit;
  end;

  try
    // 1. ファイルから読み込む
    sWorksheetGrid1.Workbook.ReadFromFile(OpenDialog1.FileName, sfOOXML);
    ShowMessage('読み込みました');
  except
    on E: Exception do
      ShowMessage('読み込みに失敗しました: ' + E.Message);
  end;
end;

{ --- 終了処理 --- }
procedure TForm1.MenuItemExitClick(Sender: TObject);
begin
  Close;
end;

{ --- アプリ終了時の処理 --- }
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  // 終了時の処理なし
end;

end.
