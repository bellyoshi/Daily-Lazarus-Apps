unit DancingLinks;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  // Dancing Linksのノード
  PDancingLinksNode = ^TDancingLinksNode;
  TDancingLinksNode = record
    Left, Right, Up, Down: PDancingLinksNode;
    Column: PDancingLinksNode;  // 列ヘッダーへのポインタ
    RowID: Integer;             // 行の識別子（数独ではセル位置と値の組み合わせ）
  end;

  // Dancing Linksソルバー
  TDancingLinksSolver = class
  private
    FHeader: PDancingLinksNode;  // ルートノード（列ヘッダーのヘッダー）
    FColumns: array of PDancingLinksNode;  // 列ヘッダーの配列
    FColumnSizes: array of Integer;  // 各列のサイズ（ノード数）
    FSolution: TList;            // 解を保持するリスト
    FNumColumns: Integer;         // 列の数
    FNumRows: Integer;            // 行の数
    
    // ノードの作成と削除
    function CreateNode: PDancingLinksNode;
    procedure FreeNode(ANode: PDancingLinksNode);
    
    // リンク操作
    procedure LinkLeftRight(ALeft, ARight: PDancingLinksNode);
    procedure LinkUpDown(AUp, ADown: PDancingLinksNode);
    
    // ノードの削除と復元
    procedure CoverColumn(AColumn: PDancingLinksNode);
    procedure UncoverColumn(AColumn: PDancingLinksNode);
    
    // Algorithm Xの再帰的実装
    function Search(ADepth: Integer): Boolean;
    
    // 列の選択（最小サイズの列を選択）
    function SelectColumn: PDancingLinksNode;
    
  public
    constructor Create(ANumColumns: Integer);
    destructor Destroy; override;
    
    // 行を追加（行IDとその行がカバーする列のインデックスのリスト）
    procedure AddRow(ARowID: Integer; AColumns: array of Integer);
    
    // 解を探索
    function Solve: Boolean;
    
    // 解を取得
    function GetSolution: TList;
    
    // デバッグ用：マトリックスの表示
    procedure PrintMatrix;
  end;

implementation

{ TDancingLinksSolver }

constructor TDancingLinksSolver.Create(ANumColumns: Integer);
var
  i: Integer;
  PrevNode: PDancingLinksNode;
begin
  inherited Create;
  FNumColumns := ANumColumns;
  FNumRows := 0;
  FSolution := TList.Create;
  
  // ルートノード（ヘッダー）を作成
  FHeader := CreateNode;
  FHeader^.Left := FHeader;
  FHeader^.Right := FHeader;
  FHeader^.Up := FHeader;
  FHeader^.Down := FHeader;
  FHeader^.Column := nil;
  FHeader^.RowID := -1;
  
  // 列ヘッダーを作成
  SetLength(FColumns, FNumColumns);
  SetLength(FColumnSizes, FNumColumns);
  PrevNode := FHeader;
  
  for i := 0 to FNumColumns - 1 do
  begin
    FColumns[i] := CreateNode;
    FColumns[i]^.Column := FColumns[i];
    FColumns[i]^.RowID := i;  // 列のインデックスを保存
    FColumnSizes[i] := 0;
    
    // 列ヘッダーを双方向リンクで接続
    LinkLeftRight(PrevNode, FColumns[i]);
    LinkLeftRight(FColumns[i], FHeader);
    PrevNode := FColumns[i];
    
    // 列ヘッダーの上下リンクを自分自身に設定
    FColumns[i]^.Up := FColumns[i];
    FColumns[i]^.Down := FColumns[i];
  end;
end;

destructor TDancingLinksSolver.Destroy;
var
  i: Integer;
  Node, NextNode, RowNode, NextRowNode: PDancingLinksNode;
begin
  // すべてのノードを解放
  if Assigned(FHeader) then
  begin
    // 各列を処理
    for i := 0 to FNumColumns - 1 do
    begin
      if Assigned(FColumns[i]) then
      begin
        // 列内のすべてのノードを解放
        Node := FColumns[i]^.Down;
        while Node <> FColumns[i] do
        begin
          NextNode := Node^.Down;
          FreeNode(Node);
          Node := NextNode;
        end;
        // 列ヘッダーを解放
        FreeNode(FColumns[i]);
      end;
    end;
    // ルートノードを解放
    FreeNode(FHeader);
  end;
  
  FSolution.Free;
  inherited Destroy;
