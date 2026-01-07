unit ErrorDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Graphics;

procedure ShowErrorDialog(const Title, ErrorMessage: string);

implementation

procedure ShowErrorDialog(const Title, ErrorMessage: string);
var
  ErrorForm: TForm;
  Memo: TMemo;
  BtnOK: TButton;
begin
  ErrorForm := TForm.Create(nil);
  try
    ErrorForm.Caption := Title;
    ErrorForm.Width := 600;
    ErrorForm.Height := 400;
    ErrorForm.Position := poScreenCenter;
    ErrorForm.BorderStyle := bsDialog;
    
    Memo := TMemo.Create(ErrorForm);
    Memo.Parent := ErrorForm;
    Memo.Left := 8;
    Memo.Top := 8;
    Memo.Width := ErrorForm.ClientWidth - 16;
    Memo.Height := ErrorForm.ClientHeight - 48;
    Memo.Anchors := [akLeft, akTop, akRight, akBottom];
    Memo.ScrollBars := ssBoth;
    Memo.ReadOnly := True;
    Memo.WordWrap := False;
    Memo.Text := ErrorMessage;
    Memo.Font.Name := 'Consolas';
    Memo.Font.Size := 9;
    
    BtnOK := TButton.Create(ErrorForm);
    BtnOK.Parent := ErrorForm;
    BtnOK.Caption := 'OK';
    BtnOK.ModalResult := mrOK;
    BtnOK.Default := True;
    BtnOK.Left := (ErrorForm.ClientWidth - BtnOK.Width) div 2;
    BtnOK.Top := ErrorForm.ClientHeight - 36;
    BtnOK.Anchors := [akBottom];
    
    ErrorForm.ShowModal;
  finally
    ErrorForm.Free;
  end;
end;

end.




