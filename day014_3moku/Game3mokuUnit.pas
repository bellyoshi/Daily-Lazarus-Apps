unit Game3mokuUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TPlayer = (pNone, pX, pO);
  TGameState = (gsPlaying, gsXWon, gsOWon, gsDraw);

  { TGame3moku }

  TGame3moku = class
  private
    FBoard: array[0..2, 0..2] of TPlayer;
    FCurrentPlayer: TPlayer;
    FGameState: TGameState;
    function CheckWin: TGameState;
    function CheckDraw: Boolean;
  public
    constructor Create;
    procedure Reset;
    function MakeMove(Row, Col: Integer): Boolean;
    function GetCell(Row, Col: Integer): TPlayer;
    function GetCurrentPlayer: TPlayer;
    function GetGameState: TGameState;
    function IsValidMove(Row, Col: Integer): Boolean;
  end;

implementation

{ TGame3moku }

constructor TGame3moku.Create;
begin
  Reset;
end;

procedure TGame3moku.Reset;
var
  i, j: Integer;
begin
  for i := 0 to 2 do
    for j := 0 to 2 do
      FBoard[i, j] := pNone;
  FCurrentPlayer := pX;
  FGameState := gsPlaying;
end;

function TGame3moku.MakeMove(Row, Col: Integer): Boolean;
begin
  Result := False;
  if (FGameState <> gsPlaying) or not IsValidMove(Row, Col) then
    Exit;

  FBoard[Row, Col] := FCurrentPlayer;
  FGameState := CheckWin;

  if FGameState = gsPlaying then
  begin
    if CheckDraw then
      FGameState := gsDraw
    else
    begin
      // プレイヤーを切り替え
      if FCurrentPlayer = pX then
        FCurrentPlayer := pO
      else
        FCurrentPlayer := pX;
    end;
  end;

  Result := True;
end;

function TGame3moku.GetCell(Row, Col: Integer): TPlayer;
begin
  if (Row >= 0) and (Row <= 2) and (Col >= 0) and (Col <= 2) then
    Result := FBoard[Row, Col]
  else
    Result := pNone;
end;

function TGame3moku.GetCurrentPlayer: TPlayer;
begin
  Result := FCurrentPlayer;
end;

function TGame3moku.GetGameState: TGameState;
begin
  Result := FGameState;
end;

function TGame3moku.IsValidMove(Row, Col: Integer): Boolean;
begin
  Result := (Row >= 0) and (Row <= 2) and
            (Col >= 0) and (Col <= 2) and
            (FBoard[Row, Col] = pNone);
end;

function TGame3moku.CheckWin: TGameState;
var
  i: Integer;
begin
  Result := gsPlaying;

  // 横のチェック
  for i := 0 to 2 do
  begin
    if (FBoard[i, 0] <> pNone) and
       (FBoard[i, 0] = FBoard[i, 1]) and
       (FBoard[i, 1] = FBoard[i, 2]) then
    begin
      if FBoard[i, 0] = pX then
        Exit(gsXWon)
      else
        Exit(gsOWon);
    end;
  end;

  // 縦のチェック
  for i := 0 to 2 do
  begin
    if (FBoard[0, i] <> pNone) and
       (FBoard[0, i] = FBoard[1, i]) and
       (FBoard[1, i] = FBoard[2, i]) then
    begin
      if FBoard[0, i] = pX then
        Exit(gsXWon)
      else
        Exit(gsOWon);
    end;
  end;

  // 斜めのチェック（左上から右下）
  if (FBoard[0, 0] <> pNone) and
     (FBoard[0, 0] = FBoard[1, 1]) and
     (FBoard[1, 1] = FBoard[2, 2]) then
  begin
    if FBoard[0, 0] = pX then
      Exit(gsXWon)
    else
      Exit(gsOWon);
  end;

  // 斜めのチェック（右上から左下）
  if (FBoard[0, 2] <> pNone) and
     (FBoard[0, 2] = FBoard[1, 1]) and
     (FBoard[1, 1] = FBoard[2, 0]) then
  begin
    if FBoard[0, 2] = pX then
      Exit(gsXWon)
    else
      Exit(gsOWon);
  end;
end;

function TGame3moku.CheckDraw: Boolean;
var
  i, j: Integer;
begin
  Result := True;
  for i := 0 to 2 do
    for j := 0 to 2 do
      if FBoard[i, j] = pNone then
      begin
        Result := False;
        Exit;
      end;
end;

end.
