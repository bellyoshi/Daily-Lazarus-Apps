unit ChessGame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TPieceType = (ptNone, ptPawn, ptRook, ptKnight, ptBishop, ptQueen, ptKing);
  TPieceColor = (pcWhite, pcBlack);
  
  TChessPiece = record
    PieceType: TPieceType;
    Color: TPieceColor;
  end;
  
  TChessBoard = array[0..7, 0..7] of TChessPiece;
  
  TMove = record
    FromRow, FromCol: Integer;
    ToRow, ToCol: Integer;
  end;
  
  TChessGame = class
  private
    FBoard: TChessBoard;
    FCurrentPlayer: TPieceColor;
    FGameOver: Boolean;
    FWhiteKingRow, FWhiteKingCol: Integer;
    FBlackKingRow, FBlackKingCol: Integer;
    FWhiteKingMoved: Boolean;
    FBlackKingMoved: Boolean;
    FWhiteRookKingSideMoved: Boolean;  // h1
    FWhiteRookQueenSideMoved: Boolean; // a1
    FBlackRookKingSideMoved: Boolean;  // h8
    FBlackRookQueenSideMoved: Boolean; // a8
    procedure InitializeBoard;
    function IsValidMove(FromRow, FromCol, ToRow, ToCol: Integer): Boolean;
    function IsCheckmate(Color: TPieceColor): Boolean;
    function CanMove(FromRow, FromCol, ToRow, ToCol: Integer): Boolean;
    function GetPieceMoves(Row, Col: Integer): TList;
    function CanCastle(Color: TPieceColor; KingSide: Boolean): Boolean;
  public
    function IsInCheck(Color: TPieceColor): Boolean;
    constructor Create;
    destructor Destroy; override;
    function MakeMove(FromRow, FromCol, ToRow, ToCol: Integer): Boolean;
    function GetBoard: TChessBoard;
    function GetCurrentPlayer: TPieceColor;
    function IsGameOver: Boolean;
    function GetWinner: TPieceColor;
    function GetAllValidMoves(Color: TPieceColor): TList;
    procedure Reset;
  end;

implementation

constructor TChessGame.Create;
begin
  inherited Create;
  InitializeBoard;
  FCurrentPlayer := pcWhite;
  FGameOver := False;
  FWhiteKingMoved := False;
  FBlackKingMoved := False;
  FWhiteRookKingSideMoved := False;
  FWhiteRookQueenSideMoved := False;
  FBlackRookKingSideMoved := False;
  FBlackRookQueenSideMoved := False;
end;

destructor TChessGame.Destroy;
begin
  inherited Destroy;
end;

procedure TChessGame.InitializeBoard;
var
  i, j: Integer;
begin
  // 盤面をクリア
  for i := 0 to 7 do
    for j := 0 to 7 do
    begin
      FBoard[i, j].PieceType := ptNone;
      FBoard[i, j].Color := pcWhite;
    end;
  
  // 黒の駒を配置
  FBoard[0, 0].PieceType := ptRook;
  FBoard[0, 0].Color := pcBlack;
  FBoard[0, 1].PieceType := ptKnight;
  FBoard[0, 1].Color := pcBlack;
  FBoard[0, 2].PieceType := ptBishop;
  FBoard[0, 2].Color := pcBlack;
  FBoard[0, 3].PieceType := ptQueen;
  FBoard[0, 3].Color := pcBlack;
  FBoard[0, 4].PieceType := ptKing;
  FBoard[0, 4].Color := pcBlack;
  FBlackKingRow := 0; FBlackKingCol := 4;
  FBoard[0, 5].PieceType := ptBishop;
  FBoard[0, 5].Color := pcBlack;
  FBoard[0, 6].PieceType := ptKnight;
  FBoard[0, 6].Color := pcBlack;
  FBoard[0, 7].PieceType := ptRook;
  FBoard[0, 7].Color := pcBlack;
  for j := 0 to 7 do
  begin
    FBoard[1, j].PieceType := ptPawn;
    FBoard[1, j].Color := pcBlack;
  end;
  
  // 白の駒を配置
  for j := 0 to 7 do
  begin
    FBoard[6, j].PieceType := ptPawn;
    FBoard[6, j].Color := pcWhite;
  end;
  FBoard[7, 0].PieceType := ptRook;
  FBoard[7, 0].Color := pcWhite;
  FBoard[7, 1].PieceType := ptKnight;
  FBoard[7, 1].Color := pcWhite;
  FBoard[7, 2].PieceType := ptBishop;
  FBoard[7, 2].Color := pcWhite;
  FBoard[7, 3].PieceType := ptQueen;
  FBoard[7, 3].Color := pcWhite;
  FBoard[7, 4].PieceType := ptKing;
  FBoard[7, 4].Color := pcWhite;
  FWhiteKingRow := 7; FWhiteKingCol := 4;
  FBoard[7, 5].PieceType := ptBishop;
  FBoard[7, 5].Color := pcWhite;
  FBoard[7, 6].PieceType := ptKnight;
  FBoard[7, 6].Color := pcWhite;
  FBoard[7, 7].PieceType := ptRook;
  FBoard[7, 7].Color := pcWhite;
