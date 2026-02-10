unit quantum_shogi_logic;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  TPieceType = (ptPawn, ptLance, ptKnight, ptSilver, ptGold, ptBishop, ptRook, ptKing);
  TPieceSet = set of TPieceType;

  TQuantumPiece = class
  public
    Owner: Integer;
    InitialGroup: Integer;
    Possibilities: TPieceSet;
    IsPromoted: Boolean;
    constructor Create(AOwner: Integer; AInitialGroup: Integer);
  end;

  TGameLogic = class
  public
    Board: array[1..9, 1..9] of TQuantumPiece;
    Stands: array[0..1] of TList;
    constructor Create;
    procedure InitBoard;
    function InitialCountPerGroup(pt: TPieceType): Integer;
    function CountPiecesWithTypeInGroup(AGroupId: Integer; pt: TPieceType): Integer;
    function WouldExceedTypeCount(AOwner: Integer; p: TQuantumPiece; newSet: TPieceSet): Boolean;
    procedure RemovePossibilityFromGroup(AGroupId: Integer; pt: TPieceType; excludePiece: TQuantumPiece);
    { 飛・角・香は経路上に駒があると動けない。桂馬は飛び越え可。 }
    function IsPathClear(fx, fy, tx, ty: Integer): Boolean;
    function IsMovePathBlocked(fx, fy, tx, ty: Integer; newSet: TPieceSet): Boolean;
  end;

implementation

constructor TQuantumPiece.Create(AOwner: Integer; AInitialGroup: Integer);
begin
  inherited Create;
  Owner := AOwner;
  InitialGroup := AInitialGroup;
  Possibilities := [ptPawn, ptLance, ptKnight, ptSilver, ptGold, ptBishop, ptRook, ptKing];
  IsPromoted := False;
end;

constructor TGameLogic.Create;
var
  x, y: Integer;
begin
  inherited Create;
  Stands[0] := TList.Create;
  Stands[1] := TList.Create;
  for y := 1 to 9 do for x := 1 to 9 do Board[x, y] := nil;
  InitBoard;
end;

procedure TGameLogic.InitBoard;
var
  x, y: Integer;
begin
  for y := 1 to 9 do for x := 1 to 9 do Board[x, y] := nil;
  { グループA（初期先手）: 19枚を量子状態で標準初期配置 }
  Board[1, 9] := TQuantumPiece.Create(0, 0);
  Board[2, 9] := TQuantumPiece.Create(0, 0);
  Board[3, 9] := TQuantumPiece.Create(0, 0);
  Board[4, 9] := TQuantumPiece.Create(0, 0);
  Board[5, 9] := TQuantumPiece.Create(0, 0);
  Board[6, 9] := TQuantumPiece.Create(0, 0);
  Board[7, 9] := TQuantumPiece.Create(0, 0);
  Board[8, 9] := TQuantumPiece.Create(0, 0);
  Board[9, 9] := TQuantumPiece.Create(0, 0);
  Board[2, 8] := TQuantumPiece.Create(0, 0);
  Board[8, 8] := TQuantumPiece.Create(0, 0);
  for x := 1 to 9 do Board[x, 7] := TQuantumPiece.Create(0, 0);
  { グループB（初期後手）: 19枚を量子状態で }
  Board[1, 1] := TQuantumPiece.Create(1, 1);
  Board[2, 1] := TQuantumPiece.Create(1, 1);
  Board[3, 1] := TQuantumPiece.Create(1, 1);
  Board[4, 1] := TQuantumPiece.Create(1, 1);
  Board[5, 1] := TQuantumPiece.Create(1, 1);
  Board[6, 1] := TQuantumPiece.Create(1, 1);
  Board[7, 1] := TQuantumPiece.Create(1, 1);
  Board[8, 1] := TQuantumPiece.Create(1, 1);
  Board[9, 1] := TQuantumPiece.Create(1, 1);
  Board[2, 2] := TQuantumPiece.Create(1, 1);
  Board[8, 2] := TQuantumPiece.Create(1, 1);
  for x := 1 to 9 do Board[x, 3] := TQuantumPiece.Create(1, 1);
