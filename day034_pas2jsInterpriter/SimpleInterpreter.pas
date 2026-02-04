program SimpleInterpreter;

uses
  SysUtils, Classes, JS, Web;

var
  ConsoleElement: TJSHTMLElement;
  SourceElement: TJSHTMLTextAreaElement;

// 実行ログの表示用
procedure PrintToConsole(const Msg: string);
begin
  ConsoleElement.InnerText := ConsoleElement.InnerText + Msg + #10;
end;

type
  TInterpreter = class
  private
    FSource: string;
    FPos: Integer;
    FVariables: TStringList; // 簡易的な変数格納庫
    FLookAhead: string;     // 式解析用 1トークン先読み
    
    function GetChar: Char;
    function FetchToken: string;   // ソースから1トークン読み進める
    function GetToken: string;     // 先読みがあればそれ、なければ FetchToken
    function PeekToken: string;    // 消費せず次のトークンを返す
    procedure SkipSpaces;
    function ParseExpression: Double;  // 再帰下降: expression = term (('+'|'-') term)*
    function ParseTerm: Double;        // term = factor (('*'|'/') factor)*
    function ParseFactor: Double;      // factor = '(' expr ')' | unary | number | variable
    function EvaluateExpression: Double;
    procedure ExecuteOneStatement;   // PRINT または 代入を1文実行
    procedure SkipOneStatement;      // 1文を読み飛ばす（IF の条件不成立時用）
    procedure ExecuteStatementWithToken(const Token: string);  // 先読み済みトークンで1文実行
    procedure SkipStatementWithToken(const Token: string);   // 1文を読み飛ばす（トークン済み）
    procedure SkipUntilWEND;       // WEND まで読み飛ばす（ネスト対応）
    procedure DoWhileLoop;         // WHILE を消費済みとしてループ実行
  public
    constructor Create;
    destructor Destroy; override;
    procedure Execute(ASource: string);
  end;

{ TInterpreter の実装 (一部抜粋・簡略化) }

constructor TInterpreter.Create;
begin
  inherited Create;
  FVariables := TStringList.Create;
  FLookAhead := '';
end;

destructor TInterpreter.Destroy;
begin
  FVariables.Free;
  inherited Destroy;
end;

function TInterpreter.GetChar: Char;
begin
  if FPos <= Length(FSource) then
    Result := FSource[FPos]
  else
    Result := #0;
end;

