unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls, ExtCtrls;

const
  GRID_SIZE = 8;  // 8x8のグリッド
  MINE_COUNT = 10; // 10個の地雷

type
  TCellState = (csClosed, csOpen, csFlagged);
  
  { TForm1 }

  TForm1 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure CellClick(Sender: TObject);
    procedure CellRightClick(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button1Click(Sender: TObject);
  private
    GridButtons: array[0..GRID_SIZE-1, 0..GRID_SIZE-1] of TSpeedButton;
    Mines: array[0..GRID_SIZE-1, 0..GRID_SIZE-1] of Boolean;
    CellStates: array[0..GRID_SIZE-1, 0..GRID_SIZE-1] of TCellState;
    GameOver: Boolean;
    GameStarted: Boolean;
    procedure InitializeGame;
    procedure PlaceMines(ExcludeRow, ExcludeCol: Integer);
    procedure OpenCell(Row, Col: Integer);
    function CountAdjacentMines(Row, Col: Integer): Integer;
    procedure CheckWinCondition;
    procedure RevealAllMines;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  i, j: Integer;
  Btn: TSpeedButton;
begin
  // フォームのサイズとタイトルを設定
  Width := GRID_SIZE * 35 + 50;
  Height := GRID_SIZE * 35 + 120;
  Caption := 'マインスイーパー - 簡単レベル';
  
  // パネルの設定
  Panel1.Left := 10;
  Panel1.Top := 10;
  Panel1.Width := GRID_SIZE * 35;
  Panel1.Height := GRID_SIZE * 35;
  Panel1.Caption := '';
  
  // ラベルの設定
  Label1.Left := 10;
  Label1.Top := GRID_SIZE * 35 + 20;
  Label1.Caption := '地雷: ' + IntToStr(MINE_COUNT);
  
  // リセットボタンの設定
  Button1.Left := 10;
  Button1.Top := GRID_SIZE * 35 + 50;
  Button1.Caption := '新しいゲーム';
  Button1.Width := 120;
  
  // グリッドボタンの作成
  for i := 0 to GRID_SIZE - 1 do
  begin
    for j := 0 to GRID_SIZE - 1 do
    begin
      Btn := TSpeedButton.Create(Self);
      Btn.Parent := Panel1;
      Btn.Left := j * 35;
      Btn.Top := i * 35;
      Btn.Width := 33;
      Btn.Height := 33;
      Btn.Caption := '';
      Btn.Tag := i * GRID_SIZE + j;
      Btn.OnClick := @CellClick;
      Btn.OnMouseDown := @CellRightClick;
      GridButtons[i, j] := Btn;
    end;
  end;
  
  InitializeGame;
end;

procedure TForm1.InitializeGame;
var
  i, j: Integer;
begin
  GameOver := False;
  GameStarted := False;
  Label1.Caption := '地雷: ' + IntToStr(MINE_COUNT);
  
  // すべてのセルをリセット
  for i := 0 to GRID_SIZE - 1 do
  begin
    for j := 0 to GRID_SIZE - 1 do
    begin
      Mines[i, j] := False;
      CellStates[i, j] := csClosed;
      GridButtons[i, j].Caption := '';
      GridButtons[i, j].Enabled := True;
      GridButtons[i, j].Font.Color := clBlack;
    end;
  end;
  
  // 地雷は初手クリック後に配置する
end;

procedure TForm1.PlaceMines(ExcludeRow, ExcludeCol: Integer);
var
  Count, Row, Col: Integer;
begin
  Randomize;
  Count := 0;
  
  while Count < MINE_COUNT do
  begin
    Row := Random(GRID_SIZE);
    Col := Random(GRID_SIZE);
    
    // 初手の位置とその周囲には地雷を配置しない
    if (Row = ExcludeRow) and (Col = ExcludeCol) then Continue;
    if (Abs(Row - ExcludeRow) <= 1) and (Abs(Col - ExcludeCol) <= 1) then Continue;
    
    if not Mines[Row, Col] then
    begin
      Mines[Row, Col] := True;
      Inc(Count);
    end;
  end;
end;

procedure TForm1.CellClick(Sender: TObject);
var
  Row, Col: Integer;
  TagValue: Integer;
begin
  if GameOver then Exit;
  
  TagValue := (Sender as TSpeedButton).Tag;
  Row := TagValue div GRID_SIZE;
  Col := TagValue mod GRID_SIZE;
  
  if CellStates[Row, Col] = csFlagged then Exit;
  
  // 初手の場合は地雷を配置してから開く
  if not GameStarted then
  begin
    GameStarted := True;
    PlaceMines(Row, Col);
  end;
  
  OpenCell(Row, Col);
end;

procedure TForm1.CellRightClick(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Row, Col: Integer;
  TagValue: Integer;
  FlagCount: Integer;
  i, j: Integer;
begin
  if GameOver then Exit;
  if Button <> mbRight then Exit;
  
  TagValue := (Sender as TSpeedButton).Tag;
  Row := TagValue div GRID_SIZE;
  Col := TagValue mod GRID_SIZE;
  
  if CellStates[Row, Col] = csOpen then Exit;
  
  // フラグの切り替え
  if CellStates[Row, Col] = csFlagged then
  begin
    CellStates[Row, Col] := csClosed;
    GridButtons[Row, Col].Caption := '';
  end
  else
  begin
    CellStates[Row, Col] := csFlagged;
    GridButtons[Row, Col].Caption := '🚩';
  end;
  
  // フラグの数をカウント
  FlagCount := 0;
  for i := 0 to GRID_SIZE - 1 do
    for j := 0 to GRID_SIZE - 1 do
      if CellStates[i, j] = csFlagged then
        Inc(FlagCount);
  
  Label1.Caption := '地雷: ' + IntToStr(MINE_COUNT - FlagCount);
end;

procedure TForm1.OpenCell(Row, Col: Integer);
var
  AdjacentMines: Integer;
begin
  if (Row < 0) or (Row >= GRID_SIZE) or (Col < 0) or (Col >= GRID_SIZE) then Exit;
  if CellStates[Row, Col] <> csClosed then Exit;
  
  CellStates[Row, Col] := csOpen;
  GridButtons[Row, Col].Enabled := False;
  
  if Mines[Row, Col] then
  begin
    // 地雷を踏んだ
    GridButtons[Row, Col].Caption := '💣';
    GridButtons[Row, Col].Font.Color := clRed;
    GameOver := True;
    RevealAllMines;
    ShowMessage('ゲームオーバー！地雷を踏んでしまいました。');
    Exit;
  end;
  
  // 周囲の地雷数を計算
  AdjacentMines := CountAdjacentMines(Row, Col);
  
  if AdjacentMines > 0 then
  begin
    GridButtons[Row, Col].Caption := IntToStr(AdjacentMines);
    // 数字に応じて色を変える
    case AdjacentMines of
      1: GridButtons[Row, Col].Font.Color := clBlue;
      2: GridButtons[Row, Col].Font.Color := clGreen;
      3: GridButtons[Row, Col].Font.Color := clRed;
      4: GridButtons[Row, Col].Font.Color := clPurple;
      5: GridButtons[Row, Col].Font.Color := clMaroon;
      6: GridButtons[Row, Col].Font.Color := clTeal;
      7: GridButtons[Row, Col].Font.Color := clBlack;
      8: GridButtons[Row, Col].Font.Color := clGray;
    end;
  end
  else
  begin
    // 周囲に地雷がない場合は自動的に開く
    OpenCell(Row - 1, Col - 1);
    OpenCell(Row - 1, Col);
    OpenCell(Row - 1, Col + 1);
    OpenCell(Row, Col - 1);
    OpenCell(Row, Col + 1);
    OpenCell(Row + 1, Col - 1);
    OpenCell(Row + 1, Col);
    OpenCell(Row + 1, Col + 1);
  end;
  
  CheckWinCondition;
end;

function TForm1.CountAdjacentMines(Row, Col: Integer): Integer;
var
  i, j: Integer;
begin
  Result := 0;
  for i := Row - 1 to Row + 1 do
  begin
    for j := Col - 1 to Col + 1 do
    begin
      if (i >= 0) and (i < GRID_SIZE) and (j >= 0) and (j < GRID_SIZE) then
      begin
        if Mines[i, j] then
          Inc(Result);
      end;
    end;
  end;
end;

procedure TForm1.CheckWinCondition;
var
  i, j, OpenCount: Integer;
begin
  OpenCount := 0;
  for i := 0 to GRID_SIZE - 1 do
  begin
    for j := 0 to GRID_SIZE - 1 do
    begin
      if (CellStates[i, j] = csOpen) and (not Mines[i, j]) then
        Inc(OpenCount);
    end;
  end;
  
  // すべての安全なセルが開かれたら勝利
  if OpenCount = (GRID_SIZE * GRID_SIZE - MINE_COUNT) then
  begin
    GameOver := True;
    RevealAllMines;
    ShowMessage('おめでとうございます！ゲームクリア！');
  end;
end;

procedure TForm1.RevealAllMines;
var
  i, j: Integer;
begin
  for i := 0 to GRID_SIZE - 1 do
  begin
    for j := 0 to GRID_SIZE - 1 do
    begin
      if Mines[i, j] then
      begin
        if CellStates[i, j] <> csOpen then
        begin
          GridButtons[i, j].Caption := '💣';
          GridButtons[i, j].Enabled := False;
        end;
      end;
    end;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  InitializeGame;
end;

end.