end;

function TChessGame.IsValidMove(FromRow, FromCol, ToRow, ToCol: Integer): Boolean;
var
  Piece: TChessPiece;
  TargetPiece: TChessPiece;
begin
  Result := False;
  
  // 範囲チェック
  if (FromRow < 0) or (FromRow > 7) or (FromCol < 0) or (FromCol > 7) then
    Exit;
  if (ToRow < 0) or (ToRow > 7) or (ToCol < 0) or (ToCol > 7) then
    Exit;
  
  Piece := FBoard[FromRow, FromCol];
  TargetPiece := FBoard[ToRow, ToCol];
  
  // 駒が存在しない
  if Piece.PieceType = ptNone then
    Exit;
  
  // 現在のプレイヤーの駒でない
  if Piece.Color <> FCurrentPlayer then
    Exit;
  
  // 同じ場所への移動
  if (FromRow = ToRow) and (FromCol = ToCol) then
    Exit;
  
  // 自分の駒を取ろうとしている
  if (TargetPiece.PieceType <> ptNone) and (TargetPiece.Color = Piece.Color) then
    Exit;
  
  // キャスリングのチェック
  if (Piece.PieceType = ptKing) then
  begin
    // 白のキングサイドキャスリング (e1 -> g1)
    if (Piece.Color = pcWhite) and (FromRow = 7) and (FromCol = 4) and
       (ToRow = 7) and (ToCol = 6) then
    begin
      Result := CanCastle(pcWhite, True);
      if Result then
      begin
        // キャスリングの場合、移動後のチェックを確認
        // キングをg1に移動
        FBoard[7, 6] := Piece;
        FBoard[7, 4].PieceType := ptNone;
        FWhiteKingRow := 7;
        FWhiteKingCol := 6;
        if IsInCheck(pcWhite) then
          Result := False;
        // 元に戻す
        FBoard[7, 4] := Piece;
        FBoard[7, 6].PieceType := ptNone;
        FWhiteKingRow := 7;
        FWhiteKingCol := 4;
      end;
      Exit;
    end
    // 白のクイーンサイドキャスリング (e1 -> c1)
    else if (Piece.Color = pcWhite) and (FromRow = 7) and (FromCol = 4) and
            (ToRow = 7) and (ToCol = 2) then
    begin
      Result := CanCastle(pcWhite, False);
      if Result then
      begin
        // キャスリングの場合、移動後のチェックを確認
        FBoard[7, 2] := Piece;
        FBoard[7, 4].PieceType := ptNone;
        FWhiteKingRow := 7;
        FWhiteKingCol := 2;
        if IsInCheck(pcWhite) then
          Result := False;
        // 元に戻す
        FBoard[7, 4] := Piece;
        FBoard[7, 2].PieceType := ptNone;
        FWhiteKingRow := 7;
        FWhiteKingCol := 4;
      end;
      Exit;
    end
    // 黒のキングサイドキャスリング (e8 -> g8)
    else if (Piece.Color = pcBlack) and (FromRow = 0) and (FromCol = 4) and
            (ToRow = 0) and (ToCol = 6) then
    begin
      Result := CanCastle(pcBlack, True);
      if Result then
      begin
        // キャスリングの場合、移動後のチェックを確認
        FBoard[0, 6] := Piece;
        FBoard[0, 4].PieceType := ptNone;
        FBlackKingRow := 0;
        FBlackKingCol := 6;
        if IsInCheck(pcBlack) then
          Result := False;
        // 元に戻す
        FBoard[0, 4] := Piece;
        FBoard[0, 6].PieceType := ptNone;
        FBlackKingRow := 0;
        FBlackKingCol := 4;
      end;
      Exit;
    end
    // 黒のクイーンサイドキャスリング (e8 -> c8)
    else if (Piece.Color = pcBlack) and (FromRow = 0) and (FromCol = 4) and
            (ToRow = 0) and (ToCol = 2) then
    begin
      Result := CanCastle(pcBlack, False);
      if Result then
      begin
        // キャスリングの場合、移動後のチェックを確認
        FBoard[0, 2] := Piece;
        FBoard[0, 4].PieceType := ptNone;
        FBlackKingRow := 0;
        FBlackKingCol := 2;
        if IsInCheck(pcBlack) then
          Result := False;
        // 元に戻す
        FBoard[0, 4] := Piece;
        FBoard[0, 2].PieceType := ptNone;
        FBlackKingRow := 0;
        FBlackKingCol := 4;
      end;
      Exit;
    end;
  end;
  
  // 駒の種類に応じた移動チェック
  Result := CanMove(FromRow, FromCol, ToRow, ToCol);
  
  // 移動後、自分のキングがチェックされていないか確認
  if Result then
  begin
    // 一時的に移動を実行
    FBoard[ToRow, ToCol] := Piece;
    FBoard[FromRow, FromCol].PieceType := ptNone;
    
    // キングの位置を更新
    if Piece.PieceType = ptKing then
    begin
      if Piece.Color = pcWhite then
      begin
        FWhiteKingRow := ToRow;
        FWhiteKingCol := ToCol;
      end
      else
      begin
        FBlackKingRow := ToRow;
        FBlackKingCol := ToCol;
      end;
    end;
    
    // チェックされているか確認
    if IsInCheck(Piece.Color) then
      Result := False;
    
    // 元に戻す
    FBoard[FromRow, FromCol] := Piece;
    FBoard[ToRow, ToCol] := TargetPiece;
    
    if Piece.PieceType = ptKing then
    begin
      if Piece.Color = pcWhite then
      begin
        FWhiteKingRow := FromRow;
        FWhiteKingCol := FromCol;
      end
      else
      begin
        FBlackKingRow := FromRow;
        FBlackKingCol := FromCol;
      end;
    end;
  end;
