unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ChessGame, ChessAI;

type

  { TForm1 }

  TForm1 = class(TForm)
    PaintBox1: TPaintBox;
    Button1: TButton;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button1Click(Sender: TObject);
  private
    FGame: TChessGame;
    FAI: TChessAI;
    FSelectedRow, FSelectedCol: Integer;
    FHasSelection: Boolean;
    procedure DrawBoard;
    procedure DrawPiece(Row, Col: Integer; Piece: TChessPiece);
    function GetSquareFromPos(X, Y: Integer; out Row, Col: Integer): Boolean;
    procedure MakeAIMove;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FGame := TChessGame.Create;
  FAI := TChessAI.Create;
  FSelectedRow := -1;
  FSelectedCol := -1;
  FHasSelection := False;
  PaintBox1.Width := 480;
  PaintBox1.Height := 480;
  ClientWidth := 600;
  ClientHeight := 520;
  Caption := 'チェスゲーム';
  Label1.Caption := '白のターン';
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FGame.Free;
  FAI.Free;
end;

procedure TForm1.PaintBox1Paint(Sender: TObject);
begin
  DrawBoard;
end;

procedure TForm1.DrawBoard;
var
  i, j: Integer;
  SquareSize: Integer;
  Board: TChessBoard;
  Piece: TChessPiece;
begin
  SquareSize := PaintBox1.Width div 8;
  Board := FGame.GetBoard;
  
  with PaintBox1.Canvas do
  begin
    // 盤面を描画
    for i := 0 to 7 do
      for j := 0 to 7 do
      begin
        // マスの色
        if (i + j) mod 2 = 0 then
          Brush.Color := $FFEEDD
        else
          Brush.Color := $8B4513;
        
        // 選択されたマスをハイライト
        if FHasSelection and (FSelectedRow = i) and (FSelectedCol = j) then
          Brush.Color := $00FFFF;
        
        FillRect(j * SquareSize, i * SquareSize, 
                 (j + 1) * SquareSize, (i + 1) * SquareSize);
        
        // 駒を描画
        Piece := Board[i, j];
        DrawPiece(i, j, Piece);
      end;
  end;
end;

procedure TForm1.DrawPiece(Row, Col: Integer; Piece: TChessPiece);
var
  SquareSize: Integer;
  CenterX, CenterY: Integer;
  PieceChar: String;
begin
  if Piece.PieceType = ptNone then
    Exit;
  
  SquareSize := PaintBox1.Width div 8;
  CenterX := Col * SquareSize + SquareSize div 2;
  CenterY := Row * SquareSize + SquareSize div 2;
  
  with PaintBox1.Canvas do
  begin
    Font.Size := SquareSize div 2;
    Font.Style := [fsBold];
    
    // ユニコードのチェス駒文字を使用
    if Piece.Color = pcWhite then
    begin
      Font.Color := clBlack;
      // 白の駒（U+2654-2659）
      case Piece.PieceType of
        ptPawn: PieceChar := '♙';
        ptRook: PieceChar := '♖';
        ptKnight: PieceChar := '♘';
        ptBishop: PieceChar := '♗';
        ptQueen: PieceChar := '♕';
        ptKing: PieceChar := '♔';
        else PieceChar := '';
      end;
    end
    else
    begin
      Font.Color := clBlack;
      // 黒の駒（U+265A-265F）
      case Piece.PieceType of
        ptPawn: PieceChar := '♟';
        ptRook: PieceChar := '♜';
        ptKnight: PieceChar := '♞';
        ptBishop: PieceChar := '♝';
        ptQueen: PieceChar := '♛';
        ptKing: PieceChar := '♚';
        else PieceChar := '';
      end;
    end;
    
    TextOut(CenterX - TextWidth(PieceChar) div 2,
            CenterY - TextHeight(PieceChar) div 2,
            PieceChar);
  end;
end;

