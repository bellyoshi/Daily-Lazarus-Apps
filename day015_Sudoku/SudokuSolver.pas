unit SudokuSolver;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DancingLinks;

type
  TSudokuGrid = array[0..8, 0..8] of Integer;  // 0 = 空きセル

  TSudokuSolver = class
  private
    function EncodeRowID(ARow, ACol, AValue: Integer): Integer;
    procedure DecodeRowID(ARowID: Integer; out ARow, ACol, AValue: Integer);
    function GetBoxIndex(ARow, ACol: Integer): Integer;
  public
    function Solve(const AGrid: TSudokuGrid; out ASolution: TSudokuGrid): Boolean;
  end;

implementation

{ TSudokuSolver }

function TSudokuSolver.EncodeRowID(ARow, ACol, AValue: Integer): Integer;
begin
  // 行ID = 行 * 81 + 列 * 9 + 値 - 1
  Result := ARow * 81 + ACol * 9 + (AValue - 1);
end;

procedure TSudokuSolver.DecodeRowID(ARowID: Integer; out ARow, ACol, AValue: Integer);
begin
  ARow := ARowID div 81;
  ACol := (ARowID mod 81) div 9;
  AValue := (ARowID mod 9) + 1;
end;

function TSudokuSolver.GetBoxIndex(ARow, ACol: Integer): Integer;
begin
  Result := (ARow div 3) * 3 + (ACol div 3);
end;

function TSudokuSolver.Solve(const AGrid: TSudokuGrid; out ASolution: TSudokuGrid): Boolean;
var
  Solver: TDancingLinksSolver;
  Row, Col, Value, Box: Integer;
  RowID: Integer;
  Columns: array[0..3] of Integer;
  Solution: TList;
  i: Integer;
  SolutionRow, SolutionCol, SolutionValue: Integer;
begin
  Result := False;
  
  // 数独の制約：324列
  // - セル制約：81列（各セルに1つの数字）
  // - 行制約：81列（各行に各数字が1回）
  // - 列制約：81列（各列に各数字が1回）
  // - ボックス制約：81列（各ボックスに各数字が1回）
  Solver := TDancingLinksSolver.Create(324);
  try
    // すべての可能な配置を追加
    for Row := 0 to 8 do
    begin
      for Col := 0 to 8 do
      begin
        // 既に値が設定されている場合
        if AGrid[Row, Col] <> 0 then
        begin
          Value := AGrid[Row, Col];
          if (Value < 1) or (Value > 9) then
            Continue;
          
          RowID := EncodeRowID(Row, Col, Value);
          Box := GetBoxIndex(Row, Col);
          
          // 4つの制約列を設定
          Columns[0] := Row * 9 + Col;  // セル制約
          Columns[1] := 81 + Row * 9 + (Value - 1);  // 行制約
          Columns[2] := 162 + Col * 9 + (Value - 1);  // 列制約
          Columns[3] := 243 + Box * 9 + (Value - 1);  // ボックス制約
          
          Solver.AddRow(RowID, Columns);
        end
        else
        begin
          // 空きセルの場合、すべての可能な値を追加
          for Value := 1 to 9 do
          begin
            RowID := EncodeRowID(Row, Col, Value);
            Box := GetBoxIndex(Row, Col);
            
            // 4つの制約列を設定
            Columns[0] := Row * 9 + Col;  // セル制約
            Columns[1] := 81 + Row * 9 + (Value - 1);  // 行制約
            Columns[2] := 162 + Col * 9 + (Value - 1);  // 列制約
            Columns[3] := 243 + Box * 9 + (Value - 1);  // ボックス制約
            
            Solver.AddRow(RowID, Columns);
          end;
        end;
      end;
    end;
    
    // 解を探索
    if Solver.Solve then
    begin
      // 解をグリッドに変換
      for Row := 0 to 8 do
        for Col := 0 to 8 do
          ASolution[Row, Col] := 0;
      
      Solution := Solver.GetSolution;
      for i := 0 to Solution.Count - 1 do
      begin
        DecodeRowID(Integer(Solution[i]), SolutionRow, SolutionCol, SolutionValue);
        ASolution[SolutionRow, SolutionCol] := SolutionValue;
      end;
      
      Result := True;
    end;
  finally
    Solver.Free;
  end;
end;

end.