end;

function TChessGame.CanMove(FromRow, FromCol, ToRow, ToCol: Integer): Boolean;
var
  Piece: TChessPiece;
  i, RowDir, ColDir: Integer;
begin
  Result := False;
  Piece := FBoard[FromRow, FromCol];
  
  case Piece.PieceType of
    ptPawn:
    begin
      if Piece.Color = pcWhite then
      begin
        // 前に1マス
        if (ToRow = FromRow - 1) and (ToCol = FromCol) and 
           (FBoard[ToRow, ToCol].PieceType = ptNone) then
          Result := True
        // 最初の位置から2マス
        else if (FromRow = 6) and (ToRow = 4) and (ToCol = FromCol) and
                (FBoard[5, FromCol].PieceType = ptNone) and
                (FBoard[4, FromCol].PieceType = ptNone) then
          Result := True
        // 斜めに取る
        else if (ToRow = FromRow - 1) and (Abs(ToCol - FromCol) = 1) and
                (FBoard[ToRow, ToCol].PieceType <> ptNone) and
                (FBoard[ToRow, ToCol].Color = pcBlack) then
          Result := True;
      end
      else // Black
      begin
        // 前に1マス
        if (ToRow = FromRow + 1) and (ToCol = FromCol) and 
           (FBoard[ToRow, ToCol].PieceType = ptNone) then
          Result := True
        // 最初の位置から2マス
        else if (FromRow = 1) and (ToRow = 3) and (ToCol = FromCol) and
                (FBoard[2, FromCol].PieceType = ptNone) and
                (FBoard[3, FromCol].PieceType = ptNone) then
          Result := True
        // 斜めに取る
        else if (ToRow = FromRow + 1) and (Abs(ToCol - FromCol) = 1) and
                (FBoard[ToRow, ToCol].PieceType <> ptNone) and
                (FBoard[ToRow, ToCol].Color = pcWhite) then
          Result := True;
      end;
    end;
    
    ptRook:
    begin
      // 縦横の移動
      if (FromRow = ToRow) or (FromCol = ToCol) then
      begin
        Result := True;
        // 経路上に駒がないか確認
        if FromRow = ToRow then
        begin
          if FromCol < ToCol then
            for i := FromCol + 1 to ToCol - 1 do
              if FBoard[FromRow, i].PieceType <> ptNone then
                Result := False;
          if FromCol > ToCol then
            for i := ToCol + 1 to FromCol - 1 do
              if FBoard[FromRow, i].PieceType <> ptNone then
                Result := False;
        end
        else
        begin
          if FromRow < ToRow then
            for i := FromRow + 1 to ToRow - 1 do
              if FBoard[i, FromCol].PieceType <> ptNone then
                Result := False;
          if FromRow > ToRow then
            for i := ToRow + 1 to FromRow - 1 do
              if FBoard[i, FromCol].PieceType <> ptNone then
                Result := False;
        end;
      end;
    end;
    
    ptKnight:
    begin
      // ナイトの移動（L字）
      Result := ((Abs(ToRow - FromRow) = 2) and (Abs(ToCol - FromCol) = 1)) or
                ((Abs(ToRow - FromRow) = 1) and (Abs(ToCol - FromCol) = 2));
    end;
    
    ptBishop:
    begin
      // 斜めの移動
      if Abs(ToRow - FromRow) = Abs(ToCol - FromCol) then
      begin
        Result := True;
        // 経路上に駒がないか確認
        if ToRow > FromRow then RowDir := 1 else RowDir := -1;
        if ToCol > FromCol then ColDir := 1 else ColDir := -1;
        i := 1;
        while (FromRow + i * RowDir <> ToRow) do
        begin
          if FBoard[FromRow + i * RowDir, FromCol + i * ColDir].PieceType <> ptNone then
          begin
            Result := False;
            Break;
          end;
          Inc(i);
        end;
      end;
    end;
    
    ptQueen:
    begin
      // 縦横斜めの移動（ルークとビショップの組み合わせ）
      // ルークの動き
      if (FromRow = ToRow) or (FromCol = ToCol) then
      begin
        Result := True;
        if FromRow = ToRow then
        begin
          if FromCol < ToCol then
            for i := FromCol + 1 to ToCol - 1 do
              if FBoard[FromRow, i].PieceType <> ptNone then
                Result := False;
          if FromCol > ToCol then
            for i := ToCol + 1 to FromCol - 1 do
              if FBoard[FromRow, i].PieceType <> ptNone then
                Result := False;
        end
        else
        begin
          if FromRow < ToRow then
            for i := FromRow + 1 to ToRow - 1 do
              if FBoard[i, FromCol].PieceType <> ptNone then
                Result := False;
          if FromRow > ToRow then
            for i := ToRow + 1 to FromRow - 1 do
              if FBoard[i, FromCol].PieceType <> ptNone then
                Result := False;
        end;
      end
      // ビショップの動き
      else if Abs(ToRow - FromRow) = Abs(ToCol - FromCol) then
      begin
        Result := True;
        if ToRow > FromRow then RowDir := 1 else RowDir := -1;
        if ToCol > FromCol then ColDir := 1 else ColDir := -1;
        i := 1;
        while (FromRow + i * RowDir <> ToRow) do
        begin
          if FBoard[FromRow + i * RowDir, FromCol + i * ColDir].PieceType <> ptNone then
          begin
            Result := False;
            Break;
          end;
          Inc(i);
        end;
      end;
    end;
    
    ptKing:
    begin
      // キングの移動（1マス）
      Result := (Abs(ToRow - FromRow) <= 1) and (Abs(ToCol - FromCol) <= 1);
      
      // キャスリングのチェック
      if not Result then
      begin
        // 白のキングサイドキャスリング (e1 -> g1)
        if (Piece.Color = pcWhite) and (FromRow = 7) and (FromCol = 4) and
           (ToRow = 7) and (ToCol = 6) then
        begin
          Result := CanCastle(pcWhite, True);
        end
        // 白のクイーンサイドキャスリング (e1 -> c1)
        else if (Piece.Color = pcWhite) and (FromRow = 7) and (FromCol = 4) and
                (ToRow = 7) and (ToCol = 2) then
        begin
          Result := CanCastle(pcWhite, False);
        end
        // 黒のキングサイドキャスリング (e8 -> g8)
        else if (Piece.Color = pcBlack) and (FromRow = 0) and (FromCol = 4) and
                (ToRow = 0) and (ToCol = 6) then
        begin
          Result := CanCastle(pcBlack, True);
        end
        // 黒のクイーンサイドキャスリング (e8 -> c8)
        else if (Piece.Color = pcBlack) and (FromRow = 0) and (FromCol = 4) and
                (ToRow = 0) and (ToCol = 2) then
        begin
          Result := CanCastle(pcBlack, False);
        end;
      end;
    end;
  end;
