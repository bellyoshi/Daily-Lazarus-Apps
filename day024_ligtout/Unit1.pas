unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

const
  GridSize = 5;
  CellSize = 60;
  Gap = 5;

type

  { TForm1 }

  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure ResetButtonClick(Sender: TObject);
  private
    FLights: array[0..GridSize-1, 0..GridSize-1] of Boolean;
    FPanels: array[0..GridSize-1, 0..GridSize-1] of TPanel;
    FStartBtn: TButton;
    
    procedure PanelClick(Sender: TObject);
    procedure InitializeGame;
    procedure ToggleCell(x, y: Integer);
    procedure ToggleState(x, y: Integer);
    procedure UpdateVisuals;
    function CheckWin: Boolean;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  x, y: Integer;
  P: TPanel;
begin
  // Form setup
  Caption := 'Lights Out Game';
  ClientWidth := (CellSize + Gap) * GridSize + Gap;
  ClientHeight := (CellSize + Gap) * GridSize + Gap + 50; // Extra space for button
  Position := poScreenCenter;
  Color := clWhite;

  // Create Grid
  for x := 0 to GridSize - 1 do
  begin
    for y := 0 to GridSize - 1 do
    begin
      P := TPanel.Create(Self);
      P.Parent := Self;
      P.Width := CellSize;
      P.Height := CellSize;
      P.Left := Gap + x * (CellSize + Gap);
      P.Top := Gap + y * (CellSize + Gap);
      P.Tag := x * GridSize + y; // Store coordinate in Tag (x * 5 + y)
      P.OnClick := @PanelClick;
      P.BevelOuter := bvNone;
      P.Caption := '';
      P.Color := clSilver; // Default off
      
      FPanels[x, y] := P;
    end;
  end;

  // Create Reset Button
  FStartBtn := TButton.Create(Self);
  FStartBtn.Parent := Self;
  FStartBtn.Caption := 'ゲームリセット';
  FStartBtn.Left := Gap;
  FStartBtn.Top := (CellSize + Gap) * GridSize + 10;
  FStartBtn.Width := ClientWidth - (Gap * 2);
  FStartBtn.Height := 30;
  FStartBtn.OnClick := @ResetButtonClick;

  // Start the game
  InitializeGame;
end;

procedure TForm1.InitializeGame;
var
  i, rx, ry: Integer;
begin
  Randomize;

  // Reset all to OFF
  for i := 0 to GridSize - 1 do
    for rx := 0 to GridSize - 1 do
      FLights[i, rx] := False;

  // Toggle random cells to ensure solvability
  // A configuration is solvable if it can be reached from the solved state (all off)
  // by toggling valid moves.
  for i := 1 to 20 do
  begin
    rx := Random(GridSize);
    ry := Random(GridSize);
    ToggleCell(rx, ry);
  end;
  
  UpdateVisuals;
end;

procedure TForm1.ResetButtonClick(Sender: TObject);
begin
  InitializeGame;
end;

procedure TForm1.PanelClick(Sender: TObject);
var
  idx, x, y: Integer;
begin
  if Sender is TPanel then
  begin
    idx := TPanel(Sender).Tag;
    x := idx div GridSize;
    y := idx mod GridSize;
    
    ToggleCell(x, y);
    UpdateVisuals;
    
    if CheckWin then
    begin
      ShowMessage('クリアおめでとうございます！');
      InitializeGame;
    end;
  end;
end;

procedure TForm1.ToggleState(x, y: Integer);
begin
  if (x >= 0) and (x < GridSize) and (y >= 0) and (y < GridSize) then
  begin
    FLights[x, y] := not FLights[x, y];
  end;
end;

procedure TForm1.ToggleCell(x, y: Integer);
begin
  ToggleState(x, y);     // Center
  ToggleState(x - 1, y); // Left
  ToggleState(x + 1, y); // Right
  ToggleState(x, y - 1); // Top
  ToggleState(x, y + 1); // Bottom
end;

procedure TForm1.UpdateVisuals;
var
  x, y: Integer;
begin
  for x := 0 to GridSize - 1 do
  begin
    for y := 0 to GridSize - 1 do
    begin
      if FLights[x, y] then
      begin
        // ON - Bright Color
        FPanels[x, y].Color := $0080FFFF; // Yellow-ish (BGR format in hex: $00BBGGRR)
        FPanels[x, y].Caption := 'ON';
      end
      else
      begin
        // OFF - Dark Color
        FPanels[x, y].Color := clGray;
        FPanels[x, y].Caption := '';
      end;
    end;
  end;
end;

function TForm1.CheckWin: Boolean;
var
  x, y: Integer;
begin
  Result := True;
  for x := 0 to GridSize - 1 do
    for y := 0 to GridSize - 1 do
      if FLights[x, y] then
      begin
        Result := False;
        Exit;
      end;
end;

end.
