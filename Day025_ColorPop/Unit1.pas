unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Types;

const
  BoardSize = 10;
  CellSize = 40;
  ColorCount = 3;
  EmptyCell = -1;

type
  PPoint = ^TPoint;

  { TForm1 }

  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormPaint(Sender: TObject);
  private
    Board: array[0..BoardSize-1, 0..BoardSize-1] of Integer;
    procedure InitGame;
    procedure DrawBoard;
    procedure HandleClick(X, Y: Integer);
    procedure RemoveAndDrop(StartX, StartY: Integer);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  ClientWidth := BoardSize * CellSize;
  ClientHeight := BoardSize * CellSize;
  Caption := 'Day025 ColorPop';
  DoubleBuffered := True;

  OnPaint := @FormPaint;
  OnMouseDown := @FormMouseDown;
  
  Randomize;
  InitGame;
end;

procedure TForm1.InitGame;
var
  x, y: Integer;
begin
  for y := 0 to BoardSize - 1 do
    for x := 0 to BoardSize - 1 do
      Board[y, x] := Random(ColorCount) + 1; // 1..3
end;

procedure TForm1.FormPaint(Sender: TObject);
begin
  DrawBoard;
end;

procedure TForm1.DrawBoard;
var
  x, y: Integer;
  R: TRect;
begin
  Canvas.Brush.Color := clWhite;
  Canvas.FillRect(ClientRect);
  Canvas.Pen.Color := clBlack;

  for y := 0 to BoardSize - 1 do
    for x := 0 to BoardSize - 1 do
    begin
      R := Rect(x * CellSize, y * CellSize, (x + 1) * CellSize, (y + 1) * CellSize);
      
      case Board[y, x] of
        1: Canvas.Brush.Color := $004444FF; // Red
        2: Canvas.Brush.Color := $0044FF44; // Green
        3: Canvas.Brush.Color := $00FFCC44; // Blue/Cyan
        EmptyCell: Canvas.Brush.Color := clWhite;
      else
        Canvas.Brush.Color := clWhite;
      end;
      
      if Board[y, x] <> EmptyCell then
      begin
        Canvas.Rectangle(R);
      end;
    end;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  GridX, GridY: Integer;
begin
  if Button <> mbLeft then Exit;

  GridX := X div CellSize;
  GridY := Y div CellSize;

  if (GridX >= 0) and (GridX < BoardSize) and (GridY >= 0) and (GridY < BoardSize) then
  begin
    HandleClick(GridX, GridY);
  end;
end;

procedure TForm1.HandleClick(X, Y: Integer);
begin
  if Board[Y, X] = EmptyCell then Exit;
  RemoveAndDrop(X, Y);
end;

procedure TForm1.RemoveAndDrop(StartX, StartY: Integer);
var
  Q: TList;
  Matches: TList;
  Visited: array[0..BoardSize-1, 0..BoardSize-1] of Boolean;
  TargetColor: Integer;
  P, NewP, TempP: PPoint;
  cx, cy, nx, ny, i: Integer;
  dx: array[0..3] of Integer = (0, 0, -1, 1);
  dy: array[0..3] of Integer = (-1, 1, 0, 0);
  WritePos: Integer;
begin
  TargetColor := Board[StartY, StartX];
  if TargetColor = EmptyCell then Exit;

  Q := TList.Create;
  Matches := TList.Create;
  FillChar(Visited, SizeOf(Visited), False);

  try
    New(P); P^.X := StartX; P^.Y := StartY;
    Q.Add(P);
    Visited[StartY, StartX] := True;
    
    while Q.Count > 0 do
    begin
      P := PPoint(Q[0]);
      Q.Delete(0);

      cx := P^.X;
      cy := P^.Y;
      
      New(TempP); TempP^.X := cx; TempP^.Y := cy;
      Matches.Add(TempP);
      
      Dispose(P); // Free queue node

      for i := 0 to 3 do
      begin
        nx := cx + dx[i];
        ny := cy + dy[i];

        if (nx >= 0) and (nx < BoardSize) and (ny >= 0) and (ny < BoardSize) then
        begin
          if (not Visited[ny, nx]) and (Board[ny, nx] = TargetColor) then
          begin
            Visited[ny, nx] := True;
            New(NewP); NewP^.X := nx; NewP^.Y := ny;
            Q.Add(NewP);
          end;
        end;
      end;
    end;

    if Matches.Count >= 2 then
    begin
      for i := 0 to Matches.Count - 1 do
      begin
        P := PPoint(Matches[i]);
        Board[P^.Y, P^.X] := EmptyCell;
      end;

      for cx := 0 to BoardSize - 1 do
      begin
        WritePos := BoardSize - 1;
        for cy := BoardSize - 1 downto 0 do
        begin
          if Board[cy, cx] <> EmptyCell then
          begin
            if cy <> WritePos then
              Board[WritePos, cx] := Board[cy, cx];
            Dec(WritePos);
          end;
        end;
        
        while WritePos >= 0 do
        begin
          Board[WritePos, cx] := EmptyCell;
          Dec(WritePos);
        end;
      end;

      Invalidate;
    end;

  finally
    while Q.Count > 0 do
    begin
      Dispose(PPoint(Q[0]));
      Q.Delete(0);
    end;
    Q.Free;

    for i := 0 to Matches.Count - 1 do
      Dispose(PPoint(Matches[i]));
    Matches.Free;
  end;
end;

end.