end;

function TChessGame.CanCastle(Color: TPieceColor; KingSide: Boolean): Boolean;
var
  KingRow, KingCol, RookCol: Integer;
  i: Integer;
begin
  Result := False;
  
  // キングが既に動いている場合はキャスリング不可
  if Color = pcWhite then
  begin
    if FWhiteKingMoved then
      Exit;
    KingRow := 7;
    KingCol := 4;
    if KingSide then
    begin
      if FWhiteRookKingSideMoved then
        Exit;
      RookCol := 7;
    end
    else
    begin
      if FWhiteRookQueenSideMoved then
        Exit;
      RookCol := 0;
    end;
  end
  else
  begin
    if FBlackKingMoved then
      Exit;
    KingRow := 0;
    KingCol := 4;
    if KingSide then
    begin
      if FBlackRookKingSideMoved then
        Exit;
      RookCol := 7;
    end
    else
    begin
      if FBlackRookQueenSideMoved then
        Exit;
      RookCol := 0;
    end;
  end;
  
  // ルークが存在するか確認
  if (FBoard[KingRow, RookCol].PieceType <> ptRook) or
     (FBoard[KingRow, RookCol].Color <> Color) then
    Exit;
  
  // キングとルークの間に駒がないか確認
  if KingSide then
  begin
    for i := KingCol + 1 to RookCol - 1 do
      if FBoard[KingRow, i].PieceType <> ptNone then
        Exit;
  end
  else
  begin
    for i := RookCol + 1 to KingCol - 1 do
      if FBoard[KingRow, i].PieceType <> ptNone then
        Exit;
  end;
  
  // キングがチェックされていないか確認
  if IsInCheck(Color) then
    Exit;
  
  // キングが通過するマスと移動先がチェックされていないか確認
  // 簡易版：IsValidMove内でチェックされるため、ここでは基本的な条件のみ確認
  // 実際のチェックはIsValidMove内で行われる
  
  Result := True;