function TForm1.GetSquareFromPos(X, Y: Integer; out Row, Col: Integer): Boolean;
var
  SquareSize: Integer;
begin
  Result := False;
  SquareSize := PaintBox1.Width div 8;
  
  if (X < 0) or (X >= PaintBox1.Width) or (Y < 0) or (Y >= PaintBox1.Height) then
    Exit;
  
  Col := X div SquareSize;
  Row := Y div SquareSize;
  
  if (Row >= 0) and (Row < 8) and (Col >= 0) and (Col < 8) then
    Result := True;
end;

procedure TForm1.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Row, Col: Integer;
  Board: TChessBoard;
  Piece: TChessPiece;
begin
  if FGame.IsGameOver then
    Exit;
  
  if not GetSquareFromPos(X, Y, Row, Col) then
    Exit;
  
  Board := FGame.GetBoard;
  Piece := Board[Row, Col];
  
  if FHasSelection then
  begin
    // 移動を試みる
    if FGame.MakeMove(FSelectedRow, FSelectedCol, Row, Col) then
    begin
      FHasSelection := False;
      PaintBox1.Invalidate;
      
      // ゲーム終了チェック
      if FGame.IsGameOver then
      begin
        if FGame.GetWinner = pcWhite then
          Label1.Caption := '白の勝利！'
        else
          Label1.Caption := '黒の勝利！';
        ShowMessage('ゲーム終了！');
      end
      else
      begin
        // ターン表示を更新
        if FGame.GetCurrentPlayer = pcWhite then
          Label1.Caption := '白のターン'
        else
          Label1.Caption := '黒のターン';
        
        // AIのターンの場合、AIに移動させる
        if FGame.GetCurrentPlayer = pcBlack then
        begin
          Application.ProcessMessages;
          MakeAIMove;
        end;
      end;
    end
    else
    begin
      // 移動できない場合、新しい選択
      if (Piece.PieceType <> ptNone) and (Piece.Color = FGame.GetCurrentPlayer) then
      begin
        FSelectedRow := Row;
        FSelectedCol := Col;
        FHasSelection := True;
      end
      else
        FHasSelection := False;
      PaintBox1.Invalidate;
    end;
  end
  else
  begin
    // 新しい選択
    if (Piece.PieceType <> ptNone) and (Piece.Color = FGame.GetCurrentPlayer) then
    begin
      FSelectedRow := Row;
      FSelectedCol := Col;
      FHasSelection := True;
      PaintBox1.Invalidate;
    end;
  end;
end;

procedure TForm1.MakeAIMove;
var
  BestMove: TMove;
begin
  if FGame.IsGameOver then
    Exit;
  
  BestMove := FAI.GetBestMove(FGame, pcBlack, 2);
  
  if (BestMove.FromRow >= 0) and (BestMove.FromRow < 8) and
     (BestMove.FromCol >= 0) and (BestMove.FromCol < 8) and
     (BestMove.ToRow >= 0) and (BestMove.ToRow < 8) and
     (BestMove.ToCol >= 0) and (BestMove.ToCol < 8) then
  begin
    if FGame.MakeMove(BestMove.FromRow, BestMove.FromCol, 
                      BestMove.ToRow, BestMove.ToCol) then
    begin
      PaintBox1.Invalidate;
      
      // ゲーム終了チェック
      if FGame.IsGameOver then
      begin
        if FGame.GetWinner = pcWhite then
          Label1.Caption := '白の勝利！'
        else
          Label1.Caption := '黒の勝利！';
        ShowMessage('ゲーム終了！');
      end
      else
      begin
        if FGame.GetCurrentPlayer = pcWhite then
          Label1.Caption := '白のターン'
        else
          Label1.Caption := '黒のターン';
      end;
    end;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  FGame.Reset;
  FHasSelection := False;
  Label1.Caption := '白のターン';
  PaintBox1.Invalidate;
end;

end.
