unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  TOperator = (opNone, opAdd, opSubtract, opMultiply, opDivide);

  { TForm1 }

  TForm1 = class(TForm)
    Display: TEdit;
    btn0: TButton;
    btn1: TButton;
    btn2: TButton;
    btn3: TButton;
    btn4: TButton;
    btn5: TButton;
    btn6: TButton;
    btn7: TButton;
    btn8: TButton;
    btn9: TButton;
    btnAdd: TButton;
    btnSubtract: TButton;
    btnMultiply: TButton;
    btnDivide: TButton;
    btnEquals: TButton;
    btnClear: TButton;
    procedure FormCreate(Sender: TObject);
    procedure NumberClick(Sender: TObject);
    procedure OperatorClick(Sender: TObject);
    procedure btnEqualsClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
  private
    FCurrentValue: Double;
    FPreviousValue: Double;
    FCurrentOperator: TOperator;
    FNewNumber: Boolean;
    procedure Calculate;
    procedure UpdateDisplay;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FCurrentValue := 0;
  FPreviousValue := 0;
  FCurrentOperator := opNone;
  FNewNumber := True;
  UpdateDisplay;
end;

procedure TForm1.NumberClick(Sender: TObject);
var
  NumStr: String;
begin
  if FNewNumber then
  begin
    Display.Text := '';
    FNewNumber := False;
  end;

  NumStr := (Sender as TButton).Caption;
  
  if Display.Text = '0' then
    Display.Text := NumStr
  else
    Display.Text := Display.Text + NumStr;
    
  FCurrentValue := StrToFloatDef(Display.Text, 0);
end;

procedure TForm1.OperatorClick(Sender: TObject);
var
  OpStr: String;
begin
  OpStr := (Sender as TButton).Caption;
  
  if FCurrentOperator <> opNone then
    Calculate;
  
  FPreviousValue := FCurrentValue;
  FNewNumber := True;
  
  if OpStr = '+' then
    FCurrentOperator := opAdd
  else if OpStr = '-' then
    FCurrentOperator := opSubtract
  else if OpStr = '×' then
    FCurrentOperator := opMultiply
  else if OpStr = '÷' then
    FCurrentOperator := opDivide;
end;

procedure TForm1.btnEqualsClick(Sender: TObject);
begin
  if FCurrentOperator <> opNone then
  begin
    Calculate;
    FCurrentOperator := opNone;
  end;
end;

procedure TForm1.btnClearClick(Sender: TObject);
begin
  FCurrentValue := 0;
  FPreviousValue := 0;
  FCurrentOperator := opNone;
  FNewNumber := True;
  UpdateDisplay;
end;

procedure TForm1.Calculate;
begin
  case FCurrentOperator of
    opAdd:
      FCurrentValue := FPreviousValue + FCurrentValue;
    opSubtract:
      FCurrentValue := FPreviousValue - FCurrentValue;
    opMultiply:
      FCurrentValue := FPreviousValue * FCurrentValue;
    opDivide:
      if FCurrentValue <> 0 then
        FCurrentValue := FPreviousValue / FCurrentValue
      else
      begin
        Display.Text := 'エラー';
        FCurrentValue := 0;
        FNewNumber := True;
        Exit;
      end;
  end;
  
  FNewNumber := True;
  UpdateDisplay;
end;

procedure TForm1.UpdateDisplay;
var
  DisplayStr: String;
begin
  DisplayStr := FloatToStr(FCurrentValue);
  // 小数点以下が不要な場合は整数として表示
  if Frac(FCurrentValue) = 0 then
    DisplayStr := IntToStr(Trunc(FCurrentValue));
  Display.Text := DisplayStr;
end;

end.
