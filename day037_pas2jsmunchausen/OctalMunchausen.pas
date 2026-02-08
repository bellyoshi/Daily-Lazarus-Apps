program OctalMunchausen;

{$mode objfpc}

uses
  SysUtils, Web;

const
  BASE = 8;
  TARGET_DIGITS = 8;

var
  PowCache: array[0..BASE-1] of Integer;
  OutputDiv: TJSHTMLElement;

procedure AppendHtml(const s: string);
begin
  OutputDiv.InnerHTML := OutputDiv.InnerHTML + s;
end;

procedure AppendLine(const s: string);
begin
  AppendHtml('<span class="console-text">' + s + '</span><br>');
end;

// 0^0 = 1 と定義した累乗キャッシュの初期化
procedure InitPowCache;
var
  i, j, p: Integer;
begin
  PowCache[0] := 1; // 0^0 = 1
  for i := 1 to BASE - 1 do
  begin
    p := 1;
    for j := 1 to i do
      p := p * i;
    PowCache[i] := p;
  end;
end;

// 8進数としての各桁の累乗和を計算し、式を表示する
procedure CheckAndPrint(n: Integer);
var
  temp: Integer;
  digits: array[0..TARGET_DIGITS-1] of Integer;
  sum: Integer;
  i: Integer;
  sOctal, sFormulaHtml: String;
begin
  sum := 0;
  temp := n;
  
  for i := 0 to TARGET_DIGITS - 1 do
  begin
    digits[TARGET_DIGITS - 1 - i] := temp mod BASE;
    sum := sum + PowCache[temp mod BASE];
    temp := temp div BASE;
  end;

  if sum = n then
  begin
    sOctal := '';
    sFormulaHtml := '';
    for i := 0 to TARGET_DIGITS - 1 do
    begin
      sOctal := sOctal + IntToStr(digits[i]);
      if sFormulaHtml <> '' then
        sFormulaHtml := sFormulaHtml + '<span class="formula-eq"> + </span>';
      sFormulaHtml := sFormulaHtml + '<span class="formula-term">' + IntToStr(digits[i]) + '<sup>' + IntToStr(digits[i]) + '</sup></span>';
    end;
    sFormulaHtml := sFormulaHtml + '<span class="formula-eq"> = </span><span class="formula-result">' + IntToStr(n) + '</span>';
    AppendHtml('<div class="result-card"><div class="octal">' + sOctal + '</div><div class="decimal">10進数: ' + IntToStr(n) + '</div><div class="formula-line">' + sFormulaHtml + '</div></div>');
  end;
end;

var
  i, Limit: Integer;
begin
  InitPowCache;
  
  // 8進数 8桁の最大値は 8^8 - 1
  Limit := 1;
  for i := 1 to TARGET_DIGITS do Limit := Limit * BASE;
  Limit := Limit - 1;

  OutputDiv := TJSHTMLElement(document.getElementById('output'));
  AppendLine('8進数 8桁固定探索開始 (0^0=1)');
  AppendLine('範囲: 00000000 ～ 77777777');
  AppendLine('--------------------------------------------------');

  for i := 0 to Limit do
  begin
    CheckAndPrint(i);
  end;

  AppendLine('探索終了');
end.