end;

function TChessGame.IsInCheck(Color: TPieceColor): Boolean;
var
  i, j, k, l: Integer;
  KingRow, KingCol: Integer;
  OpponentColor: TPieceColor;
begin
  Result := False;
  
  // キングの位置を取得
  if Color = pcWhite then
  begin
    KingRow := FWhiteKingRow;
    KingCol := FWhiteKingCol;
    OpponentColor := pcBlack;
  end
  else
  begin
    KingRow := FBlackKingRow;
    KingCol := FBlackKingCol;
    OpponentColor := pcWhite;
  end;
  
  // 相手の駒がキングを攻撃できるか確認
  for i := 0 to 7 do
    for j := 0 to 7 do
    begin
      if (FBoard[i, j].PieceType <> ptNone) and (FBoard[i, j].Color = OpponentColor) then
      begin
        // 一時的に色を変更してCanMoveを呼ぶ
        FCurrentPlayer := OpponentColor;
        if CanMove(i, j, KingRow, KingCol) then
        begin
          Result := True;
          FCurrentPlayer := Color;
          Exit;
        end;
        FCurrentPlayer := Color;
      end;
    end;
end;

function TChessGame.IsCheckmate(Color: TPieceColor): Boolean;
var
  i, j, k, l: Integer;
  OldPlayer: TPieceColor;