end;

function TDancingLinksSolver.CreateNode: PDancingLinksNode;
begin
  New(Result);
  Result^.Left := nil;
  Result^.Right := nil;
  Result^.Up := nil;
  Result^.Down := nil;
  Result^.Column := nil;
  Result^.RowID := -1;
end;

procedure TDancingLinksSolver.FreeNode(ANode: PDancingLinksNode);
begin
  if Assigned(ANode) then
    Dispose(ANode);
end;

procedure TDancingLinksSolver.LinkLeftRight(ALeft, ARight: PDancingLinksNode);
begin
  ALeft^.Right := ARight;
  ARight^.Left := ALeft;
end;

procedure TDancingLinksSolver.LinkUpDown(AUp, ADown: PDancingLinksNode);
begin
  AUp^.Down := ADown;
  ADown^.Up := AUp;
end;

procedure TDancingLinksSolver.AddRow(ARowID: Integer; AColumns: array of Integer);
var
  i: Integer;
  FirstNode, PrevNode, NewNode: PDancingLinksNode;
  Column: PDancingLinksNode;
begin
  if Length(AColumns) = 0 then
    Exit;
  
  FirstNode := nil;
  PrevNode := nil;
  
  // 行内の各列に対してノードを作成
  for i := 0 to Length(AColumns) - 1 do
  begin
    if (AColumns[i] < 0) or (AColumns[i] >= FNumColumns) then
      Continue;
    
    Column := FColumns[AColumns[i]];
    
    // 新しいノードを作成
    NewNode := CreateNode;
    NewNode^.Column := Column;
    NewNode^.RowID := ARowID;
    
    // 行内のノードを左右にリンク
    if FirstNode = nil then
    begin
      FirstNode := NewNode;
      PrevNode := NewNode;
      NewNode^.Left := NewNode;
      NewNode^.Right := NewNode;
    end
    else
    begin
      LinkLeftRight(PrevNode, NewNode);
      LinkLeftRight(NewNode, FirstNode);
      PrevNode := NewNode;
    end;
    
    // 列内のノードを上下にリンク
    // 列ヘッダーの上（最後のノード）の下に新しいノードを挿入
    LinkUpDown(Column^.Up, NewNode);
    LinkUpDown(NewNode, Column);
    
    // 列のサイズを増やす
    // 列ヘッダーのRowIDに列のインデックスが保存されている
    if (Column^.RowID >= 0) and (Column^.RowID < FNumColumns) then
      Inc(FColumnSizes[Column^.RowID]);
  end;
  
  Inc(FNumRows);
end;

procedure TDancingLinksSolver.CoverColumn(AColumn: PDancingLinksNode);
var
  RowNode, RightNode: PDancingLinksNode;
begin
  // 列ヘッダーを左右のリンクから削除
  LinkLeftRight(AColumn^.Left, AColumn^.Right);
  
  // 列内の各行を処理
  RowNode := AColumn^.Down;
  while RowNode <> AColumn do
  begin
    // 行内の各ノードを処理
    RightNode := RowNode^.Right;
    while RightNode <> RowNode do
    begin
      // ノードを上下のリンクから削除
      LinkUpDown(RightNode^.Up, RightNode^.Down);
      
      // 列のサイズを減らす
      // 列ヘッダーのRowIDに列のインデックスが保存されている
      if (RightNode^.Column^.RowID >= 0) and (RightNode^.Column^.RowID < FNumColumns) then
        Dec(FColumnSizes[RightNode^.Column^.RowID]);
      
      RightNode := RightNode^.Right;
    end;
    RowNode := RowNode^.Down;
  end;
end;

procedure TDancingLinksSolver.UncoverColumn(AColumn: PDancingLinksNode);
var
  RowNode, LeftNode: PDancingLinksNode;
