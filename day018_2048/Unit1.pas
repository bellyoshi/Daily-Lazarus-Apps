unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, LCLType;

type
  // 盤面の型定義（4x4、0は空マス）
  TBoard = array[0..3, 0..3] of Integer;

  { TForm1 }

  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormPaint(Sender: TObject);
  private
    FBoard: TBoard;           // ゲーム盤面
    FGameWon: Boolean;        // 勝利フラグ
    FGameOver: Boolean;       // ゲームオーバーフラグ
    
    // ゲームロジック
    procedure InitializeGame; // ゲーム初期化
    procedure AddRandomTile;  // ランダムな位置に新タイルを追加
    function MoveLeft: Boolean; // 左移動（戻り値：移動があったか）
    function MoveRight: Boolean; // 右移動
    function MoveUp: Boolean;   // 上移動
    function MoveDown: Boolean;  // 下移動
    function CanMove: Boolean;   // 移動可能かチェック
    function CheckWin: Boolean;  // 勝利条件チェック（2048出現）
    
    // 盤面操作（左移動を基準に他方向を実装）
    procedure RotateBoard90;   // 盤面を90度回転（時計回り）
    procedure RotateBoard180;  // 盤面を180度回転
    procedure RotateBoard270;  // 盤面を270度回転（反時計回り90度）
    procedure FlipHorizontal;  // 盤面を水平反転
    
    // 描画処理
    procedure DrawBoard;       // 盤面を描画
    procedure DrawTile(X, Y, Value: Integer); // 個別のタイルを描画
    function GetTileColor(Value: Integer): TColor; // タイルの色を取得
    function GetTileTextColor(Value: Integer): TColor; // テキストの色を取得
    
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // フォームの設定
  Caption := '2048';
  Width := 500;
  Height := 600;
  KeyPreview := True; // キーイベントを受け取るために必要
  
  // ゲーム初期化
  InitializeGame;
end;

// ゲーム初期化
procedure TForm1.InitializeGame;
var
  i, j: Integer;
begin
  // 盤面を0で初期化（全て空マス）
  for i := 0 to 3 do
    for j := 0 to 3 do
      FBoard[i, j] := 0;
  
  FGameWon := False;
  FGameOver := False;
  
  // 初期タイルを2つ追加
  AddRandomTile;
  AddRandomTile;
  
  Invalidate; // 再描画
end;

// ランダムな空マスに新タイルを追加（90%で2、10%で4）
procedure TForm1.AddRandomTile;
var
  EmptyCells: array[0..15] of record X, Y: Integer; end;
  EmptyCount, i, j, RandomIndex: Integer;
  NewValue: Integer;
begin
  // 空マスをリストアップ
  EmptyCount := 0;
  for i := 0 to 3 do
    for j := 0 to 3 do
      if FBoard[i, j] = 0 then
      begin
        EmptyCells[EmptyCount].X := i;
        EmptyCells[EmptyCount].Y := j;
        Inc(EmptyCount);
      end;
  
  // 空マスがない場合は何もしない
  if EmptyCount = 0 then
    Exit;
  
  // ランダムな空マスを選択
  RandomIndex := Random(EmptyCount);
  
  // 新タイルの値（90%で2、10%で4）
  if Random(100) < 90 then
    NewValue := 2
  else
    NewValue := 4;
  
  // タイルを配置
  FBoard[EmptyCells[RandomIndex].X, EmptyCells[RandomIndex].Y] := NewValue;
end;

// 左移動ロジック（基準となる実装）
function TForm1.MoveLeft: Boolean;
var
  i, j, k: Integer;
  Merged: array[0..3] of Boolean; // 各行で既に合体したか
  NewBoard: TBoard;
  Moved: Boolean;
begin
  Moved := False;
  NewBoard := FBoard; // 作業用コピー
  
  // 各行を処理
  for i := 0 to 3 do
  begin
    // 合体フラグをリセット
    for j := 0 to 3 do
      Merged[j] := False;
    
    // 左詰め処理
    k := 0; // 新しい位置のインデックス
    for j := 0 to 3 do
    begin
      if NewBoard[i, j] <> 0 then
      begin
        // 同じ数字で未合体のタイルと合体できるかチェック
        if (k > 0) and 
           (NewBoard[i, k - 1] = NewBoard[i, j]) and 
           (not Merged[k - 1]) then
        begin
          // 合体
          NewBoard[i, k - 1] := NewBoard[i, k - 1] * 2;
          Merged[k - 1] := True;
          Moved := True;
          
          // 勝利条件チェック
          if NewBoard[i, k - 1] = 2048 then
            FGameWon := True;
        end
        else
        begin
          // 移動
          if k <> j then
            Moved := True;
          NewBoard[i, k] := NewBoard[i, j];
          Inc(k);
        end;
      end;
    end;
    
    // 残りを空マスで埋める
    while k < 4 do
    begin
      NewBoard[i, k] := 0;
      Inc(k);
    end;
  end;
  
  // 盤面を更新
  FBoard := NewBoard;
  Result := Moved;
