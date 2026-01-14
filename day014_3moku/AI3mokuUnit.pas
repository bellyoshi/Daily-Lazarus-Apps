unit AI3mokuUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Game3mokuUnit;

type
  { TLevel1AI }

  TLevel1AI = class
  public
    constructor Create;
    function GetMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
  end;

  { TLevel2AI }

  TLevel2AI = class
  public
    constructor Create;
    function GetMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
  private
    function FindBlockingMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
    function CheckTwoInARow(Game: TGame3moku; Opponent: TPlayer; out BlockRow, BlockCol: Integer): Boolean;
  end;

  { TLevel3AI }

  TLevel3AI = class
  public
    constructor Create;
    function GetMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
  private
    function FindWinningMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
    function FindBlockingMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
    function CheckTwoInARow(Game: TGame3moku; Player: TPlayer; out WinRow, WinCol: Integer): Boolean;
  end;

implementation

{ TLevel1AI }

constructor TLevel1AI.Create;
begin
  Randomize; // 乱数生成器を初期化
end;

function TLevel1AI.GetMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
var
  ValidMoves: array of record
    Row, Col: Integer;
  end;
  i, j, Count, Index: Integer;
begin
  Result := False;
  Row := -1;
  Col := -1;

  if not Assigned(Game) then
    Exit;

  // ゲームが終了している場合は合法手なし
  if Game.GetGameState <> gsPlaying then
    Exit;

  // 合法手を収集
  SetLength(ValidMoves, 9);
  Count := 0;
  for i := 0 to 2 do
    for j := 0 to 2 do
      if Game.IsValidMove(i, j) then
      begin
        ValidMoves[Count].Row := i;
        ValidMoves[Count].Col := j;
        Inc(Count);
      end;

  // 合法手がない場合はFalseを返す
  if Count = 0 then
    Exit;

  // ランダムに1つ選択
  Index := Random(Count);
  Row := ValidMoves[Index].Row;
  Col := ValidMoves[Index].Col;
  Result := True;
end;

{ TLevel2AI }

constructor TLevel2AI.Create;
begin
  Randomize; // 乱数生成器を初期化
end;

function TLevel2AI.GetMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
var
  ValidMoves: array of record
    Row, Col: Integer;
  end;
  i, j, Count, Index: Integer;
  Opponent: TPlayer;
begin
  Result := False;
  Row := -1;
  Col := -1;

  if not Assigned(Game) then
    Exit;

  // ゲームが終了している場合は合法手なし
  if Game.GetGameState <> gsPlaying then
    Exit;

  // 相手のプレイヤーを決定
  if Game.GetCurrentPlayer = pX then
    Opponent := pO
  else
    Opponent := pX;

  // まず、妨害が必要かチェック
  if FindBlockingMove(Game, Row, Col) then
  begin
    Result := True;
    Exit;
  end;

  // 妨害が不要な場合、ランダムに選択
  SetLength(ValidMoves, 9);
  Count := 0;
  for i := 0 to 2 do
    for j := 0 to 2 do
      if Game.IsValidMove(i, j) then
      begin
        ValidMoves[Count].Row := i;
        ValidMoves[Count].Col := j;
        Inc(Count);
      end;

  // 合法手がない場合はFalseを返す
  if Count = 0 then
    Exit;

  // ランダムに1つ選択
  Index := Random(Count);
  Row := ValidMoves[Index].Row;
  Col := ValidMoves[Index].Col;
  Result := True;
end;

function TLevel2AI.FindBlockingMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
var
  Opponent: TPlayer;
begin
  Result := False;
  Row := -1;
  Col := -1;

  if not Assigned(Game) then
    Exit;

  // 相手のプレイヤーを決定
  if Game.GetCurrentPlayer = pX then
    Opponent := pO
  else
    Opponent := pX;

  // 相手の2目並びをチェック
  if CheckTwoInARow(Game, Opponent, Row, Col) then
    Result := True;
end;

function TLevel2AI.CheckTwoInARow(Game: TGame3moku; Opponent: TPlayer; out BlockRow, BlockCol: Integer): Boolean;
var
  i: Integer;
  Count: Integer;
  EmptyRow, EmptyCol: Integer;
