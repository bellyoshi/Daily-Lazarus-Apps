unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids;

type
  // セルの状態を表す型
  TCellState = (csEmpty, csFilled);  // csEmpty: 未確定（白）, csFilled: 塗りつぶし（黒）
  
  // ヒント用の整数配列
  TIntArray = array of Integer;
  
  // 盤面データ用の2次元配列
  TBoolBoard = array of array of Boolean;

  { TForm1 }

  TForm1 = class(TForm)
    DrawGrid1: TDrawGrid;
    procedure DrawGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure DrawGrid1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    // 盤面の状態を管理する2次元配列（10×10）
    FGrid: array[0..9, 0..9] of TCellState;
    
    // 行ヒントデータ（左側に表示される）配列の配列
    FRowHints: array[0..9] of TIntArray;
    
    // 列ヒントデータ（上側に表示される）配列の配列
    FColHints: array[0..9] of TIntArray;
    
    // ヒント列の幅（ピクセル）
    FHintColWidth: Integer;
    
    // ヒント行の高さ（ピクセル）
    FHintRowHeight: Integer;
    
    // 初期化処理
    procedure InitializeGrid;
    
    // 問題データの設定
    procedure SetupProblem;
    
    // ヒントの幅を計算して設定
    procedure CalculateHintSizes;
    
    // ヒント文字列を生成
    function FormatHint(const HintArray: TIntArray): String;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

// 正解データ
const
  Solution: array[0..9, 0..9] of Boolean = (
    (False,False,False,False,True ,False,False,False,False,False),
    (False,False,False,False,True ,False,False,False,False,False),
    (False,False,False,False,True ,False,False,False,False,False),
    (False,False,False,False,True ,False,False,False,False,False),
    (True ,True ,True ,True ,True ,True ,True ,True ,True ,True ),
    (False,False,False,False,True ,False,False,False,False,False),
    (False,False,False,False,True ,False,False,False,False,False),
    (False,False,False,False,True ,False,False,False,False,False),
    (False,False,False,False,True ,False,False,False,False,False),
    (False,False,False,False,True ,False,False,False,False,False)
  );

// 1行分のデータからヒント配列を生成
function MakeHintFromLine(const Line: array of Boolean): TIntArray;
var
  i, Count: Integer;
begin
  SetLength(Result, 0);
  Count := 0;

  for i := 0 to High(Line) do
  begin
    if Line[i] then
      Inc(Count)
    else
    begin
      if Count > 0 then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := Count;
        Count := 0;
      end;
    end;
  end;

  if Count > 0 then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Count;
  end;
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // フォーム作成時の初期化
  InitializeGrid;
  SetupProblem;
  CalculateHintSizes;
  
  // DrawGridの設定
  // 固定列1（左側のヒント）+ データ列10 = 合計11列
  // 固定行1（上側のヒント）+ データ行10 = 合計11行
  DrawGrid1.ColCount := 11;
  DrawGrid1.RowCount := 11;
  DrawGrid1.FixedCols := 1;
  DrawGrid1.FixedRows := 1;
  DrawGrid1.DefaultColWidth := 50;
  DrawGrid1.DefaultRowHeight := 50;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  // フォーム表示時にヒント列・行のサイズを設定
  // OnShowで設定することで、DrawGridが完全に初期化された後にサイズを調整できる
  DrawGrid1.ColWidths[0] := FHintColWidth;  // ヒント列の幅を設定
  DrawGrid1.RowHeights[0] := FHintRowHeight;  // ヒント行の高さを設定
end;

procedure TForm1.InitializeGrid;
var
  i, j: Integer;
begin
  // 盤面をすべて未確定（白）で初期化
  for i := 0 to 9 do
    for j := 0 to 9 do
      FGrid[i, j] := csEmpty;
end;

procedure TForm1.SetupProblem;
var
  i, j: Integer;
  Line: array[0..9] of Boolean;
  ColLine: array[0..9] of Boolean;
begin
  // 正解データから行ヒントを生成
  for i := 0 to 9 do
  begin
    for j := 0 to 9 do
      Line[j] := Solution[i, j];
    FRowHints[i] := MakeHintFromLine(Line);
  end;
  
  // 正解データから列ヒントを生成
  for j := 0 to 9 do
  begin
    for i := 0 to 9 do
      ColLine[i] := Solution[i, j];
    FColHints[j] := MakeHintFromLine(ColLine);
  end;
end;

procedure TForm1.CalculateHintSizes;
var
  i, j: Integer;
  MaxHintLength: Integer;
  MaxHintCount: Integer;
  TestText: String;
  TestWidth, TestHeight: Integer;
