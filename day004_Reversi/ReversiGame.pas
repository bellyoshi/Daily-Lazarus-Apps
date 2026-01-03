unit ReversiGame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TPiece = (pNone, pBlack, pWhite);
  TPlayer = (plBlack, plWhite);
  TBoard = array[0..7, 0..7] of TPiece;
  TPosition = record
    X, Y: Integer;
  end;

  { TReversiGame }

  TReversiGame = class
  private
    FBoard: TBoard;
    FCurrentPlayer: TPlayer;
    FGameOver: Boolean;
    FBlackCount: Integer;
    FWhiteCount: Integer;
    function IsValidMove(X, Y: Integer; Player: TPlayer): Boolean;
    function GetOpponent(Player: TPlayer): TPlayer;
    function GetPiece(Player: TPlayer): TPiece;
    function FlipPieces(X, Y: Integer; Player: TPlayer): Boolean;
    function CheckDirection(X, Y, DX, DY: Integer; Player: TPlayer): Integer;
    procedure CountPieces;
    function HasValidMove(Player: TPlayer): Boolean;
  public
    constructor Create;
    procedure Initialize;
    function PlacePiece(X, Y: Integer): Boolean;
    function GetBoard: TBoard;
    function GetCurrentPlayer: TPlayer;
    function IsGameOver: Boolean;
    function GetBlackCount: Integer;
    function GetWhiteCount: Integer;
    function GetWinner: TPlayer;
    function GetValidMoves(Player: TPlayer): TList;
    procedure PassTurn;
    function CanPlacePiece(X, Y: Integer): Boolean;
  end;

implementation

{ TReversiGame }

constructor TReversiGame.Create;
begin
  Initialize;
end;

procedure TReversiGame.Initialize;
var
  X, Y: Integer;
begin
  // ボードを初期化
  for Y := 0 to 7 do
    for X := 0 to 7 do
      FBoard[X, Y] := pNone;

  // 中央に初期配置
  FBoard[3, 3] := pWhite;
  FBoard[4, 4] := pWhite;
  FBoard[3, 4] := pBlack;
  FBoard[4, 3] := pBlack;

  FCurrentPlayer := plBlack;
  FGameOver := False;
  CountPieces;
end;

function TReversiGame.GetOpponent(Player: TPlayer): TPlayer;
begin
  if Player = plBlack then
    Result := plWhite
  else
    Result := plBlack;
end;

function TReversiGame.GetPiece(Player: TPlayer): TPiece;
begin
  if Player = plBlack then
    Result := pBlack
  else
    Result := pWhite;
end;

function TReversiGame.CheckDirection(X, Y, DX, DY: Integer; Player: TPlayer): Integer;
var
  Opponent: TPlayer;
  OpponentPiece, PlayerPiece: TPiece;
  Count: Integer;
  CX, CY: Integer;
begin
  Result := 0;
  Opponent := GetOpponent(Player);
  OpponentPiece := GetPiece(Opponent);
  PlayerPiece := GetPiece(Player);

  CX := X + DX;
  CY := Y + DY;
  Count := 0;

  // 相手の石を数える
  while (CX >= 0) and (CX < 8) and (CY >= 0) and (CY < 8) and
        (FBoard[CX, CY] = OpponentPiece) do
  begin
    Inc(Count);
    CX := CX + DX;
    CY := CY + DY;
  end;

  // 最後に自分の石があるか確認
  if (Count > 0) and (CX >= 0) and (CX < 8) and (CY >= 0) and (CY < 8) and
     (FBoard[CX, CY] = PlayerPiece) then
    Result := Count;
end;

function TReversiGame.IsValidMove(X, Y: Integer; Player: TPlayer): Boolean;
var
  DX, DY: Integer;
begin
  Result := False;

  // 範囲チェック
  if (X < 0) or (X > 7) or (Y < 0) or (Y > 7) then
    Exit;

  // 既に石がある場合は無効
  if FBoard[X, Y] <> pNone then
    Exit;

  // 8方向をチェック
  for DX := -1 to 1 do
    for DY := -1 to 1 do
    begin
      if (DX = 0) and (DY = 0) then
        Continue;
      if CheckDirection(X, Y, DX, DY, Player) > 0 then
      begin
        Result := True;
        Exit;
      end;
    end;