end;

// 右移動（水平反転→左移動→水平反転）
function TForm1.MoveRight: Boolean;
begin
  FlipHorizontal;
  Result := MoveLeft;
  FlipHorizontal;
end;

// 上移動（270度回転→左移動→90度回転）
function TForm1.MoveUp: Boolean;
begin
  RotateBoard270;
  Result := MoveLeft;
  RotateBoard90;
end;

// 下移動（90度回転→左移動→270度回転）
function TForm1.MoveDown: Boolean;
begin
  RotateBoard90;
  Result := MoveLeft;
  RotateBoard270;
end;

// 盤面を90度回転（時計回り）
procedure TForm1.RotateBoard90;
var
  i, j: Integer;
  Temp: TBoard;
begin
  Temp := FBoard;
  for i := 0 to 3 do
    for j := 0 to 3 do
      FBoard[j, 3 - i] := Temp[i, j];
end;

// 盤面を180度回転
procedure TForm1.RotateBoard180;
begin
  RotateBoard90;
  RotateBoard90;
end;

// 盤面を270度回転（反時計回り90度）
procedure TForm1.RotateBoard270;
begin
  RotateBoard90;
  RotateBoard90;
  RotateBoard90;
end;

// 盤面を水平反転
procedure TForm1.FlipHorizontal;
var
  i, j: Integer;
  Temp: Integer;
begin
  for i := 0 to 3 do
    for j := 0 to 1 do
    begin
      Temp := FBoard[i, j];
      FBoard[i, j] := FBoard[i, 3 - j];
      FBoard[i, 3 - j] := Temp;
    end;
end;

// 移動可能かチェック（全方向を試す）
function TForm1.CanMove: Boolean;
var
  i, j: Integer;
begin
  // 空マスがあるかチェック
  for i := 0 to 3 do
    for j := 0 to 3 do
      if FBoard[i, j] = 0 then
      begin
        Result := True;
        Exit;
      end;
  
  // 隣接する同じ数字のタイルがあるかチェック
  for i := 0 to 3 do
    for j := 0 to 3 do
    begin
      // 右隣
      if (j < 3) and (FBoard[i, j] = FBoard[i, j + 1]) then
      begin
        Result := True;
        Exit;
      end;
      // 下隣
      if (i < 3) and (FBoard[i, j] = FBoard[i + 1, j]) then
      begin
        Result := True;
        Exit;
      end;
    end;
  
  Result := False;
end;

// 勝利条件チェック（2048が出現）
function TForm1.CheckWin: Boolean;
var
  i, j: Integer;
begin
  for i := 0 to 3 do
    for j := 0 to 3 do
      if FBoard[i, j] = 2048 then
      begin
        Result := True;
        Exit;
      end;
  Result := False;
end;

// キー入力処理
procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Moved: Boolean;
begin
  // ゲームオーバー時は何もしない
  if FGameOver then
    Exit;
  
  Moved := False;
  
  // 矢印キーで移動
  case Key of
    VK_LEFT, VK_A:
      Moved := MoveLeft;
    VK_RIGHT, VK_D:
      Moved := MoveRight;
    VK_UP, VK_W:
      Moved := MoveUp;
    VK_DOWN, VK_S:
      Moved := MoveDown;
  end;
  
  // 移動があった場合のみ新タイルを追加
  if Moved then
  begin
    AddRandomTile;
    
    // 勝利条件チェック
    if CheckWin and not FGameWon then
    begin
      FGameWon := True;
      ShowMessage('2048達成！おめでとうございます！');
    end;
    
    // ゲームオーバー条件チェック
    if not CanMove then
    begin
      FGameOver := True;
      ShowMessage('ゲームオーバー！');
    end;
    
    Invalidate; // 再描画
  end;
end;

// 描画処理
procedure TForm1.FormPaint(Sender: TObject);
begin
  DrawBoard;
