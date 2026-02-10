program quantum_shogi;

uses
  SysUtils, Classes, Web, JS, Math, quantum_shogi_logic;

type
  TGame = class(TGameLogic)
  public
    CurrentPlayer: Integer;
    SelectedX, SelectedY: Integer;
    SelectedStandIndex: Integer;
    GameOver: Boolean;
    ValidMoves: array[1..9, 1..9] of Boolean;

    constructor Create;
    procedure HandleCellClick(ax, ay: Integer);
    procedure HandleStandClick(PlayerIdx, PieceIdx: Integer);
    procedure MovePiece(fx, fy, tx, ty: Integer);
    procedure DropPiece(PieceIdx, tx, ty: Integer);
    function CanMove(pt: TPieceType; dx, dy, Owner: Integer): Boolean;
    procedure ComputeValidMoves(fx, fy: Integer);
    procedure UpdateUI;
    procedure RenderPieceTo(container: TJSHTMLElement; p: TQuantumPiece);
    procedure CheckVictory;
  end;

var
  Game: TGame;

function OnStandClick(e: TJSMouseEvent): boolean; forward;
procedure RunGroupTwoPieceTest; forward;
function RunGroupTwoPieceTestClick(e: TJSMouseEvent): boolean; forward;

constructor TGame.Create;
begin
  inherited Create;
  CurrentPlayer := 0;
  SelectedX := -1;
  SelectedY := -1;
  SelectedStandIndex := -1;
  GameOver := False;
end;

function TGame.CanMove(pt: TPieceType; dx, dy, Owner: Integer): Boolean;
var absX, absY: Integer;
begin
  if Owner = 1 then begin dy := -dy; dx := -dx; end;
  absX := Abs(dx); absY := Abs(dy);
  case pt of
    ptPawn:   Result := (dx = 0) and (dy = -1);
    ptLance:  Result := (dx = 0) and (dy < 0);
    ptKnight: Result := (absX = 1) and (absY = 2) and (dy = -2);
    ptSilver: Result := (absX <= 1) and (absY <= 1) and not ((dx=0) and (dy=0)) and ( (dy = -1) or ((dy = 1) and (absX = 1)) );
    ptKing:   Result := (absX <= 1) and (absY <= 1) and not ((dx=0) and (dy=0));
    ptRook:   Result := (dx = 0) or (dy = 0);
    ptBishop: Result := (absX = absY);
    ptGold:   Result := (absX <= 1) and (dy >= -1) and (dy <= 1) and not ((dy=1) and (absX=1));
  end;
end;

procedure TGame.ComputeValidMoves(fx, fy: Integer);
var
  p: TQuantumPiece;
  tx, ty: Integer;
  newSet: TPieceSet;
  pt: TPieceType;
begin
  p := Board[fx, fy];
  for ty := 1 to 9 do
    for tx := 1 to 9 do begin
      if (tx = fx) and (ty = fy) then ValidMoves[tx, ty] := False
      else if (Board[tx, ty] <> nil) and (Board[tx, ty].Owner = p.Owner) then ValidMoves[tx, ty] := False
      else begin
        newSet := [];
        for pt in p.Possibilities do if CanMove(pt, tx - fx, ty - fy, p.Owner) then Include(newSet, pt);
        ValidMoves[tx, ty] := (newSet <> []) and not WouldExceedTypeCount(p.Owner, p, newSet)
          and not IsMovePathBlocked(fx, fy, tx, ty, newSet);
      end;
    end;
end;

procedure TGame.RenderPieceTo(container: TJSHTMLElement; p: TQuantumPiece);
var
  pt: TPieceType;
  Count: Integer;
  PieceChar: string;
  Span: TJSHTMLElement;
begin
  Count := 0;
  for pt in p.Possibilities do Inc(Count);
  for pt in p.Possibilities do begin
    case pt of
      ptPawn: PieceChar := '歩'; ptLance: PieceChar := '香';
      ptKnight: PieceChar := '桂'; ptSilver: PieceChar := '銀';
      ptGold: PieceChar := '金'; ptBishop: PieceChar := '角';
      ptRook: PieceChar := '飛'; ptKing: PieceChar := '王';
    end;
    Span := TJSHTMLElement(document.createElement('span'));
    Span.className := 'quantum-char';
    Span.innerText := PieceChar;
    Span.style.setProperty('opacity', FloatToStr(1.0 / Count));
    if p.Owner = 1 then Span.style.setProperty('transform', 'translate(-50%, -50%) rotate(180deg)')
    else Span.style.setProperty('transform', 'translate(-50%, -50%)');
    container.appendChild(Span);
  end;
end;

procedure TGame.UpdateUI;
var
  x, y, s, i: Integer;
  Cell, Container, StandEl: TJSHTMLElement;
  p: TQuantumPiece;