procedure TInterpreter.SkipSpaces;
begin
  while (FPos <= Length(FSource)) and (FSource[FPos] in [' ', #9, #10, #13]) do
    Inc(FPos);
end;

function TInterpreter.FetchToken: string;
var
  C: Char;
begin
  Result := '';
  SkipSpaces;
  if FPos > Length(FSource) then Exit;
  C := GetChar;
  if C in ['A'..'Z', 'a'..'z', '_'] then
  begin
    while (FPos <= Length(FSource)) and (FSource[FPos] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
    begin
      Result := Result + FSource[FPos];
      Inc(FPos);
    end;
  end
  else if C in ['0'..'9', '.'] then
  begin
    while (FPos <= Length(FSource)) and (FSource[FPos] in ['0'..'9', '.']) do
    begin
      Result := Result + FSource[FPos];
      Inc(FPos);
    end;
  end
  else
  begin
    Result := C;
    Inc(FPos);
  end;
end;

function TInterpreter.GetToken: string;
begin
  if FLookAhead <> '' then
  begin
    Result := FLookAhead;
    FLookAhead := '';
  end
  else
    Result := FetchToken;
end;

function TInterpreter.PeekToken: string;
begin
  if FLookAhead = '' then
    FLookAhead := FetchToken;
  Result := FLookAhead;
end;

{ 再帰下降構文解析: expression = term (('+'|'-') term)* }
function TInterpreter.ParseExpression: Double;
var
  T: string;
begin
  Result := ParseTerm;
  T := PeekToken;
  while (T = '+') or (T = '-') do
  begin
    GetToken;  // consume '+' or '-'
    if T = '+' then
      Result := Result + ParseTerm
    else
      Result := Result - ParseTerm;
    T := PeekToken;
  end;
end;

{ term = factor (('*'|'/') factor)* }
function TInterpreter.ParseTerm: Double;
var
  T: string;
  Right: Double;
begin
  Result := ParseFactor;
  T := PeekToken;
  while (T = '*') or (T = '/') do
  begin
    GetToken;  // consume '*' or '/'
    Right := ParseFactor;
    if T = '*' then
      Result := Result * Right
    else
      if Right <> 0 then Result := Result / Right;
    T := PeekToken;
  end;
end;

{ factor = '(' expression ')' | unary '+'|'-' factor | number | variable }
function TInterpreter.ParseFactor: Double;
var
  T: string;
begin
  T := PeekToken;
  if T = '(' then
  begin
    GetToken;  // consume '('
    Result := ParseExpression;
    if PeekToken = ')' then
      GetToken  // consume ')'
    else
      Result := 0;
  end
  else if (T = '+') or (T = '-') then
  begin
    GetToken;
    if T = '-' then
      Result := -ParseFactor
    else
      Result := ParseFactor;
  end
  else
  begin
    T := GetToken;
    if T = '' then
      Result := 0
    else if (Length(T) > 0) and (T[1] in ['0'..'9', '.']) then
      Result := StrToFloatDef(T, 0)
    else
      Result := StrToFloatDef(FVariables.Values[T], 0);
  end;
end;

function TInterpreter.EvaluateExpression: Double;
begin
  FLookAhead := '';
  Result := ParseExpression;
end;

procedure TInterpreter.ExecuteOneStatement;
var
  Token: string;
begin
  Token := GetToken;
  if Token = 'PRINT' then
    PrintToConsole(FloatToStr(EvaluateExpression))
  else if Token <> '' then
  begin
    if PeekToken = '=' then
      GetToken;
    FVariables.Values[Token] := FloatToStr(EvaluateExpression);
  end;
end;

procedure TInterpreter.SkipOneStatement;
var
  Token: string;
begin
  Token := GetToken;
  if Token = 'PRINT' then
    EvaluateExpression  // 式だけ消費
  else if Token <> '' then
  begin
    if PeekToken = '=' then
      GetToken;
    EvaluateExpression;
  end;
end;

procedure TInterpreter.ExecuteStatementWithToken(const Token: string);
begin
  if Token = 'PRINT' then
    PrintToConsole(FloatToStr(EvaluateExpression))
  else if Token <> '' then
  begin
    if PeekToken = '=' then
      GetToken;
    FVariables.Values[Token] := FloatToStr(EvaluateExpression);
  end;
end;

procedure TInterpreter.SkipStatementWithToken(const Token: string);
begin
  if Token = 'PRINT' then
    EvaluateExpression
  else if Token <> '' then
  begin
    if PeekToken = '=' then
      GetToken;
    EvaluateExpression;
  end;
end;

procedure TInterpreter.SkipUntilWEND;
var
  Token: string;
begin
  repeat
    Token := GetToken;
    if Token = 'WEND' then Exit;
    if Token = 'WHILE' then
    begin
      EvaluateExpression;  // 条件を消費
      SkipUntilWEND;        // 内側の WEND まで飛ばす
    end
    else
      SkipStatementWithToken(Token);
  until False;
end;

procedure TInterpreter.DoWhileLoop;
var
  startOfLoop: Integer;
  condition: Double;
  Token: string;
begin
  startOfLoop := FPos;
  repeat
    FPos := startOfLoop;
    FLookAhead := '';
    condition := EvaluateExpression;
    if condition = 0 then
    begin
      SkipUntilWEND;
      Break;
    end;
    repeat
      Token := GetToken;
      if Token = 'WEND' then Break;
      if Token = 'WHILE' then
        DoWhileLoop
      else if Token = 'IF' then
      begin
        if EvaluateExpression <> 0 then
        begin
          ExecuteOneStatement;
          if PeekToken = 'ELSE' then begin GetToken; SkipOneStatement; end;
        end
        else
        begin
          SkipOneStatement;
          if PeekToken = 'ELSE' then begin GetToken; ExecuteOneStatement; end;
        end;
      end
      else
        ExecuteStatementWithToken(Token);
    until False;
  until False;
end;

procedure TInterpreter.Execute(ASource: string);
var
  Token: string;
begin
  FSource := ASource;
  FPos := 1;
  while FPos <= Length(FSource) do
  begin
    Token := GetToken;
    if Token = 'PRINT' then
      PrintToConsole(FloatToStr(EvaluateExpression))
    else if Token = 'IF' then
    begin
      if EvaluateExpression <> 0 then
      begin
        ExecuteOneStatement;
        if PeekToken = 'ELSE' then begin GetToken; SkipOneStatement; end;
      end
      else
      begin
        SkipOneStatement;
        if PeekToken = 'ELSE' then begin GetToken; ExecuteOneStatement; end;
      end;
    end
    else if Token = 'WHILE' then
      DoWhileLoop
    else if Token <> '' then
    begin
      // 代入処理 (Variable = Value): '=' を消費してから右辺を評価
      if PeekToken = '=' then
        GetToken;  // consume '='
      FVariables.Values[Token] := FloatToStr(EvaluateExpression);
    end;
  end;
end;

// --- メイン処理 ---
function OnRunClick(Event: TJSMouseEvent): Boolean;
var
  Interpreter: TInterpreter;
begin
  Result := True;
  ConsoleElement.InnerText := ''; // クリア
  Interpreter := TInterpreter.Create;
  try
    Interpreter.Execute(SourceElement.Value);
  finally
    Interpreter.Free;
  end;
end;

begin
  ConsoleElement := TJSHTMLElement(document.getElementById('console'));
  SourceElement := TJSHTMLTextAreaElement(document.getElementById('source'));
  TJSHTMLElement(document.getElementById('runBtn')).onclick := @OnRunClick;
end.