end;

// 盤面を描画
procedure TForm1.DrawBoard;
const
  CELL_SIZE = 100;      // セルサイズ
  CELL_MARGIN = 10;     // セル間のマージン
  BOARD_OFFSET_X = 50;  // 盤面のXオフセット
  BOARD_OFFSET_Y = 50;  // 盤面のYオフセット
var
  i, j: Integer;
  X, Y: Integer;
begin
  // 背景をクリア
  Canvas.Brush.Color := clBtnFace;
  Canvas.FillRect(0, 0, Width, Height);
  
  // 盤面の背景
  Canvas.Brush.Color := $BBADA0; // 2048の標準的な背景色
  Canvas.FillRect(
    BOARD_OFFSET_X - CELL_MARGIN,
    BOARD_OFFSET_Y - CELL_MARGIN,
    BOARD_OFFSET_X + 4 * (CELL_SIZE + CELL_MARGIN),
    BOARD_OFFSET_Y + 4 * (CELL_SIZE + CELL_MARGIN)
  );
  
  // 各タイルを描画
  for i := 0 to 3 do
    for j := 0 to 3 do
    begin
      X := BOARD_OFFSET_X + j * (CELL_SIZE + CELL_MARGIN);
      Y := BOARD_OFFSET_Y + i * (CELL_SIZE + CELL_MARGIN);
      DrawTile(X, Y, FBoard[i, j]);
    end;
  
  // ゲーム状態の表示
  Canvas.Font.Size := 16;
  Canvas.Font.Style := [fsBold];
  if FGameWon then
  begin
    Canvas.Font.Color := clGreen;
    Canvas.TextOut(BOARD_OFFSET_X, BOARD_OFFSET_Y + 4 * (CELL_SIZE + CELL_MARGIN) + 20, '勝利！');
  end
  else if FGameOver then
  begin
    Canvas.Font.Color := clRed;
    Canvas.TextOut(BOARD_OFFSET_X, BOARD_OFFSET_Y + 4 * (CELL_SIZE + CELL_MARGIN) + 20, 'ゲームオーバー');
  end;
  
  // 操作説明
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [];
  Canvas.Font.Color := clBlack;
  Canvas.TextOut(BOARD_OFFSET_X, BOARD_OFFSET_Y + 4 * (CELL_SIZE + CELL_MARGIN) + 50, 
    '矢印キーまたはWASDで操作');
end;

// 個別のタイルを描画
procedure TForm1.DrawTile(X, Y, Value: Integer);
const
  CELL_SIZE = 100;
var
  TileColor, TextColor: TColor;
  TileText: String;
  TextWidth, TextHeight: Integer;
begin
  // タイルの色を取得
  TileColor := GetTileColor(Value);
  TextColor := GetTileTextColor(Value);
  
  // タイルの背景を描画
  Canvas.Brush.Color := TileColor;
  Canvas.Pen.Color := TileColor;
  Canvas.RoundRect(X, Y, X + CELL_SIZE, Y + CELL_SIZE, 5, 5);
  
  // テキストを描画（空マスでない場合）
  if Value <> 0 then
  begin
    TileText := IntToStr(Value);
    Canvas.Font.Size := 24;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := TextColor;
    
    // テキストを中央に配置
    TextWidth := Canvas.TextWidth(TileText);
    TextHeight := Canvas.TextHeight(TileText);
    Canvas.TextOut(
      X + (CELL_SIZE - TextWidth) div 2,
      Y + (CELL_SIZE - TextHeight) div 2,
      TileText
    );
  end;
end;

// タイルの色を取得（値に応じた色）
function TForm1.GetTileColor(Value: Integer): TColor;
begin
  case Value of
    0: Result := $CDC1B4;      // 空マス
    2: Result := $EEE4DA;
    4: Result := $EDE0C8;
    8: Result := $F2B179;
    16: Result := $F59563;
    32: Result := $F67C5F;
    64: Result := $F65E3B;
    128: Result := $EDCF72;
    256: Result := $EDCC61;
    512: Result := $EDC850;
    1024: Result := $EDC53F;
    2048: Result := $EDC22E;
    else Result := $3C3A32;   // それ以上
  end;
end;

// テキストの色を取得
function TForm1.GetTileTextColor(Value: Integer): TColor;
begin
  if Value <= 4 then
    Result := $776E65  // 暗い色
  else
    Result := $F9F6F2; // 明るい色
end;

end.