begin
  if (SelectedX <> -1) and (SelectedY <> -1) and (Board[SelectedX, SelectedY] <> nil) then
    ComputeValidMoves(SelectedX, SelectedY)
  else
    for y := 1 to 9 do for x := 1 to 9 do ValidMoves[x, y] := False;
  for y := 1 to 9 do
    for x := 1 to 9 do begin
      Cell := TJSHTMLElement(document.getElementById('cell-'+IntToStr(x)+'-'+IntToStr(y)));
      Container := TJSHTMLElement(Cell.querySelector('.piece-container'));
      Container.innerHTML := '';
      if (SelectedX=x) and (SelectedY=y) then Cell.classList.add('selected') else Cell.classList.remove('selected');
      if (SelectedX <> -1) and (SelectedY <> -1) and ValidMoves[x, y] then Cell.classList.add('move-dest')
      else Cell.classList.remove('move-dest');
      if Board[x, y] <> nil then RenderPieceTo(Container, Board[x, y]);
    end;

  for s := 0 to 1 do begin
    StandEl := TJSHTMLElement(document.getElementById('stand-'+IntToStr(s)));
    StandEl.innerHTML := '';
    for i := 0 to Stands[s].Count - 1 do begin
      p := TQuantumPiece(Stands[s].Items[i]);
      Container := TJSHTMLElement(document.createElement('div'));
      Container.className := 'cell';
      if (s = CurrentPlayer) and (SelectedStandIndex = i) then Container.classList.add('selected');
      Container.dataset['idx'] := IntToStr(i);
      Container.dataset['owner'] := IntToStr(s);
      Container.onclick := @OnStandClick;
      RenderPieceTo(Container, p);
      StandEl.appendChild(Container);
    end;
  end;

  if CurrentPlayer = 0 then document.getElementById('status').innerText := '手番: 先手'
  else document.getElementById('status').innerText := '手番: 後手';
end;

procedure TGame.MovePiece(fx, fy, tx, ty: Integer);
var
  p: TQuantumPiece;
  newSet: TPieceSet;
  pt: TPieceType;
begin
  p := Board[fx, fy];
  newSet := [];
  for pt in p.Possibilities do if CanMove(pt, tx-fx, ty-fy, p.Owner) then Include(newSet, pt);
  if newSet = [] then Exit;
  if WouldExceedTypeCount(p.Owner, p, newSet) then Exit;
  if IsMovePathBlocked(fx, fy, tx, ty, newSet) then Exit;
  p.Possibilities := newSet;
  for pt in newSet do if newSet = [pt] then begin
    if CountPiecesWithTypeInGroup(p.InitialGroup, pt) >= InitialCountPerGroup(pt) then
      RemovePossibilityFromGroup(p.InitialGroup, pt, p);
    Break;
  end;
  if Board[tx, ty] <> nil then begin
    Board[tx, ty].Owner := p.Owner;
    Stands[p.Owner].Add(Board[tx, ty]);
  end;
  Board[tx, ty] := p; Board[fx, fy] := nil;
  CurrentPlayer := 1 - CurrentPlayer;
  UpdateUI;
end;

procedure TGame.DropPiece(PieceIdx, tx, ty: Integer);
var
  p: TQuantumPiece;
  newSet: TPieceSet;
  pt: TPieceType;
begin
  if Board[tx, ty] <> nil then Exit;
  p := TQuantumPiece(Stands[CurrentPlayer].Items[PieceIdx]);
  newSet := p.Possibilities;
  if (CurrentPlayer = 0) and (ty = 1) then newSet := newSet - [ptPawn, ptLance];
  if (CurrentPlayer = 1) and (ty = 9) then newSet := newSet - [ptPawn, ptLance];
  if newSet = [] then Exit;
  if WouldExceedTypeCount(CurrentPlayer, p, newSet) then Exit;
  p.Possibilities := newSet;
  for pt in newSet do if newSet = [pt] then begin
    if CountPiecesWithTypeInGroup(p.InitialGroup, pt) >= InitialCountPerGroup(pt) then
      RemovePossibilityFromGroup(p.InitialGroup, pt, p);
    Break;
  end;
  Board[tx, ty] := p;
  Stands[CurrentPlayer].Delete(PieceIdx);
  CurrentPlayer := 1 - CurrentPlayer;
  UpdateUI;
end;

procedure TGame.HandleCellClick(ax, ay: Integer);
begin
  if SelectedStandIndex <> -1 then begin
    if Board[ax, ay] = nil then begin DropPiece(SelectedStandIndex, ax, ay); SelectedStandIndex := -1; end;
    Exit;
  end;
  if SelectedX = -1 then begin
    if (Board[ax, ay] <> nil) and (Board[ax, ay].Owner = CurrentPlayer) then begin
      SelectedX := ax; SelectedY := ay; UpdateUI;
    end;
    Exit;
  end;
  if (SelectedX = ax) and (SelectedY = ay) then begin SelectedX := -1; SelectedY := -1; UpdateUI; Exit; end;
  if ValidMoves[ax, ay] then begin MovePiece(SelectedX, SelectedY, ax, ay); SelectedX := -1; SelectedY := -1; Exit; end;
  if (Board[ax, ay] <> nil) and (Board[ax, ay].Owner = CurrentPlayer) then begin SelectedX := ax; SelectedY := ay; UpdateUI; end;
