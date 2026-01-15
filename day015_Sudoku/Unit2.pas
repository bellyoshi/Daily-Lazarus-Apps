unit Unit2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  SudokuSolver;

type

  { TForm2 - 解を表示するウィンドウ }

  TForm2 = class(TForm)
    Panel1: TPanel;
    BtnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
  private
    FCells: array[0..8, 0..8] of TPanel;
    procedure CreateSolutionGrid;
  public
    procedure ShowSolution(const ASolution: TSudokuGrid);
  end;

var
  Form2: TForm2;

implementation

{$R *.lfm}

{ TForm2 }

procedure TForm2.FormCreate(Sender: TObject);
begin
  CreateSolutionGrid;
  BtnClose.Caption := '閉じる';
  BtnClose.Width := 100;
  BtnClose.Height := 35;
  BtnClose.Left := (Panel1.Width - BtnClose.Width) div 2;
  BtnClose.Top := (Panel1.Height - BtnClose.Height) div 2;
end;

procedure TForm2.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TForm2.CreateSolutionGrid;
var
  Row, Col: Integer;
  Cell: TPanel;
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
  
  // 9x9のグリッドを作成（読み取り専用のパネル）
  for Row := 0 to 8 do
  begin
    for Col := 0 to 8 do
    begin
      Cell := TPanel.Create(Self);
      Cell.Parent := Self;
      Cell.Width := CellSize;
      Cell.Height := CellSize;
      
      // 3x3の区切り線を考慮した位置計算
      X := Col * CellSize + (Col div 3) * ThickLine + 10;
      Y := Row * CellSize + (Row div 3) * ThickLine + 10;
      Cell.Left := X;
      Cell.Top := Y;
      
      Cell.BevelOuter := bvLowered;
      Cell.Caption := '';
      Cell.Font.Size := 16;
      Cell.Font.Style := [fsBold];
      Cell.Color := clWhite;
      Cell.Alignment := taCenter;
      
      FCells[Row, Col] := Cell;
    end;
  end;
  
  // パネルとボタンの配置
  Panel1.Left := 10;
  Panel1.Top := 9 * CellSize + 3 * ThickLine + 20;
  Panel1.Width := 9 * CellSize + 2 * ThickLine;
  Panel1.Height := 50;
  
  // フォームのサイズを調整
  Self.Width := 9 * CellSize + 2 * ThickLine + 40;
  Self.Height := 9 * CellSize + 3 * ThickLine + Panel1.Height + 60;
  Self.Caption := '数独ソルバー - 解';
end;

procedure TForm2.ShowSolution(const ASolution: TSudokuGrid);
var
  Row, Col: Integer;
begin
  for Row := 0 to 8 do
  begin
    for Col := 0 to 8 do
    begin
      if ASolution[Row, Col] <> 0 then
        FCells[Row, Col].Caption := IntToStr(ASolution[Row, Col])
      else
        FCells[Row, Col].Caption := '';
    end;
  end;
end;

end.