begin
  // 列内の各行を逆順で処理（下から上へ）
  RowNode := AColumn^.Up;
  while RowNode <> AColumn do
  begin
    // 行内の各ノードを逆順で処理（右から左へ）
    LeftNode := RowNode^.Left;
    while LeftNode <> RowNode do
    begin
      // 列のサイズを増やす
      // 列ヘッダーのRowIDに列のインデックスが保存されている
      if (LeftNode^.Column^.RowID >= 0) and (LeftNode^.Column^.RowID < FNumColumns) then
        Inc(FColumnSizes[LeftNode^.Column^.RowID]);
      
      // ノードを上下のリンクに復元
      LinkUpDown(LeftNode^.Up, LeftNode);
      LinkUpDown(LeftNode, LeftNode^.Down);
      
      LeftNode := LeftNode^.Left;
    end;
    RowNode := RowNode^.Up;
  end;
  
  // 列ヘッダーを左右のリンクに復元
  LinkLeftRight(AColumn^.Left, AColumn);
  LinkLeftRight(AColumn, AColumn^.Right);
end;

function TDancingLinksSolver.SelectColumn: PDancingLinksNode;
var
  Node: PDancingLinksNode;
  MinSize, Size: Integer;
begin
  Result := nil;
  MinSize := MaxInt;
  
  // ルートノードから右へ進み、最小サイズの列を探す
  Node := FHeader^.Right;
  while Node <> FHeader do
  begin
    // 列のサイズを取得（列ヘッダーのRowIDに列のインデックスが保存されている）
    if (Node^.RowID >= 0) and (Node^.RowID < FNumColumns) then
    begin
      Size := FColumnSizes[Node^.RowID];
      if Size < MinSize then
      begin
        MinSize := Size;
        Result := Node;
      end;
    end;
    Node := Node^.Right;
  end;
end;

function TDancingLinksSolver.Search(ADepth: Integer): Boolean;
var
  Column, RowNode, RightNode: PDancingLinksNode;
  SolutionRow: Integer;
begin
  Result := False;
  
  // すべての列がカバーされた場合、解が見つかった
  if FHeader^.Right = FHeader then
  begin
    Result := True;
    Exit;
  end;
  
  // 最小サイズの列を選択
  Column := SelectColumn;
  if Column = nil then
    Exit;
  
  // 列が空の場合、解なし
  if Column^.Down = Column then
    Exit;
  
  // 列をカバー
  CoverColumn(Column);
  
  // 列内の各行を試す
  RowNode := Column^.Down;
  while RowNode <> Column do
  begin
    // この行を解に追加
    SolutionRow := RowNode^.RowID;
    if ADepth >= FSolution.Count then
      FSolution.Add(Pointer(SolutionRow))
    else
      FSolution[ADepth] := Pointer(SolutionRow);
    
    // この行がカバーする他の列もカバー
    RightNode := RowNode^.Right;
    while RightNode <> RowNode do
    begin
      CoverColumn(RightNode^.Column);
      RightNode := RightNode^.Right;
    end;
    
    // 再帰的に探索
    if Search(ADepth + 1) then
    begin
      Result := True;
      Break;
    end;
    
    // バックトラック：カバーした列を復元
    RightNode := RowNode^.Left;
    while RightNode <> RowNode do
    begin
      UncoverColumn(RightNode^.Column);
      RightNode := RightNode^.Left;
    end;
    
    RowNode := RowNode^.Down;
  end;
  
  // 列を復元
  UncoverColumn(Column);
end;

function TDancingLinksSolver.Solve: Boolean;
begin
  FSolution.Clear;
  Result := Search(0);
end;

function TDancingLinksSolver.GetSolution: TList;
begin
  Result := FSolution;
end;

procedure TDancingLinksSolver.PrintMatrix;
var
  i: Integer;
  Node: PDancingLinksNode;
  RowNode: PDancingLinksNode;
begin
  WriteLn('Dancing Links Matrix:');
  WriteLn('Columns: ', FNumColumns);
  WriteLn('Rows: ', FNumRows);
  
  for i := 0 to FNumColumns - 1 do
  begin
    Write('Column ', i, ': ');
    RowNode := FColumns[i]^.Down;
    while RowNode <> FColumns[i] do
    begin
      Write(RowNode^.RowID, ' ');
      RowNode := RowNode^.Down;
    end;
    WriteLn;
  end;
end;

end.
