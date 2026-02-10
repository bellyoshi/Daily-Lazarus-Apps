unit TestCase1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, quantum_shogi_logic;

type

  TTestGroupTwoPiece = class(TTestCase)
  published
    procedure TestGroupTwoPiece_Lance_FirstPieceStaysWhenSecondCollapses;
    procedure TestGroupTwoPiece_ThirdPieceLosesLancePossibility;
    procedure TestInitialCountPerGroup;
    procedure TestCountPiecesWithTypeInGroup;
    procedure TestWouldExceedTypeCount_RejectsThirdBishopInGroup;
    procedure TestRemovePossibility_DoesNotTouchOtherGroup;
    procedure TestRemovePossibility_DoesNotTouchAlreadyCollapsed;
  end;

  TTestPathBlocking = class(TTestCase)
  published
    procedure TestIsPathClear_BlockedByFriendly;
    procedure TestIsPathClear_BlockedByEnemy;
    procedure TestIsPathClear_BlockedByBishopPath;
    procedure TestIsPathClear_EmptyPath;
    procedure TestIsMovePathBlocked_RookBlockedByPiece;
    procedure TestIsMovePathBlocked_KnightCanJumpOverPiece;
  end;

implementation

procedure TTestGroupTwoPiece.TestGroupTwoPiece_Lance_FirstPieceStaysWhenSecondCollapses;
var
  g: TGameLogic;
  p1, p2, p3: TQuantumPiece;
  x, y: Integer;
  cnt: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Stands[0].Clear;
    g.Stands[1].Clear;
    p1 := TQuantumPiece.Create(0, 0);
    p1.Possibilities := [ptLance];
    p2 := TQuantumPiece.Create(0, 0);
    p2.Possibilities := [ptLance, ptRook];
    p3 := TQuantumPiece.Create(0, 0);
    p3.Possibilities := [ptLance, ptKnight];
    g.Board[1, 5] := p1;
    g.Board[2, 5] := p2;
    g.Board[3, 5] := p3;
    cnt := g.CountPiecesWithTypeInGroup(0, ptLance);
    AssertEquals('1枚目のみ香確定のとき Count=1', 1, cnt);
    p2.Possibilities := [ptLance];
    cnt := g.CountPiecesWithTypeInGroup(0, ptLance);
    AssertTrue('2枚目確定後 Count>=2', cnt >= g.InitialCountPerGroup(ptLance));
    g.RemovePossibilityFromGroup(0, ptLance, p2);
    AssertTrue('1枚目は香のまま', p1.Possibilities = [ptLance]);
    AssertTrue('2枚目は香のまま', p2.Possibilities = [ptLance]);
    AssertTrue('3枚目から香の可能性が削除され桂のみ', p3.Possibilities = [ptKnight]);
  finally
    g.Free;
  end;
end;

procedure TTestGroupTwoPiece.TestGroupTwoPiece_ThirdPieceLosesLancePossibility;
var
  g: TGameLogic;
  p1, p2, p3: TQuantumPiece;
  x, y: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Stands[0].Clear;
    g.Stands[1].Clear;
    p1 := TQuantumPiece.Create(0, 0);
    p1.Possibilities := [ptLance];
    p2 := TQuantumPiece.Create(0, 0);
    p2.Possibilities := [ptLance, ptRook];
    p3 := TQuantumPiece.Create(0, 0);
    p3.Possibilities := [ptLance, ptKnight, ptSilver];
    g.Board[1, 5] := p1;
    g.Board[2, 5] := p2;
    g.Board[3, 5] := p3;
    p2.Possibilities := [ptLance];
    g.RemovePossibilityFromGroup(0, ptLance, p2);
    AssertTrue('3枚目に香が含まれていない', not (ptLance in p3.Possibilities));
    AssertTrue('3枚目は桂か銀の可能性あり', (p3.Possibilities = [ptKnight]) or (ptSilver in p3.Possibilities));
  finally
    g.Free;
  end;