begin
  Result := False;
  BlockRow := -1;
  BlockCol := -1;

  // 横のチェック
  for i := 0 to 2 do
  begin
    Count := 0;
    EmptyRow := -1;
    EmptyCol := -1;
    if Game.GetCell(i, 0) = Opponent then Inc(Count) else if Game.GetCell(i, 0) = pNone then begin EmptyRow := i; EmptyCol := 0; end;
    if Game.GetCell(i, 1) = Opponent then Inc(Count) else if Game.GetCell(i, 1) = pNone then begin EmptyRow := i; EmptyCol := 1; end;
    if Game.GetCell(i, 2) = Opponent then Inc(Count) else if Game.GetCell(i, 2) = pNone then begin EmptyRow := i; EmptyCol := 2; end;
    
    if (Count = 2) and (EmptyRow >= 0) then
    begin
      BlockRow := EmptyRow;
      BlockCol := EmptyCol;
      Result := True;
      Exit;
    end;
  end;

  // 縦のチェック
  for i := 0 to 2 do
  begin
    Count := 0;
    EmptyRow := -1;
    EmptyCol := -1;
    if Game.GetCell(0, i) = Opponent then Inc(Count) else if Game.GetCell(0, i) = pNone then begin EmptyRow := 0; EmptyCol := i; end;
    if Game.GetCell(1, i) = Opponent then Inc(Count) else if Game.GetCell(1, i) = pNone then begin EmptyRow := 1; EmptyCol := i; end;
    if Game.GetCell(2, i) = Opponent then Inc(Count) else if Game.GetCell(2, i) = pNone then begin EmptyRow := 2; EmptyCol := i; end;
    
    if (Count = 2) and (EmptyRow >= 0) then
    begin
      BlockRow := EmptyRow;
      BlockCol := EmptyCol;
      Result := True;
      Exit;
    end;
  end;

  // 斜めのチェック（左上から右下）
  Count := 0;
  EmptyRow := -1;
  EmptyCol := -1;
  if Game.GetCell(0, 0) = Opponent then Inc(Count) else if Game.GetCell(0, 0) = pNone then begin EmptyRow := 0; EmptyCol := 0; end;
  if Game.GetCell(1, 1) = Opponent then Inc(Count) else if Game.GetCell(1, 1) = pNone then begin EmptyRow := 1; EmptyCol := 1; end;
  if Game.GetCell(2, 2) = Opponent then Inc(Count) else if Game.GetCell(2, 2) = pNone then begin EmptyRow := 2; EmptyCol := 2; end;
  
  if (Count = 2) and (EmptyRow >= 0) then
  begin
    BlockRow := EmptyRow;
    BlockCol := EmptyCol;
    Result := True;
    Exit;
  end;

  // 斜めのチェック（右上から左下）
  Count := 0;
  EmptyRow := -1;
  EmptyCol := -1;
  if Game.GetCell(0, 2) = Opponent then Inc(Count) else if Game.GetCell(0, 2) = pNone then begin EmptyRow := 0; EmptyCol := 2; end;
  if Game.GetCell(1, 1) = Opponent then Inc(Count) else if Game.GetCell(1, 1) = pNone then begin EmptyRow := 1; EmptyCol := 1; end;
  if Game.GetCell(2, 0) = Opponent then Inc(Count) else if Game.GetCell(2, 0) = pNone then begin EmptyRow := 2; EmptyCol := 0; end;
  
  if (Count = 2) and (EmptyRow >= 0) then
  begin
    BlockRow := EmptyRow;
    BlockCol := EmptyCol;
    Result := True;
    Exit;
  end;
end;

{ TLevel3AI }

constructor TLevel3AI.Create;
begin
  Randomize; // 乱数生成器を初期化
end;

function TLevel3AI.GetMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
var
  ValidMoves: array of record
    Row, Col: Integer;
  end;
  i, j, Count, Index: Integer;
begin
  Result := False;
  Row := -1;
  Col := -1;

  if not Assigned(Game) then
    Exit;

  // ゲームが終了している場合は合法手なし
  if Game.GetGameState <> gsPlaying then
    Exit;

  // まず、勝利を確定できる手を探す
  if FindWinningMove(Game, Row, Col) then
  begin
    Result := True;
    Exit;
  end;

  // 勝利を確定できない場合、妨害が必要かチェック
  if FindBlockingMove(Game, Row, Col) then
  begin
    Result := True;
    Exit;
  end;

  // 妨害も不要な場合、ランダムに選択
  SetLength(ValidMoves, 9);
  Count := 0;
  for i := 0 to 2 do
    for j := 0 to 2 do
      if Game.IsValidMove(i, j) then
      begin
        ValidMoves[Count].Row := i;
        ValidMoves[Count].Col := j;
        Inc(Count);
      end;

  // 合法手がない場合はFalseを返す
  if Count = 0 then
    Exit;

  // ランダムに1つ選択
  Index := Random(Count);
  Row := ValidMoves[Index].Row;
  Col := ValidMoves[Index].Col;
  Result := True;
end;

function TLevel3AI.FindWinningMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
var
  CurrentPlayer: TPlayer;