begin
  // ヒントの最大要素数を求める
  MaxHintCount := 0;
  for i := 0 to 9 do
  begin
    if Length(FRowHints[i]) > MaxHintCount then
      MaxHintCount := Length(FRowHints[i]);
    if Length(FColHints[i]) > MaxHintCount then
      MaxHintCount := Length(FColHints[i]);
  end;
  
  // ヒントの最大値を求める
  MaxHintLength := 0;
  for i := 0 to 9 do
  begin
    for j := 0 to High(FRowHints[i]) do
      if FRowHints[i][j] > MaxHintLength then
        MaxHintLength := FRowHints[i][j];
    for j := 0 to High(FColHints[i]) do
      if FColHints[i][j] > MaxHintLength then
        MaxHintLength := FColHints[i][j];
  end;
  
  // テスト用の文字列を作成して幅を計算
  // 最大要素数分のヒントを表示する場合の幅を計算
  TestText := FormatHint(FRowHints[4]);  // 最も長い可能性がある行（中央の行）
  if MaxHintCount > 1 then
  begin
    // 複数のヒントがある場合、スペースで区切る
    TestText := '';
    for i := 0 to MaxHintCount - 1 do
    begin
      if i > 0 then
        TestText := TestText + ' ';
      TestText := TestText + IntToStr(MaxHintLength);
    end;
  end;
  
  // キャンバスを使用してテキストのサイズを測定
  with DrawGrid1.Canvas do
  begin
    Font.Style := [fsBold];
    TestWidth := TextWidth(TestText) + 20;  // 余白を追加
    TestHeight := TextHeight(TestText) + 10;  // 余白を追加
  end;
  
  // 最小サイズを確保
  if TestWidth < 60 then
    TestWidth := 60;
  if TestHeight < 30 then
    TestHeight := 30;
  
  FHintColWidth := TestWidth;
  FHintRowHeight := TestHeight;
end;

function TForm1.FormatHint(const HintArray: TIntArray): String;
var
  i: Integer;
begin
  Result := '';
  if Length(HintArray) = 0 then
    Exit;
  
  for i := 0 to High(HintArray) do
  begin
    if i > 0 then
      Result := Result + ' ';
    Result := Result + IntToStr(HintArray[i]);
  end;
end;

procedure TForm1.DrawGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  HintText: String;
  TS: TTextStyle;
begin
  // キャンバスの描画設定を初期化
  with DrawGrid1.Canvas do
  begin
    // テキストスタイルの設定（中央揃え用）
    TS := TextStyle;
    TS.Alignment := taCenter;  // 水平中央
    TS.Layout := tlCenter;     // 垂直中央
    TS.Clipping := True;       // セルからはみ出さない

    // --- 固定セル（左側の行ヒントまたは上側の列ヒント）の描画 ---
    if (aCol = 0) and (aRow = 0) then
    begin
      // 左上角のセル
      Brush.Color := clBtnFace;
      FillRect(aRect);
      Pen.Color := clGray;
      Rectangle(aRect);
    end
    else if aCol = 0 then
    begin
      Pen.Color := clGray;
      Rectangle(aRect);

      // 左側の固定列：行ヒントを表示
      Brush.Color := clBtnFace;
      FillRect(aRect);
      Font.Color := clBlack;
      Font.Style := [fsBold];
      Font.Size := 10;

      HintText := FormatHint(FRowHints[aRow - 1]);
      if HintText = '' then HintText := '0';

      // TextRectを使用して描画範囲(aRect)内に中央揃えで描画
      TextRect(aRect, aRect.Left, aRect.Top, HintText, TS);
    end
    else if aRow = 0 then
    begin
      Pen.Color := clGray;
      Rectangle(aRect);

      // 上側の固定行：列ヒントを表示
      Brush.Color := clBtnFace;
      FillRect(aRect);
      Font.Color := clBlack;
      Font.Style := [fsBold];
      Font.Size := 10;

      HintText := FormatHint(FColHints[aCol - 1]);
      if HintText = '' then HintText := '0';

      // TextRectを使用して描画範囲(aRect)内に中央揃えで描画
      TextRect(aRect, aRect.Left, aRect.Top, HintText, TS);


    end
    else
    begin
      // --- データセル（盤面）の描画 ---
      // 状態に応じて背景色を決定
      case FGrid[aCol - 1, aRow - 1] of
        csEmpty:  Brush.Color := clWhite;
        csFilled: Brush.Color := clBlack;
        else      Brush.Color := clWhite;
      end;

      FillRect(aRect);

      // グリッド線を描画
      Pen.Color := clGray;
      Rectangle(aRect);
    end;

    // フォーカス枠などの装飾が必要ない場合は、ここで終了
  end;
end;
procedure TForm1.DrawGrid1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Col, Row: Integer;
begin
  // 左クリックのみ処理（右クリックはDay 2以降で実装）
  if Button <> mbLeft then
    Exit;
  
  // クリックされたセルの座標を取得
  DrawGrid1.MouseToCell(X, Y, Col, Row);
  
  // 範囲チェック（固定列・固定行はクリック不可）
  if (Col <= 0) or (Col > 10) or (Row <= 0) or (Row > 10) then
    Exit;
  
  // インデックスを調整（固定列・固定行を除く）
  Dec(Col);
  Dec(Row);
  
  // セルの状態を切り替え
  if FGrid[Col, Row] = csEmpty then
  begin
    // 未確定（白）→ 塗りつぶし（黒）
    FGrid[Col, Row] := csFilled;
  end
  else
  begin
    // 塗りつぶし（黒）→ 未確定（白）
    FGrid[Col, Row] := csEmpty;
  end;
  
  // セルを再描画
  DrawGrid1.Invalidate;
end;

end.
