unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ReversiGame, ReversiAI;

type

  { TForm1 }

  TForm1 = class(TForm)
    PaintBox1: TPaintBox;
    LabelStatus: TLabel;
    LabelBlack: TLabel;
    LabelWhite: TLabel;
    ButtonNewGame: TButton;
    ButtonAIMove: TButton;
    CheckBoxAIPlayer: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ButtonNewGameClick(Sender: TObject);
    procedure ButtonAIMoveClick(Sender: TObject);
  private
    FGame: TReversiGame;
    FAI: TReversiAI;
    FCellSize: Integer;
    procedure DrawBoard;
    procedure DrawPiece(X, Y: Integer; Piece: TPiece);
    procedure UpdateStatus;
    procedure ProcessAIMove;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FGame := TReversiGame.Create;
  FAI := TReversiAI.Create(aiMedium);
  FCellSize := 50;
  PaintBox1.Width := 8 * FCellSize;
  PaintBox1.Height := 8 * FCellSize;
  ClientWidth := PaintBox1.Width + 20;
  ClientHeight := PaintBox1.Height + 120;
  UpdateStatus;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FAI.Free;
  FGame.Free;
end;

procedure TForm1.DrawBoard;
var
  X, Y: Integer;
  Board: TBoard;
begin
  with PaintBox1.Canvas do
  begin
    // ボードの背景（緑）
    Brush.Color := $00A0A000; // 暗い緑
    FillRect(0, 0, PaintBox1.Width, PaintBox1.Height);

    // グリッド線
    Pen.Color := clBlack;
    Pen.Width := 1;
    for X := 0 to 8 do
    begin
      MoveTo(X * FCellSize, 0);
      LineTo(X * FCellSize, PaintBox1.Height);
    end;
    for Y := 0 to 8 do
    begin
      MoveTo(0, Y * FCellSize);
      LineTo(PaintBox1.Width, Y * FCellSize);
    end;

    // 石を描画
    Board := FGame.GetBoard;
    for Y := 0 to 7 do
      for X := 0 to 7 do
        DrawPiece(X, Y, Board[X, Y]);

    // 合法手をハイライト
    if not FGame.IsGameOver then
    begin
      for Y := 0 to 7 do
        for X := 0 to 7 do
        begin
          if FGame.CanPlacePiece(X, Y) then
          begin
            Brush.Color := clYellow;
            Brush.Style := bsSolid;
            Pen.Color := clYellow;
            Ellipse(X * FCellSize + FCellSize div 2 - 5,
                    Y * FCellSize + FCellSize div 2 - 5,
                    X * FCellSize + FCellSize div 2 + 5,
                    Y * FCellSize + FCellSize div 2 + 5);
          end;
        end;
    end;
  end;
end;

procedure TForm1.DrawPiece(X, Y: Integer; Piece: TPiece);
var
  CenterX, CenterY: Integer;
  Radius: Integer;
begin
  CenterX := X * FCellSize + FCellSize div 2;
  CenterY := Y * FCellSize + FCellSize div 2;
  Radius := FCellSize div 2 - 5;

  with PaintBox1.Canvas do
  begin
    if Piece = pBlack then
    begin
      // 黒い石
      Brush.Color := clBlack;
      Pen.Color := clBlack;
      Ellipse(CenterX - Radius, CenterY - Radius,
              CenterX + Radius, CenterY + Radius);
      // ハイライト
      Brush.Color := $00404040;
      Ellipse(CenterX - Radius + 2, CenterY - Radius + 2,
              CenterX - Radius div 2, CenterY - Radius div 2);
    end
    else if Piece = pWhite then
    begin
      // 白い石
      Brush.Color := clWhite;
      Pen.Color := clBlack;
      Pen.Width := 2;
      Ellipse(CenterX - Radius, CenterY - Radius,
              CenterX + Radius, CenterY + Radius);
      // ハイライト
      Brush.Color := $00E0E0E0;
      Ellipse(CenterX - Radius + 2, CenterY - Radius + 2,
              CenterX - Radius div 2, CenterY - Radius div 2);
      Pen.Width := 1;
    end;
  end;
end;

procedure TForm1.PaintBox1Paint(Sender: TObject);
begin
  DrawBoard;
end;

procedure TForm1.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  BoardX, BoardY: Integer;
begin
  if FGame.IsGameOver then
    Exit;

  // マウス座標をボード座標に変換
  BoardX := X div FCellSize;
  BoardY := Y div FCellSize;

  // 範囲チェック
  if (BoardX < 0) or (BoardX > 7) or (BoardY < 0) or (BoardY > 7) then
    Exit;

  // 石を置く
  if FGame.PlacePiece(BoardX, BoardY) then
  begin
    PaintBox1.Invalidate;
    UpdateStatus;

    // AIが有効で、次のプレイヤーがAIの場合
    if CheckBoxAIPlayer.Checked and (FGame.GetCurrentPlayer = plWhite) then
    begin
      Application.ProcessMessages;
      ProcessAIMove;
    end;
  end;
end;

procedure TForm1.UpdateStatus;
var
  CurrentPlayer: TPlayer;
  PlayerName: String;
begin
  if FGame.IsGameOver then
  begin
    if FGame.GetBlackCount > FGame.GetWhiteCount then
      LabelStatus.Caption := 'ゲーム終了 - 黒の勝ち！'
    else if FGame.GetWhiteCount > FGame.GetBlackCount then
      LabelStatus.Caption := 'ゲーム終了 - 白の勝ち！'
    else
      LabelStatus.Caption := 'ゲーム終了 - 引き分け！';
  end
  else
  begin
    CurrentPlayer := FGame.GetCurrentPlayer;
    if CurrentPlayer = plBlack then
      PlayerName := '黒'
    else
      PlayerName := '白';
    LabelStatus.Caption := '現在のプレイヤー: ' + PlayerName;
  end;

  LabelBlack.Caption := '黒: ' + IntToStr(FGame.GetBlackCount);
  LabelWhite.Caption := '白: ' + IntToStr(FGame.GetWhiteCount);
end;

procedure TForm1.ButtonNewGameClick(Sender: TObject);
begin
  FGame.Initialize;
  PaintBox1.Invalidate;
  UpdateStatus;
end;

procedure TForm1.ButtonAIMoveClick(Sender: TObject);
begin
  ProcessAIMove;
end;

procedure TForm1.ProcessAIMove;
var
  X, Y: Integer;
begin
  if FGame.IsGameOver then
    Exit;

  if FAI.GetMove(FGame, FGame.GetCurrentPlayer, X, Y) then
  begin
    if FGame.PlacePiece(X, Y) then
    begin
      PaintBox1.Invalidate;
      UpdateStatus;
    end;
  end;
end;

end.