end;

function TReversiGame.FlipPieces(X, Y: Integer; Player: TPlayer): Boolean;
var
  DX, DY: Integer;
  Count: Integer;
  CX, CY: Integer;
  OpponentPiece, PlayerPiece: TPiece;
begin
  Result := False;
  PlayerPiece := GetPiece(Player);
  OpponentPiece := GetPiece(GetOpponent(Player));

  // 石を置く
  FBoard[X, Y] := PlayerPiece;

  // 8方向の石を反転
  for DX := -1 to 1 do
    for DY := -1 to 1 do
    begin
      if (DX = 0) and (DY = 0) then
        Continue;

      Count := CheckDirection(X, Y, DX, DY, Player);
      if Count > 0 then
      begin
        CX := X + DX;
        CY := Y + DY;
        while (FBoard[CX, CY] = OpponentPiece) do
        begin
          FBoard[CX, CY] := PlayerPiece;
          CX := CX + DX;
          CY := CY + DY;
        end;
        Result := True;
      end;
    end;
end;

function TReversiGame.PlacePiece(X, Y: Integer): Boolean;
begin
  Result := False;

  if FGameOver then
    Exit;

  if not IsValidMove(X, Y, FCurrentPlayer) then
    Exit;

  if FlipPieces(X, Y, FCurrentPlayer) then
  begin
    CountPieces;

    // 次のプレイヤーに交代
    FCurrentPlayer := GetOpponent(FCurrentPlayer);

    // 次のプレイヤーが合法手を持たない場合、パス
    if not HasValidMove(FCurrentPlayer) then
    begin
      FCurrentPlayer := GetOpponent(FCurrentPlayer);
      // 両方のプレイヤーが合法手を持たない場合、ゲーム終了
      if not HasValidMove(FCurrentPlayer) then
        FGameOver := True;
    end;

    Result := True;
  end;
end;

function TReversiGame.GetBoard: TBoard;
begin
  Result := FBoard;
end;

function TReversiGame.GetCurrentPlayer: TPlayer;
begin
  Result := FCurrentPlayer;
end;

function TReversiGame.IsGameOver: Boolean;
begin
  Result := FGameOver;
end;

procedure TReversiGame.CountPieces;
var
  X, Y: Integer;
begin
  FBlackCount := 0;
  FWhiteCount := 0;

  for Y := 0 to 7 do
    for X := 0 to 7 do
    begin
      if FBoard[X, Y] = pBlack then
        Inc(FBlackCount)
      else if FBoard[X, Y] = pWhite then
        Inc(FWhiteCount);
    end;
end;

function TReversiGame.GetBlackCount: Integer;
begin
  Result := FBlackCount;
end;

function TReversiGame.GetWhiteCount: Integer;
begin
  Result := FWhiteCount;
end;

function TReversiGame.GetWinner: TPlayer;
begin
  if FBlackCount > FWhiteCount then
    Result := plBlack
  else if FWhiteCount > FBlackCount then
    Result := plWhite
  else
    Result := plBlack; // 引き分けの場合は黒を返す（実装によって変更可能）
end;

function TReversiGame.HasValidMove(Player: TPlayer): Boolean;
var
  X, Y: Integer;
begin
  Result := False;
  for Y := 0 to 7 do
    for X := 0 to 7 do
      if IsValidMove(X, Y, Player) then
      begin
        Result := True;
        Exit;
      end;
end;

function TReversiGame.GetValidMoves(Player: TPlayer): TList;
var
  X, Y: Integer;
  Pos: ^TPosition;
begin
  Result := TList.Create;
  for Y := 0 to 7 do
    for X := 0 to 7 do
      if IsValidMove(X, Y, Player) then
      begin
        New(Pos);
        Pos^.X := X;
        Pos^.Y := Y;
        Result.Add(Pos);
      end;
end;

procedure TReversiGame.PassTurn;
begin
  if not FGameOver then
  begin
    FCurrentPlayer := GetOpponent(FCurrentPlayer);
    if not HasValidMove(FCurrentPlayer) then
      FGameOver := True;
  end;
end;

function TReversiGame.CanPlacePiece(X, Y: Integer): Boolean;
begin
  Result := IsValidMove(X, Y, FCurrentPlayer);
end;

end.