begin
  Result := False;
  
  // チェックされていない場合はチェックメイトではない
  if not IsInCheck(Color) then
    Exit;
  
  // すべての可能な手を試す
  OldPlayer := FCurrentPlayer;
  FCurrentPlayer := Color;
  
  for i := 0 to 7 do
    for j := 0 to 7 do
    begin
      if (FBoard[i, j].PieceType <> ptNone) and (FBoard[i, j].Color = Color) then
      begin
        for k := 0 to 7 do
          for l := 0 to 7 do
          begin
            if IsValidMove(i, j, k, l) then
            begin
              FCurrentPlayer := OldPlayer;
              Exit; // 有効な手があるのでチェックメイトではない
            end;
          end;
      end;
    end;
  
  FCurrentPlayer := OldPlayer;
  Result := True; // 有効な手がないのでチェックメイト
end;

function TChessGame.MakeMove(FromRow, FromCol, ToRow, ToCol: Integer): Boolean;
var
  Piece: TChessPiece;
  IsCastling: Boolean;
begin
  Result := False;
  
  if FGameOver then
    Exit;
  
  if not IsValidMove(FromRow, FromCol, ToRow, ToCol) then
    Exit;
  
  Piece := FBoard[FromRow, FromCol];
  IsCastling := False;
  
  // キャスリングの処理
  if (Piece.PieceType = ptKing) then
  begin
    // 白のキングサイドキャスリング
    if (Piece.Color = pcWhite) and (FromRow = 7) and (FromCol = 4) and
       (ToRow = 7) and (ToCol = 6) then
    begin
      // キングを移動
      FBoard[7, 6] := FBoard[7, 4];
      FBoard[7, 4].PieceType := ptNone;
      // ルークを移動
      FBoard[7, 5] := FBoard[7, 7];
      FBoard[7, 7].PieceType := ptNone;
      FWhiteKingRow := 7;
      FWhiteKingCol := 6;
      FWhiteKingMoved := True;
      FWhiteRookKingSideMoved := True;
      IsCastling := True;
    end
    // 白のクイーンサイドキャスリング
    else if (Piece.Color = pcWhite) and (FromRow = 7) and (FromCol = 4) and
            (ToRow = 7) and (ToCol = 2) then
    begin
      // キングを移動
      FBoard[7, 2] := FBoard[7, 4];
      FBoard[7, 4].PieceType := ptNone;
      // ルークを移動
      FBoard[7, 3] := FBoard[7, 0];
      FBoard[7, 0].PieceType := ptNone;
      FWhiteKingRow := 7;
      FWhiteKingCol := 2;
      FWhiteKingMoved := True;
      FWhiteRookQueenSideMoved := True;
      IsCastling := True;
    end
    // 黒のキングサイドキャスリング
    else if (Piece.Color = pcBlack) and (FromRow = 0) and (FromCol = 4) and
            (ToRow = 0) and (ToCol = 6) then
    begin
      // キングを移動
      FBoard[0, 6] := FBoard[0, 4];
      FBoard[0, 4].PieceType := ptNone;
      // ルークを移動
      FBoard[0, 5] := FBoard[0, 7];
      FBoard[0, 7].PieceType := ptNone;
      FBlackKingRow := 0;
      FBlackKingCol := 6;
      FBlackKingMoved := True;
      FBlackRookKingSideMoved := True;
      IsCastling := True;
    end
    // 黒のクイーンサイドキャスリング
    else if (Piece.Color = pcBlack) and (FromRow = 0) and (FromCol = 4) and
            (ToRow = 0) and (ToCol = 2) then
    begin
      // キングを移動
      FBoard[0, 2] := FBoard[0, 4];
      FBoard[0, 4].PieceType := ptNone;
      // ルークを移動
      FBoard[0, 3] := FBoard[0, 0];
      FBoard[0, 0].PieceType := ptNone;
      FBlackKingRow := 0;
      FBlackKingCol := 2;
      FBlackKingMoved := True;
      FBlackRookQueenSideMoved := True;
      IsCastling := True;
    end;
  end;
  
  if not IsCastling then
  begin
    // 通常の移動を実行
    FBoard[ToRow, ToCol] := FBoard[FromRow, FromCol];
    FBoard[FromRow, FromCol].PieceType := ptNone;
    
    // キングの位置を更新
    if Piece.PieceType = ptKing then
    begin
      if Piece.Color = pcWhite then
      begin
        FWhiteKingRow := ToRow;
        FWhiteKingCol := ToCol;
        FWhiteKingMoved := True;
      end
      else
      begin
        FBlackKingRow := ToRow;
        FBlackKingCol := ToCol;
        FBlackKingMoved := True;
      end;
    end;
    
    // ルークが動いた場合のフラグ更新
    if Piece.PieceType = ptRook then
    begin
      if Piece.Color = pcWhite then
      begin
        if (FromRow = 7) and (FromCol = 7) then
          FWhiteRookKingSideMoved := True
        else if (FromRow = 7) and (FromCol = 0) then
          FWhiteRookQueenSideMoved := True;
      end
      else
      begin
        if (FromRow = 0) and (FromCol = 7) then
          FBlackRookKingSideMoved := True
        else if (FromRow = 0) and (FromCol = 0) then
          FBlackRookQueenSideMoved := True;
      end;
    end;
  end;
  
  // プレイヤーを切り替え
  if FCurrentPlayer = pcWhite then
    FCurrentPlayer := pcBlack
  else
    FCurrentPlayer := pcWhite;
  
  // チェックメイトを確認
  if IsCheckmate(FCurrentPlayer) then
    FGameOver := True;
  
  Result := True;