end;

procedure TTestGroupTwoPiece.TestInitialCountPerGroup;
var
  g: TGameLogic;
begin
  g := TGameLogic.Create;
  try
    AssertEquals('角はグループ内1枚', 1, g.InitialCountPerGroup(ptBishop));
    AssertEquals('飛はグループ内1枚', 1, g.InitialCountPerGroup(ptRook));
    AssertEquals('王はグループ内1枚', 1, g.InitialCountPerGroup(ptKing));
    AssertEquals('香はグループ内2枚', 2, g.InitialCountPerGroup(ptLance));
    AssertEquals('桂はグループ内2枚', 2, g.InitialCountPerGroup(ptKnight));
    AssertEquals('金はグループ内2枚', 2, g.InitialCountPerGroup(ptGold));
    AssertEquals('銀はグループ内2枚', 2, g.InitialCountPerGroup(ptSilver));
    AssertEquals('歩はグループ内9枚', 9, g.InitialCountPerGroup(ptPawn));
  finally
    g.Free;
  end;
end;

procedure TTestGroupTwoPiece.TestCountPiecesWithTypeInGroup;
var
  g: TGameLogic;
  p: TQuantumPiece;
  x, y: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Stands[0].Clear;
    g.Stands[1].Clear;
    AssertEquals('空で角0', 0, g.CountPiecesWithTypeInGroup(0, ptBishop));
    p := TQuantumPiece.Create(0, 0);
    p.Possibilities := [ptBishop];
    g.Board[5, 5] := p;
    AssertEquals('グループAで角1枚', 1, g.CountPiecesWithTypeInGroup(0, ptBishop));
    AssertEquals('グループBで角0', 0, g.CountPiecesWithTypeInGroup(1, ptBishop));
  finally
    g.Free;
  end;
end;

procedure TTestGroupTwoPiece.TestWouldExceedTypeCount_RejectsThirdBishopInGroup;
var
  g: TGameLogic;
  p1, p2, p3: TQuantumPiece;
  x, y: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Stands[0].Clear;
    g.Stands[1].Clear;
    p1 := TQuantumPiece.Create(0, 0);
    p1.Possibilities := [ptBishop];
    p2 := TQuantumPiece.Create(0, 0);
    p2.Possibilities := [ptBishop];
    p3 := TQuantumPiece.Create(0, 0);
    p3.Possibilities := [ptBishop, ptRook];
    g.Board[1, 5] := p1;
    g.Board[2, 5] := p2;
    g.Board[3, 5] := p3;
    AssertTrue('3枚目を角にすると上限超過', g.WouldExceedTypeCount(0, p3, [ptBishop]));
    AssertFalse('3枚目を飛にすると超過しない', g.WouldExceedTypeCount(0, p3, [ptRook]));
  finally
    g.Free;
  end;
end;

procedure TTestGroupTwoPiece.TestRemovePossibility_DoesNotTouchOtherGroup;
var
  g: TGameLogic;
  pA, pB: TQuantumPiece;
  x, y: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Stands[0].Clear;
    g.Stands[1].Clear;
    pA := TQuantumPiece.Create(0, 0);
    pA.Possibilities := [ptLance, ptRook];
    pB := TQuantumPiece.Create(1, 1);
    pB.Possibilities := [ptLance, ptRook];
    g.Board[1, 5] := pA;
    g.Board[9, 5] := pB;
    g.RemovePossibilityFromGroup(0, ptLance, nil);
    AssertTrue('グループBの駒は香の可能性が残る', ptLance in pB.Possibilities);
    AssertFalse('グループAの駒から香は削除される', ptLance in pA.Possibilities);
  finally
    g.Free;
  end;
end;

