unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls;

type
  TCellValue = (cvEmpty, cvPlayer, cvAI);
  TGameState = (gsPlaying, gsPlayerWon, gsAIWon, gsDraw);

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    ButtonReset: TButton;
    LabelStatus: TLabel;
    procedure ButtonClick(Sender: TObject);
    procedure ButtonResetClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    Board: array[0..2, 0..2] of TCellValue;
    GameButtons: array[0..8] of TButton;
    CurrentPlayer: TCellValue;
    GameState: TGameState;
    procedure InitializeGame;
    procedure UpdateDisplay;
    function CheckWinner: TGameState;
    function IsBoardFull: Boolean;
    function GetBestMove: Integer;
    function Minimax(depth: Integer; isMaximizing: Boolean): Integer;
    function EvaluateBoard: Integer;
    procedure MakeAIMove;
    procedure DisableAllButtons;
    procedure EnableAllButtons;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  GameButtons[0] := Button1;
  GameButtons[1] := Button2;
  GameButtons[2] := Button3;
  GameButtons[3] := Button4;
  GameButtons[4] := Button5;
  GameButtons[5] := Button6;
  GameButtons[6] := Button7;
  GameButtons[7] := Button8;
  GameButtons[8] := Button9;
  InitializeGame;
end;

procedure TForm1.InitializeGame;
var
  i, j: Integer;
begin
  for i := 0 to 2 do
    for j := 0 to 2 do
      Board[i, j] := cvEmpty;
  
  CurrentPlayer := cvPlayer;
  GameState := gsPlaying;
  UpdateDisplay;
  EnableAllButtons;
end;

procedure TForm1.UpdateDisplay;
var
  i, j, index: Integer;
begin
  for i := 0 to 2 do
    for j := 0 to 2 do
    begin
      index := i * 3 + j;
      case Board[i, j] of
        cvEmpty: GameButtons[index].Caption := '';
        cvPlayer: GameButtons[index].Caption := '○';
        cvAI: GameButtons[index].Caption := '×';
      end;
    end;
  
  case GameState of
    gsPlaying:
      if CurrentPlayer = cvPlayer then
        LabelStatus.Caption := 'あなたの番です（○）'
      else
        LabelStatus.Caption := 'AIの番です...';
    gsPlayerWon: LabelStatus.Caption := 'あなたの勝ち！';
    gsAIWon: LabelStatus.Caption := 'AIの勝ち！';
    gsDraw: LabelStatus.Caption := '引き分け！';
  end;
end;

function TForm1.CheckWinner: TGameState;
var
  i: Integer;
begin
  Result := gsPlaying;
  
  // 横のチェック
  for i := 0 to 2 do
  begin
    if (Board[i, 0] = Board[i, 1]) and (Board[i, 1] = Board[i, 2]) and (Board[i, 0] <> cvEmpty) then
    begin
      if Board[i, 0] = cvPlayer then
        Exit(gsPlayerWon)
      else
        Exit(gsAIWon);
    end;
  end;
  
  // 縦のチェック
  for i := 0 to 2 do
  begin
    if (Board[0, i] = Board[1, i]) and (Board[1, i] = Board[2, i]) and (Board[0, i] <> cvEmpty) then
    begin
      if Board[0, i] = cvPlayer then
        Exit(gsPlayerWon)
      else
        Exit(gsAIWon);
    end;
  end;
  
  // 斜めのチェック
  if (Board[0, 0] = Board[1, 1]) and (Board[1, 1] = Board[2, 2]) and (Board[0, 0] <> cvEmpty) then
  begin
    if Board[0, 0] = cvPlayer then
      Exit(gsPlayerWon)
    else
      Exit(gsAIWon);
  end;
  
  if (Board[0, 2] = Board[1, 1]) and (Board[1, 1] = Board[2, 0]) and (Board[0, 2] <> cvEmpty) then
  begin
    if Board[0, 2] = cvPlayer then
      Exit(gsPlayerWon)
    else
      Exit(gsAIWon);
  end;
  
  // 引き分けチェック
  if IsBoardFull then
    Result := gsDraw;
end;

function TForm1.IsBoardFull: Boolean;
var
  i, j: Integer;
begin
  Result := True;
  for i := 0 to 2 do
    for j := 0 to 2 do
      if Board[i, j] = cvEmpty then
      begin
        Result := False;
        Exit;
      end;
end;

function TForm1.EvaluateBoard: Integer;
var
  i: Integer;