end;

function TGameLogic.InitialCountPerGroup(pt: TPieceType): Integer;
begin
  case pt of
    ptPawn: Result := 9;
    ptLance: Result := 2;
    ptKnight: Result := 2;
    ptSilver: Result := 2;
    ptGold: Result := 2;
    ptBishop: Result := 1;
    ptRook: Result := 1;
    ptKing: Result := 1;
  end;
end;

function TGameLogic.CountPiecesWithTypeInGroup(AGroupId: Integer; pt: TPieceType): Integer;
var
  x, y, s, i: Integer;
  p: TQuantumPiece;
begin
  Result := 0;
  for y := 1 to 9 do
    for x := 1 to 9 do
      if (Board[x, y] <> nil) and (Board[x, y].InitialGroup = AGroupId) and (Board[x, y].Possibilities = [pt]) then
        Inc(Result);
  for s := 0 to 1 do
    for i := 0 to Stands[s].Count - 1 do
    begin
      p := TQuantumPiece(Stands[s].Items[i]);
      if (p.InitialGroup = AGroupId) and (p.Possibilities = [pt]) then
        Inc(Result);
    end;
end;

function TGameLogic.WouldExceedTypeCount(AOwner: Integer; p: TQuantumPiece; newSet: TPieceSet): Boolean;
var
  pt: TPieceType;
  cnt: Integer;
begin
  Result := False;
  for pt in newSet do
  begin
    if newSet <> [pt] then Continue;
    cnt := CountPiecesWithTypeInGroup(p.InitialGroup, pt);
    if p.Possibilities <> [pt] then Inc(cnt);
    if cnt > InitialCountPerGroup(pt) then
    begin
      Result := True;
      Exit;
    end;
    Exit;
  end;
end;

procedure TGameLogic.RemovePossibilityFromGroup(AGroupId: Integer; pt: TPieceType; excludePiece: TQuantumPiece);
var
  x, y, s, i: Integer;
  q: TQuantumPiece;
begin
  { 確定済み（Possibilities = [pt]）の駒は触れない。未確定でptを含む駒からだけ削除 }
  for y := 1 to 9 do
    for x := 1 to 9 do
      if (Board[x, y] <> nil) and (Board[x, y].InitialGroup = AGroupId) and (Board[x, y] <> excludePiece) then
      begin
        q := Board[x, y];
        if (pt in q.Possibilities) and (q.Possibilities <> [pt]) then q.Possibilities := q.Possibilities - [pt];
      end;
  for s := 0 to 1 do
    for i := 0 to Stands[s].Count - 1 do
    begin
      q := TQuantumPiece(Stands[s].Items[i]);
      if (q.InitialGroup = AGroupId) and (q <> excludePiece) and (pt in q.Possibilities) and (q.Possibilities <> [pt]) then
        q.Possibilities := q.Possibilities - [pt];
    end;
end;

function TGameLogic.IsPathClear(fx, fy, tx, ty: Integer): Boolean;
var
  x, y, dx, dy: Integer;
begin
  Result := True;
  if (fx = tx) and (fy = ty) then Exit;
  if tx > fx then dx := 1 else if tx < fx then dx := -1 else dx := 0;
  if ty > fy then dy := 1 else if ty < fy then dy := -1 else dy := 0;
  x := fx + dx;
  y := fy + dy;
  while (x >= 1) and (x <= 9) and (y >= 1) and (y <= 9) do
  begin
    if (x = tx) and (y = ty) then Exit;
    if Board[x, y] <> nil then begin Result := False; Exit; end;
    x := x + dx;
    y := y + dy;
  end;
end;

{ 飛・角・香は経路が空でないと動けない。桂馬は飛び越え可なので経路チェックしない。 }
function TGameLogic.IsMovePathBlocked(fx, fy, tx, ty: Integer; newSet: TPieceSet): Boolean;
begin
  if (newSet * [ptRook, ptBishop, ptLance]) = [] then
    Result := False
  else
    Result := not IsPathClear(fx, fy, tx, ty);
end;

end.
