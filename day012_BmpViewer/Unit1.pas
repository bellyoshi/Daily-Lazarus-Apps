unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Menus,
  StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Image1: TImage;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := 'BMP Viewer';
  OpenDialog1.Filter := 'Bitmap Files (*.bmp)|*.bmp|All Files (*.*)|*.*';
  OpenDialog1.DefaultExt := 'bmp';
end;

procedure TForm1.MenuItem2Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    try
      Image1.Picture.LoadFromFile(OpenDialog1.FileName);
      Caption := 'BMP Viewer - ' + ExtractFileName(OpenDialog1.FileName);
    except
      on E: Exception do
        ShowMessage('画像の読み込みに失敗しました: ' + E.Message);
    end;
  end;
end;

end.
