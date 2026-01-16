program day016_Sokoban;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, Crt;

const
  Map: array[0..4] of string = (
    '########',
    '#   .  #',
    '# $$@  #',
    '#   .  #',
    '########'
  );

type
  TGameState = record
    MapData: array[0..4] of string;
    PlayerX, PlayerY: Integer;
    GoalCount: Integer;
    BoxOnGoalCount: Integer;
  end;

var
  Game: TGameState;
  Ch: Char;
  NewX, NewY: Integer;
  GameWon: Boolean;

procedure InitializeGame;
var
  i, j: Integer;
begin
  // Copy map data
  for i := 0 to 4 do
    Game.MapData[i] := Map[i];
  
  // Find player position
  Game.PlayerX := -1;
  Game.PlayerY := -1;
  Game.GoalCount := 0;
  Game.BoxOnGoalCount := 0;
  
  for i := 0 to 4 do
    for j := 1 to Length(Game.MapData[i]) do
    begin
      if Game.MapData[i][j] = '@' then
      begin
        Game.PlayerX := j;
        Game.PlayerY := i;
        Game.MapData[i][j] := ' '; // Replace player position with space
      end
      else if Game.MapData[i][j] = '.' then
        Inc(Game.GoalCount)
      else if Game.MapData[i][j] = '*' then
      begin
        Inc(Game.GoalCount);
        Inc(Game.BoxOnGoalCount);
      end;
    end;
  
  GameWon := False;
end;

procedure DrawMap;
var
  i, j: Integer;
begin
  ClrScr;
  WriteLn('=== Sokoban Game ===');
  WriteLn('Controls: Arrow keys to move, Q to quit');
  WriteLn;
  
  for i := 0 to 4 do
  begin
    for j := 1 to Length(Game.MapData[i]) do
    begin
      if (j = Game.PlayerX) and (i = Game.PlayerY) then
        Write('@')
      else
        Write(Game.MapData[i][j]);
    end;
    WriteLn;
  end;
  
  WriteLn;
  WriteLn('Goals: ', Game.BoxOnGoalCount, ' / ', Game.GoalCount);
  
  if GameWon then
  begin
    WriteLn;
    WriteLn('*** Congratulations! You cleared the level! ***');
  end;
end;

function CanMove(X, Y: Integer): Boolean;
var
  Cell: Char;
begin
  Result := False;
  if (Y < 0) or (Y > 4) or (X < 1) or (X > Length(Game.MapData[Y])) then
    Exit;
  
  Cell := Game.MapData[Y][X];
  Result := (Cell <> '#');
end;

function CanPushBox(BoxX, BoxY, DirX, DirY: Integer): Boolean;
var
  NextBoxX, NextBoxY: Integer;
  Cell: Char;
begin
  Result := False;
  NextBoxX := BoxX + DirX;
  NextBoxY := BoxY + DirY;
  
  if (NextBoxY < 0) or (NextBoxY > 4) or 
     (NextBoxX < 1) or (NextBoxX > Length(Game.MapData[NextBoxY])) then
    Exit;
  
  Cell := Game.MapData[NextBoxY][NextBoxX];
  Result := (Cell <> '#') and (Cell <> '$') and (Cell <> '*');
end;

procedure MovePlayer(DirX, DirY: Integer);
var
  Cell: Char;
  BoxX, BoxY: Integer;
  NextBoxX, NextBoxY: Integer;
  WasOnGoal: Boolean;
begin
  NewX := Game.PlayerX + DirX;
  NewY := Game.PlayerY + DirY;
  
  if not CanMove(NewX, NewY) then
    Exit;
  
  Cell := Game.MapData[NewY][NewX];
  
  // If there is a box
  if (Cell = '$') or (Cell = '*') then
  begin
    BoxX := NewX;
    BoxY := NewY;
    NextBoxX := BoxX + DirX;
    NextBoxY := BoxY + DirY;
    
    if not CanPushBox(BoxX, BoxY, DirX, DirY) then
      Exit;
    
    // Push the box
    WasOnGoal := (Cell = '*');
    Game.MapData[BoxY][BoxX] := ' ';
    if WasOnGoal then
      Dec(Game.BoxOnGoalCount);
    
    // Check the next position of the box
    Cell := Game.MapData[NextBoxY][NextBoxX];
    if Cell = '.' then
    begin
      Game.MapData[NextBoxY][NextBoxX] := '*';
      Inc(Game.BoxOnGoalCount);
    end
    else
      Game.MapData[NextBoxY][NextBoxX] := '$';
  end;
  
  // Move player
  Game.PlayerX := NewX;
  Game.PlayerY := NewY;
  
  // Check if all goals are completed
  if Game.BoxOnGoalCount = Game.GoalCount then
    GameWon := True;
end;

begin
  InitializeGame;
  
  repeat
    DrawMap;
    
    Ch := ReadKey;
    
    if Ch = #0 then // Extended key (arrow keys, etc.)
    begin
      Ch := ReadKey;
      case Ch of
        #72: MovePlayer(0, -1);  // Up
        #80: MovePlayer(0, 1);    // Down
        #75: MovePlayer(-1, 0);   // Left
        #77: MovePlayer(1, 0);    // Right
      end;
    end
    else if (Ch = 'q') or (Ch = 'Q') then
      Break;
    
  until GameWon;
  
  if GameWon then
  begin
    DrawMap;
    WriteLn;
    WriteLn('CLEAR!');
    // Exit immediately
  end;
end.
