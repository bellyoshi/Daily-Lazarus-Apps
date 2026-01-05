unit ChessAI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ChessGame;

type
  TChessAI = class
  private
    function EvaluateBoard(Board: TChessBoard; Color: TPieceColor): Integer;
    function GetPieceValue(PieceType: TPieceType): Integer;
    function Minimax(Game: TChessGame; Depth: Integer; Alpha, Beta: Integer; 
                     Maximizing: Boolean): Integer;
  public
    function GetBestMove(Game: TChessGame; Color: TPieceColor; Depth: Integer): TMove;
  end;

implementation

function TChessAI.GetPieceValue(PieceType: TPieceType): Integer;
begin
  case PieceType of
    ptPawn: Result := 100;
    ptKnight: Result := 320;
    ptBishop: Result := 330;
    ptRook: Result := 500;
    ptQueen: Result := 900;
    ptKing: Result := 20000;
    else Result := 0;
  end;
end;

function TChessAI.EvaluateBoard(Board: TChessBoard; Color: TPieceColor): Integer;
var
  i, j: Integer;
  Piece: TChessPiece;
  Value: Integer;
begin
  Result := 0;
  
  for i := 0 to 7 do
    for j := 0 to 7 do
    begin
      Piece := Board[i, j];
      if Piece.PieceType <> ptNone then
      begin
        Value := GetPieceValue(Piece.PieceType);
        
        // 位置による評価（簡易版）
        // 中央の駒にボーナス
        if (i >= 2) and (i <= 5) and (j >= 2) and (j <= 5) then
          Value := Value + 10;
        
        if Piece.Color = Color then
          Result := Result + Value
        else
          Result := Result - Value;
      end;
    end;
end;

function TChessAI.Minimax(Game: TChessGame; Depth: Integer; Alpha, Beta: Integer; 
                          Maximizing: Boolean): Integer;
var
  Moves: TList;
  i: Integer;
  Move: ^TMove;
  TestGame: TChessGame;
  Score: Integer;
  BestScore: Integer;
  CurrentColor: TPieceColor;
begin
  // 終端条件
  if Depth = 0 then
  begin
    if Maximizing then
      Result := EvaluateBoard(Game.GetBoard, pcBlack)
    else
      Result := EvaluateBoard(Game.GetBoard, pcWhite);
    Exit;
  end;
  
  if Maximizing then
    CurrentColor := pcBlack
  else
    CurrentColor := pcWhite;
  
  Moves := Game.GetAllValidMoves(CurrentColor);
  
  if Moves.Count = 0 then
  begin
    // チェックメイトまたはステイルメイト
    if Game.IsInCheck(CurrentColor) then
    begin
      if Maximizing then
        Result := -20000 + Depth  // 早くチェックメイトするほど良い
      else
        Result := 20000 - Depth;
    end
    else
      Result := 0; // ステイルメイト
    Moves.Free;
    Exit;
  end;
  
  if Maximizing then
  begin
    BestScore := -30000;
    for i := 0 to Moves.Count - 1 do
    begin
      Move := Moves[i];
      TestGame := TChessGame.Create;
      // 現在の盤面をコピー（簡易版のため、実際にはGameをクローンする必要がある）
      // ここでは簡略化のため、実際のゲームでMoveを試す
      TestGame.Free;
      
      // 簡易版：実際の実装では、ゲームの状態を保存/復元する必要がある
      // ここでは評価値のみを返す
      Score := EvaluateBoard(Game.GetBoard, pcBlack);
      if Score > BestScore then
        BestScore := Score;
      
      if BestScore >= Beta then
        Break; // ベータカット
      if BestScore > Alpha then
        Alpha := BestScore;
    end;
    Result := BestScore;
  end
  else
  begin
    BestScore := 30000;
    for i := 0 to Moves.Count - 1 do
    begin
      Move := Moves[i];
      Score := EvaluateBoard(Game.GetBoard, pcWhite);
      if Score < BestScore then
        BestScore := Score;
      
      if BestScore <= Alpha then
        Break; // アルファカット
      if BestScore < Beta then
        Beta := BestScore;
    end;
    Result := BestScore;
  end;
  
  // メモリクリーンアップ
  for i := 0 to Moves.Count - 1 do
  begin
    Move := Moves[i];
    Dispose(Move);
  end;
  Moves.Free;
end;

function TChessAI.GetBestMove(Game: TChessGame; Color: TPieceColor; Depth: Integer): TMove;
var
  Moves: TList;
  i: Integer;
  Move: ^TMove;
  BestMove: TMove;
  BestScore: Integer;
  Score: Integer;
  Board: TChessBoard;
  TargetPiece: TChessPiece;
begin
  // デフォルトの移動（無効な移動）
  BestMove.FromRow := -1;
  BestMove.FromCol := -1;
  BestMove.ToRow := -1;
  BestMove.ToCol := -1;
  
  Moves := Game.GetAllValidMoves(Color);
  
  if Moves.Count = 0 then
  begin
    Moves.Free;
    Exit;
  end;
  
  BestScore := -30000;
  if Color = pcWhite then
    BestScore := 30000;
  
  Board := Game.GetBoard;
  
  for i := 0 to Moves.Count - 1 do
  begin
    Move := Moves[i];
    
    // 移動後の評価を計算
    TargetPiece := Board[Move^.ToRow, Move^.ToCol];
    // 移動をシミュレート
    Board[Move^.ToRow, Move^.ToCol] := Board[Move^.FromRow, Move^.FromCol];
    Board[Move^.FromRow, Move^.FromCol].PieceType := ptNone;
    
    Score := EvaluateBoard(Board, Color);
    
    // 取った駒の価値を追加
    if TargetPiece.PieceType <> ptNone then
    begin
      if Color = pcBlack then
        Score := Score + GetPieceValue(TargetPiece.PieceType)
      else
        Score := Score - GetPieceValue(TargetPiece.PieceType);
    end;
    
    // 元に戻す
    Board[Move^.FromRow, Move^.FromCol] := Board[Move^.ToRow, Move^.ToCol];
    Board[Move^.ToRow, Move^.ToCol] := TargetPiece;
    
    if Color = pcBlack then
    begin
      if Score > BestScore then
      begin
        BestScore := Score;
        BestMove := Move^;
      end;
    end
    else
    begin
      if Score < BestScore then
      begin
        BestScore := Score;
        BestMove := Move^;
      end;
    end;
  end;
  
  // メモリクリーンアップ
  for i := 0 to Moves.Count - 1 do
  begin
    Move := Moves[i];
    Dispose(Move);
  end;
  Moves.Free;
  
  Result := BestMove;
end;

end.

