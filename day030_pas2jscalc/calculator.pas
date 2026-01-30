program calculator;

uses
  web, sysutils, js;

var
  InputBox: TJSHTMLInputElement;
  CalcButton: TJSHTMLButtonElement;
  ResultDiv: TJSElement;
  Pos: Integer;
  Expr: string;

// 次の文字を取得
function PeekChar: Char;
begin
  if Pos <= Length(Expr) then Result := Expr[Pos] else Result := #0;
end;

// 1文字進む
function GetChar: Char;
begin
  Result := PeekChar;
  if Result <> #0 then Inc(Pos);
end;

// 空白を飛ばす
procedure SkipWhite;
begin
  while (PeekChar = ' ') do GetChar;
end;

// プロトタイプ宣言（相互参照のため）
function ParseExpression: Double; forward;

// 数値およびカッコの解析
function ParseFactor: Double;
var
  S: string;
begin
  SkipWhite;
  if PeekChar = '(' then
  begin
    GetChar; // '(' を消費
    Result := ParseExpression;
    SkipWhite;
    if PeekChar = ')' then GetChar; // ')' を消費
  end
  else
  begin
    S := '';
    // 数値（小数点含む）を切り出す
    while (PeekChar in ['0'..'9', '.']) do
      S := S + GetChar;
    
    if S = '' then Result := 0 else Result := StrToFloat(S);
  end;
end;

// 掛け算・割り算の解析
function ParseTerm: Double;
var
  Op: Char;
  NextVal: Double;
begin
  Result := ParseFactor;
  SkipWhite;
  while PeekChar in ['*', '/'] do
  begin
    Op := GetChar;
    NextVal := ParseFactor;
    if Op = '*' then Result := Result * NextVal
    else if NextVal <> 0 then Result := Result / NextVal;
    SkipWhite;
  end;
end;

// 足し算・引き算の解析
function ParseExpression: Double;
var
  Op: Char;
  NextVal: Double;
begin
  Result := ParseTerm;
  SkipWhite;
  while PeekChar in ['+', '-'] do
  begin
    Op := GetChar;
    NextVal := ParseTerm;
    if Op = '+' then Result := Result + NextVal
    else Result := Result - NextVal;
    SkipWhite;
  end;
end;

// 計算実行メイン
function DoCalculate(Event: TJSMouseEvent): boolean;
var
  FinalResult: Double;
begin
  Result := False;
  Expr := InputBox.value;
  Pos := 1;
  
  try
    FinalResult := ParseExpression;
    ResultDiv.innerHTML := '結果: ' + FloatToStr(FinalResult);
  except
    ResultDiv.innerHTML := 'エラー: 計算できません';
  end;
end;

begin
  InputBox := TJSHTMLInputElement(document.getElementById('formula'));
  CalcButton := TJSHTMLButtonElement(document.getElementById('btnCalc'));
  ResultDiv := document.getElementById('result');

  if Assigned(CalcButton) then
    CalcButton.onclick := @DoCalculate;
end.