begin
  Result := False;
  Row := -1;
  Col := -1;

  if not Assigned(Game) then
    Exit;

  CurrentPlayer := Game.GetCurrentPlayer;

  // 自分の2目並びをチェック
  if CheckTwoInARow(Game, CurrentPlayer, Row, Col) then
    Result := True;
end;

function TLevel3AI.FindBlockingMove(Game: TGame3moku; out Row, Col: Integer): Boolean;
var
  Opponent: TPlayer;
begin
  Result := False;
  Row := -1;
  Col := -1;

  if not Assigned(Game) then
    Exit;

  // 相手のプレイヤーを決定
  if Game.GetCurrentPlayer = pX then
    Opponent := pO
  else
    Opponent := pX;

  // 相手の2目並びをチェック
  if CheckTwoInARow(Game, Opponent, Row, Col) then
    Result := True;
end;

function TLevel3AI.CheckTwoInARow(Game: TGame3moku; Player: TPlayer; out WinRow, WinCol: Integer): Boolean;
var
  i: Integer;
  Count: Integer;
  EmptyRow, EmptyCol: Integer;
begin
  Result := False;
  WinRow := -1;
  WinCol := -1;

  // 横のチェック
  for i := 0 to 2 do
  begin
    Count := 0;
    EmptyRow := -1;
    EmptyCol := -1;
    if Game.GetCell(i, 0) = Player then Inc(Count) else if Game.GetCell(i, 0) = pNone then begin EmptyRow := i; EmptyCol := 0; end;
    if Game.GetCell(i, 1) = Player then Inc(Count) else if Game.GetCell(i, 1) = pNone then begin EmptyRow := i; EmptyCol := 1; end;
    if Game.GetCell(i, 2) = Player then Inc(Count) else if Game.GetCell(i, 2) = pNone then begin EmptyRow := i; EmptyCol := 2; end;
    
    if (Count = 2) and (EmptyRow >= 0) then
    begin
      WinRow := EmptyRow;
      WinCol := EmptyCol;
      Result := True;
      Exit;
    end;
  end;

  // 縦のチェック
  for i := 0 to 2 do
  begin
    Count := 0;
    EmptyRow := -1;
    EmptyCol := -1;
    if Game.GetCell(0, i) = Player then Inc(Count) else if Game.GetCell(0, i) = pNone then begin EmptyRow := 0; EmptyCol := i; end;
    if Game.GetCell(1, i) = Player then Inc(Count) else if Game.GetCell(1, i) = pNone then begin EmptyRow := 1; EmptyCol := i; end;
    if Game.GetCell(2, i) = Player then Inc(Count) else if Game.GetCell(2, i) = pNone then begin EmptyRow := 2; EmptyCol := i; end;
    
    if (Count = 2) and (EmptyRow >= 0) then
    begin
      WinRow := EmptyRow;
      WinCol := EmptyCol;
      Result := True;
      Exit;
    end;
  end;

  // 斜めのチェック（左上から右下）
  Count := 0;
  EmptyRow := -1;
  EmptyCol := -1;
  if Game.GetCell(0, 0) = Player then Inc(Count) else if Game.GetCell(0, 0) = pNone then begin EmptyRow := 0; EmptyCol := 0; end;
  if Game.GetCell(1, 1) = Player then Inc(Count) else if Game.GetCell(1, 1) = pNone then begin EmptyRow := 1; EmptyCol := 1; end;
  if Game.GetCell(2, 2) = Player then Inc(Count) else if Game.GetCell(2, 2) = pNone then begin EmptyRow := 2; EmptyCol := 2; end;
  
  if (Count = 2) and (EmptyRow >= 0) then
  begin
    WinRow := EmptyRow;
    WinCol := EmptyCol;
    Result := True;
    Exit;
  end;

  // 斜めのチェック（右上から左下）
  Count := 0;
  EmptyRow := -1;
  EmptyCol := -1;
  if Game.GetCell(0, 2) = Player then Inc(Count) else if Game.GetCell(0, 2) = pNone then begin EmptyRow := 0; EmptyCol := 2; end;
  if Game.GetCell(1, 1) = Player then Inc(Count) else if Game.GetCell(1, 1) = pNone then begin EmptyRow := 1; EmptyCol := 1; end;
  if Game.GetCell(2, 0) = Player then Inc(Count) else if Game.GetCell(2, 0) = pNone then begin EmptyRow := 2; EmptyCol := 0; end;
  
  if (Count = 2) and (EmptyRow >= 0) then
  begin
    WinRow := EmptyRow;
    WinCol := EmptyCol;
    Result := True;
    Exit;
  end;
end;

end.