procedure TTestGroupTwoPiece.TestRemovePossibility_DoesNotTouchAlreadyCollapsed;
var
  g: TGameLogic;
  p1, p2: TQuantumPiece;
  x, y: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Stands[0].Clear;
    g.Stands[1].Clear;
    p1 := TQuantumPiece.Create(0, 0);
    p1.Possibilities := [ptRook];
    p2 := TQuantumPiece.Create(0, 0);
    p2.Possibilities := [ptRook, ptBishop];
    g.Board[1, 5] := p1;
    g.Board[2, 5] := p2;
    { 今確定した駒を p1 として除外し、他（p2）から飛を削除 }
    g.RemovePossibilityFromGroup(0, ptRook, p1);
    AssertTrue('既に飛確定の駒は飛のまま', p1.Possibilities = [ptRook]);
    AssertTrue('未確定の駒から飛が削除され角のみ', p2.Possibilities = [ptBishop]);
  finally
    g.Free;
  end;
end;

procedure TTestPathBlocking.TestIsPathClear_BlockedByFriendly;
var
  g: TGameLogic;
  x, y: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Board[5, 5] := TQuantumPiece.Create(0, 0);
    g.Board[5, 7] := TQuantumPiece.Create(0, 0);
    AssertFalse('飛車の経路に味方駒があると IsPathClear(5,5, 5,8)=false', g.IsPathClear(5, 5, 5, 8));
  finally
    g.Free;
  end;
end;

procedure TTestPathBlocking.TestIsPathClear_BlockedByEnemy;
var
  g: TGameLogic;
  x, y: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Board[5, 5] := TQuantumPiece.Create(0, 0);
    g.Board[5, 7] := TQuantumPiece.Create(1, 1);
    AssertFalse('飛車の経路に敵駒があると IsPathClear(5,5, 5,8)=false', g.IsPathClear(5, 5, 5, 8));
  finally
    g.Free;
  end;
end;

procedure TTestPathBlocking.TestIsPathClear_BlockedByBishopPath;
var
  g: TGameLogic;
  x, y: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Board[1, 1] := TQuantumPiece.Create(0, 0);
    g.Board[2, 2] := TQuantumPiece.Create(1, 1);
    AssertFalse('角の経路に駒があると IsPathClear(1,1, 4,4)=false', g.IsPathClear(1, 1, 4, 4));
  finally
    g.Free;
  end;
end;

procedure TTestPathBlocking.TestIsPathClear_EmptyPath;
var
  g: TGameLogic;
  x, y: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Board[5, 5] := TQuantumPiece.Create(0, 0);
    AssertTrue('経路に駒がなければ IsPathClear(5,5, 5,8)=true', g.IsPathClear(5, 5, 5, 8));
  finally
    g.Free;
  end;
end;

procedure TTestPathBlocking.TestIsMovePathBlocked_RookBlockedByPiece;
var
  g: TGameLogic;
  x, y: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Board[5, 5] := TQuantumPiece.Create(0, 0);
    g.Board[5, 7] := TQuantumPiece.Create(0, 0);
    AssertTrue('飛車は経路に駒があると IsMovePathBlocked=true', g.IsMovePathBlocked(5, 5, 5, 8, [ptRook]));
  finally
    g.Free;
  end;
end;

procedure TTestPathBlocking.TestIsMovePathBlocked_KnightCanJumpOverPiece;
var
  g: TGameLogic;
  x, y: Integer;
begin
  g := TGameLogic.Create;
  try
    for y := 1 to 9 do for x := 1 to 9 do g.Board[x, y] := nil;
    g.Board[5, 5] := TQuantumPiece.Create(0, 0);
    g.Board[5, 6] := TQuantumPiece.Create(0, 0);
    AssertFalse('桂馬は駒を飛び越えるので IsMovePathBlocked(5,5→4,7)=false', g.IsMovePathBlocked(5, 5, 4, 7, [ptKnight]));
  finally
    g.Free;
  end;
end;

initialization
  RegisterTest(TTestGroupTwoPiece);
  RegisterTest(TTestPathBlocking);
end.