end;

procedure TGame.HandleStandClick(PlayerIdx, PieceIdx: Integer);
begin
  if PlayerIdx <> CurrentPlayer then Exit;
  SelectedStandIndex := PieceIdx;
  SelectedX := -1;
  UpdateUI;
end;

procedure TGame.CheckVictory;
begin
  { 勝敗判定は未実装 }
end;

function OnCellClick(e: TJSMouseEvent): boolean;
begin
  Game.HandleCellClick(StrToInt(TJSHTMLElement(e.currentTarget).dataset['x']),
                       StrToInt(TJSHTMLElement(e.currentTarget).dataset['y']));
  Result := true;
end;

function OnStandClick(e: TJSMouseEvent): boolean;
begin
  Game.HandleStandClick(StrToInt(TJSHTMLElement(e.currentTarget).dataset['owner']),
                        StrToInt(TJSHTMLElement(e.currentTarget).dataset['idx']));
  Result := true;
end;

procedure RunGroupTwoPieceTest;
var
  TestGame: TGame;
  p1, p2, p3: TQuantumPiece;
  x, y: Integer;
  cnt: Integer;
  ok: Boolean;
  msg: string;
begin
  TestGame := TGame.Create;
  for y := 1 to 9 do for x := 1 to 9 do TestGame.Board[x, y] := nil;
  TestGame.Stands[0].Clear;
  TestGame.Stands[1].Clear;
  p1 := TQuantumPiece.Create(0, 0);
  p1.Possibilities := [ptLance];
  p2 := TQuantumPiece.Create(0, 0);
  p2.Possibilities := [ptLance, ptRook];
  p3 := TQuantumPiece.Create(0, 0);
  p3.Possibilities := [ptLance, ptKnight];
  TestGame.Board[1, 5] := p1;
  TestGame.Board[2, 5] := p2;
  TestGame.Board[3, 5] := p3;
  cnt := TestGame.CountPiecesWithTypeInGroup(0, ptLance);
  if cnt <> 1 then begin
    msg := 'FAIL: 1枚目のみ香確定のとき CountPiecesWithTypeInGroup(0,ptLance)=' + IntToStr(cnt) + ' (expected 1)';
    document.getElementById('status').innerText := msg;
    Exit;
  end;
  p2.Possibilities := [ptLance];
  cnt := TestGame.CountPiecesWithTypeInGroup(0, ptLance);
  if cnt < TestGame.InitialCountPerGroup(ptLance) then begin
    msg := 'FAIL: 2枚目確定後 Count=' + IntToStr(cnt);
    document.getElementById('status').innerText := msg;
    Exit;
  end;
  TestGame.RemovePossibilityFromGroup(0, ptLance, p2);
  ok := (p1.Possibilities = [ptLance]) and (p2.Possibilities = [ptLance]) and (p3.Possibilities = [ptKnight]);
  if ok then
    msg := 'PASS: 香グループ内2枚テスト — 1枚目・2枚目は香のまま、3枚目から香の可能性が削除されている'
  else
    msg := 'FAIL: p1=' + IntToStr(Ord(ptLance)) + ' p2=' + IntToStr(Ord(ptLance)) + ' p3(expect no lance)';
  document.getElementById('status').innerText := msg;
end;

function RunGroupTwoPieceTestClick(e: TJSMouseEvent): boolean;
begin
  RunGroupTwoPieceTest;
  Result := true;
end;

var
  ix, iy: Integer;
  BoardEl, CellEl, ContEl, BtnEl: TJSHTMLElement;
begin
  Game := TGame.Create;
  BoardEl := TJSHTMLElement(document.getElementById('board'));
  for iy := 1 to 9 do
    for ix := 1 to 9 do begin
      CellEl := TJSHTMLElement(document.createElement('div'));
      CellEl.className := 'cell';
      CellEl.id := 'cell-'+IntToStr(ix)+'-'+IntToStr(iy);
      ContEl := TJSHTMLElement(document.createElement('div'));
      ContEl.className := 'piece-container';
      CellEl.appendChild(ContEl);
      CellEl.dataset['x'] := IntToStr(ix);
      CellEl.dataset['y'] := IntToStr(iy);
      CellEl.onclick := @OnCellClick;
      BoardEl.appendChild(CellEl);
    end;
  Game.UpdateUI;
  BtnEl := TJSHTMLElement(document.createElement('button'));
  BtnEl.id := 'test-btn';
  BtnEl.innerText := '香・桂・金・銀 2枚テスト';
  BtnEl.onclick := @RunGroupTwoPieceTestClick;
  document.body.appendChild(BtnEl);
end.