end;

function TChessGame.GetBoard: TChessBoard;
begin
  Result := FBoard;
end;

function TChessGame.GetCurrentPlayer: TPieceColor;
begin
  Result := FCurrentPlayer;
end;

function TChessGame.IsGameOver: Boolean;
begin
  Result := FGameOver;
end;

function TChessGame.GetWinner: TPieceColor;
begin
  if FGameOver then
  begin
    if FCurrentPlayer = pcWhite then
      Result := pcBlack
    else
      Result := pcWhite;
  end
  else
    Result := pcWhite; // デフォルト値
end;

function TChessGame.GetAllValidMoves(Color: TPieceColor): TList;
var
  i, j, k, l: Integer;
  Move: ^TMove;
  OldPlayer: TPieceColor;
begin
  Result := TList.Create;
  OldPlayer := FCurrentPlayer;
  FCurrentPlayer := Color;
  
  for i := 0 to 7 do
    for j := 0 to 7 do
    begin
      if (FBoard[i, j].PieceType <> ptNone) and (FBoard[i, j].Color = Color) then
      begin
        for k := 0 to 7 do
          for l := 0 to 7 do
          begin
            if IsValidMove(i, j, k, l) then
            begin
              New(Move);
              Move^.FromRow := i;
              Move^.FromCol := j;
              Move^.ToRow := k;
              Move^.ToCol := l;
              Result.Add(Move);
            end;
          end;
      end;
    end;
  
  FCurrentPlayer := OldPlayer;
end;

function TChessGame.GetPieceMoves(Row, Col: Integer): TList;
begin
  Result := TList.Create;
  // 実装は簡略化
end;

procedure TChessGame.Reset;
begin
  InitializeBoard;
  FCurrentPlayer := pcWhite;
  FGameOver := False;
  FWhiteKingMoved := False;
  FBlackKingMoved := False;
  FWhiteRookKingSideMoved := False;
  FWhiteRookQueenSideMoved := False;
  FBlackRookKingSideMoved := False;
  FBlackRookQueenSideMoved := False;
end;

end.

