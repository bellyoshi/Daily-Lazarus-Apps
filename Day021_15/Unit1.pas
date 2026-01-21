unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure ButtonClick(Sender: TObject);
  private
    Buttons: array[0..15] of TButton;
    Puzzle: array[0..3, 0..3] of Integer; // パズルの状態（0が空白）
    EmptyRow, EmptyCol: Integer; // 空白の位置
    
    procedure InitializePuzzle;
    procedure UpdateButtons;
    procedure MoveTile(Row, Col: Integer);
    function IsValidMove(Row, Col: Integer): Boolean;
    function IsSolved: Boolean;
    procedure ShufflePuzzle;
    procedure CheckWin;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  i, Row, Col: Integer;
  Btn: TButton;
begin
  // 乱数初期化
  Randomize;
  
  // フォームのサイズとタイトルを設定
  Width := 400;
  Height := 450;
  Caption := '15パズル';
  
  // 16個のボタンを固定位置で作成
  for i := 0 to 15 do
  begin
    Row := i div 4;
    Col := i mod 4;
    
    // ボタンを作成
    Btn := TButton.Create(Self);
    
    // Formにボタンを追加（重要：これがないとボタンが表示されない）
    Btn.Parent := Self;

    
    // ボタンのプロパティを設定
    Btn.Tag := i; // Tagで位置管理（0-15）
    Btn.Left := 20 + Col * 90;
    Btn.Top := 20 + Row * 90;
    Btn.Width := 80;
    Btn.Height := 80;
    Btn.Font.Size := 16;
    Btn.Font.Style := [fsBold];
    Btn.Caption := ''; // 初期は空、UpdateButtonsで設定
    Btn.Visible := True;
    Btn.OnClick := @ButtonClick;

    // ボタンを配列に保存
    Buttons[i] := Btn;
  end;
  
  // パズルを初期化
  InitializePuzzle;
  UpdateButtons;
end;

procedure TForm1.InitializePuzzle;
var
  i, Row, Col: Integer;
begin
  // 完成状態で初期化（1-15, 0）
  i := 1;
  for Row := 0 to 3 do
    for Col := 0 to 3 do
    begin
      if i <= 15 then
        Puzzle[Row, Col] := i
      else
        Puzzle[Row, Col] := 0;
      Inc(i);
    end;
  
  // 空白の位置を設定（右下）
  EmptyRow := 3;
  EmptyCol := 3;
  
  // シャッフル
  ShufflePuzzle;
end;

procedure TForm1.UpdateButtons;
var
  i, Row, Col, Value: Integer;
begin
  // パズルの状態をボタンに反映（テキストのみ更新）
  for i := 0 to 15 do
  begin
    Row := i div 4;
    Col := i mod 4;
    Value := Puzzle[Row, Col];
    
    if Value = 0 then
      Buttons[i].Caption := '' // 空白の位置は空文字列
    else
      Buttons[i].Caption := IntToStr(Value);
  end;
end;

procedure TForm1.ButtonClick(Sender: TObject);
var
  ClickedTag, Row, Col: Integer;
begin
  if Sender is TButton then
  begin
    ClickedTag := (Sender as TButton).Tag;
    Row := ClickedTag div 4; // Tagから位置を計算
    Col := ClickedTag mod 4;
    
    // 空白の位置でない場合のみ移動可能
    if Puzzle[Row, Col] <> 0 then
    begin
      // 合法手かチェックして移動
      if IsValidMove(Row, Col) then
      begin
        MoveTile(Row, Col);
        UpdateButtons;
        CheckWin;
      end;
    end;
  end;
end;

function TForm1.IsValidMove(Row, Col: Integer): Boolean;
begin
  // 空白の隣（上下左右）かチェック
  Result := ((Row = EmptyRow) and (Abs(Col - EmptyCol) = 1)) or
            ((Col = EmptyCol) and (Abs(Row - EmptyRow) = 1));
end;

procedure TForm1.MoveTile(Row, Col: Integer);
begin
  // タイルを空白の位置に移動
  Puzzle[EmptyRow, EmptyCol] := Puzzle[Row, Col];
  Puzzle[Row, Col] := 0;
  
  // 空白の位置を更新
  EmptyRow := Row;
  EmptyCol := Col;
end;

function TForm1.IsSolved: Boolean;
var
  Row, Col, Expected: Integer;
begin
  Expected := 1;
  Result := True;
  
  for Row := 0 to 3 do
    for Col := 0 to 3 do
    begin
      if (Row = 3) and (Col = 3) then
      begin
        // 最後のマスは空白（0）であるべき
        if Puzzle[Row, Col] <> 0 then
        begin
          Result := False;
          Exit;
        end;
      end
      else
      begin
        if Puzzle[Row, Col] <> Expected then
        begin
          Result := False;
          Exit;
        end;
        Inc(Expected);
      end;
    end;
end;

procedure TForm1.CheckWin;
begin
  if IsSolved then
  begin
    ShowMessage('クリア！おめでとうございます！');
    // 再シャッフル
    ShufflePuzzle;
    UpdateButtons;
  end;
end;

procedure TForm1.ShufflePuzzle;
var
  i, RandomMove, NewRow, NewCol: Integer;
  ValidMoves: array[0..3] of record
    Row, Col: Integer;
  end;
  MoveCount: Integer;
begin
  // 完成状態から合法手のみで1000回ランダムに移動
  for i := 1 to 1000 do
  begin
    MoveCount := 0;
    
    // 合法手を収集
    // 上
    if EmptyRow > 0 then
    begin
      ValidMoves[MoveCount].Row := EmptyRow - 1;
      ValidMoves[MoveCount].Col := EmptyCol;
      Inc(MoveCount);
    end;
    // 下
    if EmptyRow < 3 then
    begin
      ValidMoves[MoveCount].Row := EmptyRow + 1;
      ValidMoves[MoveCount].Col := EmptyCol;
      Inc(MoveCount);
    end;
    // 左
    if EmptyCol > 0 then
    begin
      ValidMoves[MoveCount].Row := EmptyRow;
      ValidMoves[MoveCount].Col := EmptyCol - 1;
      Inc(MoveCount);
    end;
    // 右
    if EmptyCol < 3 then
    begin
      ValidMoves[MoveCount].Row := EmptyRow;
      ValidMoves[MoveCount].Col := EmptyCol + 1;
      Inc(MoveCount);
    end;
    
    // ランダムに合法手を選択して移動
    if MoveCount > 0 then
    begin
      RandomMove := Random(MoveCount);
      NewRow := ValidMoves[RandomMove].Row;
      NewCol := ValidMoves[RandomMove].Col;
      
      // 移動実行
      Puzzle[EmptyRow, EmptyCol] := Puzzle[NewRow, NewCol];
      Puzzle[NewRow, NewCol] := 0;
      EmptyRow := NewRow;
      EmptyCol := NewCol;
    end;
  end;
end;

end.
