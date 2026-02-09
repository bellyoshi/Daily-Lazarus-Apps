program TypingGame;

uses
  js, sysutils, types, web;

var
  Canvas: TJSHTMLCanvasElement;
  Ctx: TJSCanvasRenderingContext2D;
  Keywords: TStringDynArray;
  ActiveWords: TJSArray; // 現在画面にある単語
  Score: Integer;
  UserInput: String;
  CheckTimer: NativeInt;  // キーワード読み込み完了を待つタイマー

// 単語オブジェクトの定義
type
  TWord = class
    Text: String;
    X, Y: Double;
    Speed: Double;
    constructor Create(AText: String);
  end;

constructor TWord.Create(AText: String);
begin
  Text := AText;
  X := 0; // 左から流れる
  Y := 50 + Random * 300; // ランダムな高さ
  Speed := 1 + Random * 2;
end;

// --- ロジック部分 ---

procedure SpawnWord;
begin
  ActiveWords.push(TWord.Create(Keywords[Random(Length(Keywords))]));
end;

procedure Update(HighResTime: Double);
var
  i: Integer;
  W: TWord;
begin
  // 背景クリア
  Ctx.fillStyle := '#2c3e50';
  Ctx.fillRect(0, 0, Canvas.width, Canvas.height);

  // 単語の移動と描画
  Ctx.font := '24px Monospace';
  Ctx.fillStyle := '#ecf0f1';
  
  for i := ActiveWords.length - 1 downto 0 do
  begin
    W := TWord(ActiveWords[i]);
    W.X := W.X + W.Speed;
    Ctx.fillText(W.Text, W.X, W.Y);

    // 画面外に出たら削除
    if W.X > Canvas.width then
      ActiveWords.splice(i, 1);
  end;

  // 入力中の文字をキャンバスにも表示
  Ctx.fillStyle := '#f1c40f';
  Ctx.font := '20px Monospace';
  Ctx.fillText('入力: ' + UserInput + '|', 20, Canvas.height - 20);

  window.requestAnimationFrame(@Update);
end;

// キー入力イベント
function HandleKeyDown(Event: TJSKeyboardEvent): boolean;
var
  i: Integer;
  W: TWord;
  El: TJSElement;
begin
  if Event.Key = 'Backspace' then
  begin
    if Length(UserInput) > 0 then
      UserInput := Copy(UserInput, 1, Length(UserInput) - 1);
    El := TJSElement(document.getElementById('current-word'));
    if UserInput = '' then El.textContent := '_' else El.textContent := UserInput;
  end
  else if Event.Key = 'Enter' then
  begin
    // 入力判定: 表示中の単語のどれかと一致したら削除してスコア加算
    for i := ActiveWords.length - 1 downto 0 do
    begin
      W := TWord(ActiveWords[i]);
      if W.Text = UserInput then
      begin
        ActiveWords.splice(i, 1);
        Score := Score + Length(W.Text);
        Break;
      end;
    end;
    UserInput := '';
    TJSElement(document.getElementById('current-word')).textContent := '_';
    TJSElement(document.getElementById('score-value')).textContent := IntToStr(Score);
  end
  else if (Length(Event.Key) = 1) and not Event.ctrlKey and not Event.altKey and not Event.metaKey then
  begin
    UserInput := UserInput + Event.Key;
    El := TJSElement(document.getElementById('current-word'));
    El.textContent := UserInput;
  end;
  Result := True;
end;

// ゲーム開始（キーワード読み込み後に呼ぶ）
procedure StartGame;
begin
  ActiveWords := TJSArray.new;
  Canvas := TJSHTMLCanvasElement(document.getElementById('gameCanvas'));
  Ctx := TJSCanvasRenderingContext2D(Canvas.getContext('2d'));
  window.setInterval(@SpawnWord, 2000);
  window.requestAnimationFrame(@Update);
  window.addEventListener('keydown', @HandleKeyDown);
end;

function GetKeywordsReady: Boolean;
begin
  Result := False;
  asm
    return !!window._keywordsReady;
  end;
end;

// キーワード読み込み完了をチェックし、完了していたらゲーム開始
procedure CheckKeywordsAndStart;
begin
  if GetKeywordsReady then
  begin
    window.clearInterval(CheckTimer);
    Keywords := TStringDynArray(JSValue(window['_keywordsData']));
    if Length(Keywords) = 0 then
      Keywords := [ {$I keywords.inc} ];  // 読み込み失敗時は組み込みリストを使用
    StartGame;
  end;
end;

begin
  // 実行時に keywords.txt を読み込む（編集しても再コンパイル不要）
  asm
    window._keywordsReady = false;
    window._keywordsData = [];
    window.fetch('keywords.txt').then(function(r) { return r.text(); }).then(function(t) {
      var lines = t.split(/\r?\n/);
      for (var i = 0; i < lines.length; i++) {
        var s = lines[i].trim();
        if (s) window._keywordsData.push(s);
      }
      window._keywordsReady = true;
    }).catch(function() { window._keywordsReady = true; });
  end;
  CheckTimer := NativeInt(window.setInterval(@CheckKeywordsAndStart, 50));
end.