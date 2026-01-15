unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  SudokuSolver, Unit2;

type

  { TForm1 }

  TForm1 = class(TForm)
    Panel1: TPanel;
    BtnSolve: TButton;
    procedure FormCreate(Sender: TObject);
    procedure BtnSolveClick(Sender: TObject);
    procedure CellKeyPress(Sender: TObject; var Key: char);
    procedure CellChange(Sender: TObject);
  private
    FCells: array[0..8, 0..8] of TEdit;
    procedure CreateSudokuGrid;
    function GetGrid: TSudokuGrid;
    procedure SetGrid(const AGrid: TSudokuGrid);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  CreateSudokuGrid;
end;

procedure TForm1.CreateSudokuGrid;
var
  Row, Col: Integer;
  Cell: TEdit;
  X, Y: Integer;
  CellSize: Integer;
  ThickLine: Integer;
  Line: TPanel;
  i: Integer;
begin
  CellSize := 40;
  ThickLine := 3;
  
  // 3x3の区切り線を描画（縦線）
  for i := 1 to 2 do
  begin
    Line := TPanel.Create(Self);
    Line.Parent := Self;
    Line.Width := ThickLine;
    Line.Height := 9 * CellSize + 2 * ThickLine;
    Line.Left := 10 + i * 3 * CellSize + (i - 1) * ThickLine;
    Line.Top := 10;
    Line.BevelOuter := bvNone;
    Line.Color := clBlack;
    Line.Enabled := False;
  end;
  
  // 3x3の区切り線を描画（横線）
  for i := 1 to 2 do
  begin
    Line := TPanel.Create(Self);
    Line.Parent := Self;
    Line.Width := 9 * CellSize + 2 * ThickLine;
    Line.Height := ThickLine;
    Line.Left := 10;
    Line.Top := 10 + i * 3 * CellSize + (i - 1) * ThickLine;
    Line.BevelOuter := bvNone;
    Line.Color := clBlack;
    Line.Enabled := False;
  end;
  
  // 9x9のグリッドを作成
  for Row := 0 to 8 do
  begin
    for Col := 0 to 8 do
    begin
      Cell := TEdit.Create(Self);
      Cell.Parent := Self;
      Cell.Width := CellSize;
      Cell.Height := CellSize;
      
      // 3x3の区切り線を考慮した位置計算
      X := Col * CellSize + (Col div 3) * ThickLine + 10;
      Y := Row * CellSize + (Row div 3) * ThickLine + 10;
      Cell.Left := X;
      Cell.Top := Y;
      
      Cell.MaxLength := 1;
      Cell.Alignment := taCenter;
      Cell.Font.Size := 16;
      Cell.Font.Style := [fsBold];
      Cell.Text := '';
      Cell.Tag := Row * 9 + Col;
      Cell.OnKeyPress := @CellKeyPress;
      Cell.OnChange := @CellChange;
      
      FCells[Row, Col] := Cell;
    end;
  end;
  
  // パネルとボタンの配置
  Panel1.Left := 10;
  Panel1.Top := 9 * CellSize + 3 * ThickLine + 20;
  Panel1.Width := 9 * CellSize + 2 * ThickLine;
  Panel1.Height := 50;
  
  BtnSolve.Caption := 'ソルバー';
  BtnSolve.Width := 100;
  BtnSolve.Height := 35;
  BtnSolve.Left := (Panel1.Width - BtnSolve.Width) div 2;
  BtnSolve.Top := (Panel1.Height - BtnSolve.Height) div 2;
  
  // フォームのサイズを調整
  Self.Width := 9 * CellSize + 2 * ThickLine + 40;
  Self.Height := 9 * CellSize + 3 * ThickLine + Panel1.Height + 60;
  Self.Caption := '数独ソルバー - 問題入力';
end;

procedure TForm1.CellKeyPress(Sender: TObject; var Key: char);
var
  Edit: TEdit;
begin
  Edit := Sender as TEdit;
  
  // 数字1-9のみ許可、または削除キー
  if not (Key in ['1'..'9', #8, #127]) then
    Key := #0;
end;

procedure TForm1.CellChange(Sender: TObject);
var
  Edit: TEdit;
  CellText: String;
begin
  Edit := Sender as TEdit;
  CellText := Edit.Text;
  
  // 数字以外の文字を削除
  if (CellText <> '') and not (CellText[1] in ['1'..'9']) then
    Edit.Text := '';
end;

function TForm1.GetGrid: TSudokuGrid;
var
  Row, Col: Integer;
  CellText: String;
  Value: Integer;
begin
  for Row := 0 to 8 do
  begin
    for Col := 0 to 8 do
    begin
      CellText := FCells[Row, Col].Text;
      if (CellText <> '') and (CellText[1] in ['1'..'9']) then
        Value := StrToInt(CellText[1])
      else
        Value := 0;
      Result[Row, Col] := Value;
    end;
  end;
end;

procedure TForm1.SetGrid(const AGrid: TSudokuGrid);
var
  Row, Col: Integer;
begin
  for Row := 0 to 8 do
  begin
    for Col := 0 to 8 do
    begin
      if AGrid[Row, Col] <> 0 then
        FCells[Row, Col].Text := IntToStr(AGrid[Row, Col])
      else
        FCells[Row, Col].Text := '';
    end;
  end;
end;

procedure TForm1.BtnSolveClick(Sender: TObject);
var
  Grid, Solution: TSudokuGrid;
  Solver: TSudokuSolver;
begin
  Grid := GetGrid;
  
  Solver := TSudokuSolver.Create;
  try
    if Solver.Solve(Grid, Solution) then
    begin
      if not Assigned(Unit2.Form2) then
      begin
        Unit2.Form2 := TForm2.Create(Application);
      end;
      Unit2.Form2.ShowSolution(Solution);
      Unit2.Form2.Show;
    end
    else
    begin
      ShowMessage('解が見つかりませんでした。');
    end;
  finally
    Solver.Free;
  end;
end;

end.
