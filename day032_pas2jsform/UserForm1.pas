program UserForm1;

uses
  web, sysutils;

type
  // 1. 範囲型：年齢は18歳から120歳まで
  TAgeRange = 18..120;

  // 2. 列挙型と集合型：興味のある分野を複数選択
  TInterest = (itTech, itArt, itSports, itMusic);
  TInterests = set of TInterest;

  // 3. ユーザー情報のレコード（構造体）
  TUserRegistration = record
    UserName: string;
    Age: Integer;          // 入力時はIntegerとして受け取る
    Interests: TInterests;
  end;

  // バリデーション結果
  TValidationResult = record
    IsValid: Boolean;
    ErrorMessage: string;
  end;


function ValidateUser(const Data: TUserRegistration): TValidationResult;
begin
  Result.IsValid := False;

  // ユーザー名のチェック
  if Length(Data.UserName) < 3 then
  begin
    Result.ErrorMessage := 'ユーザー名は3文字以上で入力してください。';
    Exit;
  end;

  // 範囲型を利用した年齢チェック (Pascalの 'in' 演算子)
  if not (Data.Age in [Low(TAgeRange)..High(TAgeRange)]) then
  begin
    Result.ErrorMessage := '年齢は18歳から120歳の間で入力してください。';
    Exit;
  end;

  // 集合型を利用したチェック（例：興味のある分野を1つ以上選択）
  if Data.Interests = [] then
  begin
    Result.ErrorMessage := '興味のある分野を少なくとも1つ選択してください。';
    Exit;
  end;

  Result.IsValid := True;
  Result.ErrorMessage := '';
end;



procedure OnSubmitClick(_Event: TJSEvent);
var
  Data: TUserRegistration;
  Result: TValidationResult;
  Doc: TJSHTMLDocument;
  ErrorDiv: TJSHTMLElement;
  I: Integer;
  CBs: TJSNodeList;
  CB: TJSHTMLInputElement;
begin
  Doc := TJSHTMLDocument(window.document);
  ErrorDiv := TJSHTMLElement(Doc.getElementById('errorMessage'));
  
  // 1. DOMから値を取得して Pascal レコードにバインド
  Data.UserName := TJSHTMLInputElement(Doc.getElementById('userName')).value;
  Data.Age := StrToIntDef(TJSHTMLInputElement(Doc.getElementById('age')).value, 0);
  
  // 集合型 (Set) の初期化とバインド
  Data.Interests := [];
  CBs := Doc.querySelectorAll('input[name="interest"]:checked');
  for I := 0 to CBs.length - 1 do
  begin
    CB := TJSHTMLInputElement(CBs[I]);
    // 文字列から列挙型への安全なマッピング（実際はCase文などで実装）
    if CB.value = 'itTech' then Include(Data.Interests, itTech);
    if CB.value = 'itArt' then Include(Data.Interests, itArt);
    if CB.value = 'itSports' then Include(Data.Interests, itSports);
    if CB.value = 'itMusic' then Include(Data.Interests, itMusic);
  end;

  // 2. Pascalの型システムによるバリデーション実行
  Result := ValidateUser(Data);

  // 3. UIへのフィードバック
  if Result.IsValid then
  begin
    ErrorDiv.style.setProperty('display', 'none');
    window.alert('登録成功！型安全なデータが準備できました。');
    // ここで TJSON.Stringify(Data) してサーバーへ送信可能
  end
  else
  begin
    ErrorDiv.innerText := Result.ErrorMessage;
    ErrorDiv.style.setProperty('display', 'block');
  end;
end;

// メイン・エントリポイント (rtl.runで呼ばれる)
begin
  window.document.getElementById('submitBtn').addEventListener('click', @OnSubmitClick);
end.