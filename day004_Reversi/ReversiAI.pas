unit ReversiAI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ReversiGame;

type
  TAIDifficulty = (aiEasy, aiMedium, aiHard);

  { TReversiAI }

  TReversiAI = class
  private
    FDifficulty: TAIDifficulty;
    function EvaluateMove(Game: TReversiGame; X, Y: Integer; Player: TPlayer): Integer;
    function CountFlippedPieces(Game: TReversiGame; X, Y: Integer; Player: TPlayer): Integer;
    function GetPositionValue(X, Y: Integer): Integer;
    function GetBestMove(Game: TReversiGame; Player: TPlayer; var BestX, BestY: Integer): Boolean;
  public
    constructor Create(Difficulty: TAIDifficulty = aiMedium);
    function GetMove(Game: TReversiGame; Player: TPlayer; var X, Y: Integer): Boolean;
    procedure SetDifficulty(Difficulty: TAIDifficulty);
    function GetDifficulty: TAIDifficulty;
  end;

implementation

{ TReversiAI }

constructor TReversiAI.Create(Difficulty: TAIDifficulty);
begin
  FDifficulty := Difficulty;
end;

function TReversiAI.GetPositionValue(X, Y: Integer): Integer;
const
  // 位置の価値テーブル（角が最も高く、端の隣は低い）
  PositionValues: array[0..7, 0..7] of Integer = (
    (100, -20,  10,   5,   5,  10, -20, 100),
    (-20, -30,  -5,  -5,  -5,  -5, -30, -20),
    ( 10,  -5,   1,   1,   1,   1,  -5,  10),
    (  5,  -5,   1,   1,   1,   1,  -5,   5),
    (  5,  -5,   1,   1,   1,   1,  -5,   5),
    ( 10,  -5,   1,   1,   1,   1,  -5,  10),
    (-20, -30,  -5,  -5,  -5,  -5, -30, -20),
    (100, -20,  10,   5,   5,  10, -20, 100)
  );
begin
  Result := PositionValues[Y, X];
end;

function TReversiAI.CountFlippedPieces(Game: TReversiGame; X, Y: Integer; Player: TPlayer): Integer;
var
  Board: TBoard;
  DX, DY: Integer;
  Count, Total: Integer;
  CX, CY: Integer;
  Opponent: TPlayer;
  OpponentPiece, PlayerPiece: TPiece;
begin
  Total := 0;
  Board := Game.GetBoard;
  
  if Player = plBlack then
  begin
    PlayerPiece := pBlack;
    Opponent := plWhite;
    OpponentPiece := pWhite;
  end
  else
  begin
    PlayerPiece := pWhite;
    Opponent := plBlack;
    OpponentPiece := pBlack;
  end;

  // 8方向をチェックして反転できる石の数を数える
  for DX := -1 to 1 do
    for DY := -1 to 1 do
    begin
      if (DX = 0) and (DY = 0) then
        Continue;

      Count := 0;
      CX := X + DX;
      CY := Y + DY;

      // 相手の石を数える
      while (CX >= 0) and (CX < 8) and (CY >= 0) and (CY < 8) and
            (Board[CX, CY] = OpponentPiece) do
      begin
        Inc(Count);
        CX := CX + DX;
        CY := CY + DY;
      end;

      // 最後に自分の石がある場合、反転できる
      if (Count > 0) and (CX >= 0) and (CX < 8) and (CY >= 0) and (CY < 8) and
         (Board[CX, CY] = PlayerPiece) then
        Total := Total + Count;
    end;

  Result := Total;
end;

function TReversiAI.EvaluateMove(Game: TReversiGame; X, Y: Integer; Player: TPlayer): Integer;
var
  FlippedCount: Integer;
  PositionValue: Integer;
begin
  Result := 0;

  // 反転できる石の数
  FlippedCount := CountFlippedPieces(Game, X, Y, Player);
  Result := Result + FlippedCount * 10;

  // 位置の価値
  PositionValue := GetPositionValue(X, Y);
  Result := Result + PositionValue;

  // 難易度に応じた評価の調整
  case FDifficulty of
    aiEasy:
      // 簡単：ランダム要素を追加（評価を少しランダム化）
      Result := Result + Random(20) - 10;
    aiMedium:
      // 中級：位置と反転数のバランス
      Result := Result;
    aiHard:
      // 上級：より多くの反転数を重視
      Result := Result + FlippedCount * 5;
  end;
end;

function TReversiAI.GetBestMove(Game: TReversiGame; Player: TPlayer; var BestX, BestY: Integer): Boolean;
var
  ValidMoves: TList;
  I: Integer;
  Pos: ^TPosition;
  BestScore, Score: Integer;
  Found: Boolean;
  X, Y: Integer;
begin
  Result := False;
  BestScore := Low(Integer);
  Found := False;
  ValidMoves := Game.GetValidMoves(Player);

  try
    if ValidMoves.Count = 0 then
      Exit;

    // すべての合法手を評価
    for I := 0 to ValidMoves.Count - 1 do
    begin
      Pos := ValidMoves[I];
      X := Pos^.X;
      Y := Pos^.Y;

      Score := EvaluateMove(Game, X, Y, Player);

      // より良い手を見つけた場合、または最初の手の場合
      if (not Found) or (Score > BestScore) or
         ((Score = BestScore) and (Random(2) = 0)) then
      begin
        BestScore := Score;
        BestX := X;
        BestY := Y;
        Found := True;
      end;
    end;

    Result := Found;
  finally
    // メモリを解放
    for I := 0 to ValidMoves.Count - 1 do
    begin
      Pos := ValidMoves[I];
      Dispose(Pos);
    end;
    ValidMoves.Free;
  end;
end;

function TReversiAI.GetMove(Game: TReversiGame; Player: TPlayer; var X, Y: Integer): Boolean;
begin
  Result := GetBestMove(Game, Player, X, Y);
end;

procedure TReversiAI.SetDifficulty(Difficulty: TAIDifficulty);
begin
  FDifficulty := Difficulty;
end;

function TReversiAI.GetDifficulty: TAIDifficulty;
begin
  Result := FDifficulty;
end;

end.