begin
  Result := 0;
  
  // 横の評価
  for i := 0 to 2 do
  begin
    if (Board[i, 0] = Board[i, 1]) and (Board[i, 1] = Board[i, 2]) then
    begin
      if Board[i, 0] = cvAI then
        Exit(10)
      else if Board[i, 0] = cvPlayer then
        Exit(-10);
    end;
  end;
  
  // 縦の評価
  for i := 0 to 2 do
  begin
    if (Board[0, i] = Board[1, i]) and (Board[1, i] = Board[2, i]) then
    begin
      if Board[0, i] = cvAI then
        Exit(10)
      else if Board[0, i] = cvPlayer then
        Exit(-10);
    end;
  end;
  
  // 斜めの評価
  if (Board[0, 0] = Board[1, 1]) and (Board[1, 1] = Board[2, 2]) then
  begin
    if Board[0, 0] = cvAI then
      Exit(10)
    else if Board[0, 0] = cvPlayer then
      Exit(-10);
  end;
  
  if (Board[0, 2] = Board[1, 1]) and (Board[1, 1] = Board[2, 0]) then
  begin
    if Board[0, 2] = cvAI then
      Exit(10)
    else if Board[0, 2] = cvPlayer then
      Exit(-10);
  end;
end;

function TForm1.Minimax(depth: Integer; isMaximizing: Boolean): Integer;
var
  score, bestScore, i, j, index: Integer;
  tempValue: TCellValue;
begin
  score := EvaluateBoard;
  
  // 終了条件
  if score = 10 then
    Exit(10 - depth);
  if score = -10 then
    Exit(depth - 10);
  if IsBoardFull then
    Exit(0);
  
  if isMaximizing then
  begin
    bestScore := -1000;
    for i := 0 to 2 do
      for j := 0 to 2 do
      begin
        if Board[i, j] = cvEmpty then
        begin
          Board[i, j] := cvAI;
          score := Minimax(depth + 1, False);
          Board[i, j] := cvEmpty;
          if score > bestScore then
            bestScore := score;
        end;
      end;
    Result := bestScore;
  end
  else
  begin
    bestScore := 1000;
    for i := 0 to 2 do
      for j := 0 to 2 do
      begin
        if Board[i, j] = cvEmpty then
        begin
          Board[i, j] := cvPlayer;
          score := Minimax(depth + 1, True);
          Board[i, j] := cvEmpty;
          if score < bestScore then
            bestScore := score;
        end;
      end;
    Result := bestScore;
  end;
end;

function TForm1.GetBestMove: Integer;
var
  bestScore, bestMove, score, i, j, index: Integer;
begin
  bestScore := -1000;
  bestMove := -1;
  
  for i := 0 to 2 do
    for j := 0 to 2 do
    begin
      index := i * 3 + j;
      if Board[i, j] = cvEmpty then
      begin
        Board[i, j] := cvAI;
        score := Minimax(0, False);
        Board[i, j] := cvEmpty;
        
        if score > bestScore then
        begin
          bestScore := score;
          bestMove := index;
        end;
      end;
    end;
  
  Result := bestMove;
end;

procedure TForm1.MakeAIMove;
var
  move: Integer;
  row, col: Integer;
begin
  if GameState <> gsPlaying then
    Exit;
  
  move := GetBestMove;
  if move >= 0 then
  begin
    row := move div 3;
    col := move mod 3;
    Board[row, col] := cvAI;
    GameState := CheckWinner;
    CurrentPlayer := cvPlayer;
    UpdateDisplay;
    
    if GameState <> gsPlaying then
      DisableAllButtons;
  end;
end;

procedure TForm1.ButtonClick(Sender: TObject);
var
  button: TButton;
  index, row, col: Integer;
begin
  if GameState <> gsPlaying then
    Exit;
  
  if CurrentPlayer <> cvPlayer then
    Exit;
  
  button := Sender as TButton;
  index := -1;
  
  // ボタンのインデックスを取得
  if button = Button1 then index := 0
  else if button = Button2 then index := 1
  else if button = Button3 then index := 2
  else if button = Button4 then index := 3
  else if button = Button5 then index := 4
  else if button = Button6 then index := 5
  else if button = Button7 then index := 6
  else if button = Button8 then index := 7
  else if button = Button9 then index := 8;
  
  if index < 0 then
    Exit;
  
  row := index div 3;
  col := index mod 3;
  
  // 既に埋まっている場合は無視
  if Board[row, col] <> cvEmpty then
    Exit;
  
  // プレイヤーの手を配置
  Board[row, col] := cvPlayer;
  GameState := CheckWinner;
  
  if GameState = gsPlaying then
  begin
    CurrentPlayer := cvAI;
    UpdateDisplay;
    Application.ProcessMessages;
    Sleep(500); // AIの思考時間をシミュレート
    MakeAIMove;
  end
  else
  begin
    DisableAllButtons;
  end;
  
  UpdateDisplay;
end;

procedure TForm1.ButtonResetClick(Sender: TObject);
begin
  InitializeGame;
end;

procedure TForm1.DisableAllButtons;
var
  i: Integer;
begin
  for i := 0 to 8 do
    GameButtons[i].Enabled := False;
end;

procedure TForm1.EnableAllButtons;
var
  i: Integer;
begin
  for i := 0 to 8 do
    GameButtons[i].Enabled := True;
end;

end.
