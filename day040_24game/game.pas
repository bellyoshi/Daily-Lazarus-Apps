program game;

uses
  web, sysutils, JS, Math;

type
  TInputState = (isSelectFirst, isSelectOp, isSelectSecond, isGameOver, isWin);
  TDoubleArray = array of Double;

var
  Numbers: TDoubleArray;
  SelectedIdx: Integer = -1;
  SelectedOp: string = '';
  State: TInputState = isSelectFirst;

// ソルバー：出題時に「解けるか」判定
function CanSolve(Nums: TDoubleArray): Boolean;
var
  i, j, k, m, op: Integer;
  NextNums: TDoubleArray;
  Res: Double;
begin
  if Length(Nums) = 1 then exit(Abs(Nums[0] - 24) < 0.0001);

  for i := 0 to High(Nums) do
    for j := 0 to High(Nums) do
      if i <> j then
      begin
        SetLength(NextNums, Length(Nums) - 1);
        k := 0;
        for m := 0 to High(Nums) do
          if (m <> i) and (m <> j) then begin NextNums[k] := Nums[m]; Inc(k); end;

        for op := 1 to 4 do
        begin
          case op of
            1: Res := Nums[i] + Nums[j];
            2: Res := Nums[i] - Nums[j];
            3: Res := Nums[i] * Nums[j];
            4: if Nums[j] <> 0 then Res := Nums[i] / Nums[j] else continue;
          end;
          NextNums[High(NextNums)] := Res;
          if CanSolve(NextNums) then exit(True);
        end;
      end;
  Result := False;
end;

procedure UpdateUI; forward;
procedure HandleNumberClick(Index: Integer); forward;

// 数字ボタンのクリックイベント（インデックスを data-idx から取得）
function HandleNumberBtnClick(Event: TJSMouseEvent): Boolean;
var
  Btn: TJSHTMLButtonElement;
  Idx: Integer;
begin
  Btn := TJSHTMLButtonElement(Event.Target);
  Idx := StrToInt(Btn.getAttribute('data-idx'));
  HandleNumberClick(Idx);
  Result := True;
end;

// 数字ボタンクリック
procedure HandleNumberClick(Index: Integer);
var
  N1, N2, Res: Double;
  NewArr: TDoubleArray;
  i: Integer;
begin
  case State of
    isSelectFirst: begin
      SelectedIdx := Index;
      State := isSelectOp;
    end;
    isSelectSecond: begin
      if Index = SelectedIdx then Exit;
      N1 := Numbers[SelectedIdx];
      N2 := Numbers[Index];

      if SelectedOp = '+' then Res := N1 + N2
      else if SelectedOp = '-' then Res := N1 - N2
      else if SelectedOp = '*' then Res := N1 * N2
      else if (SelectedOp = '/') and (N2 <> 0) then Res := N1 / N2
      else Exit;

      // 配列更新
      SetLength(NewArr, 0);
      for i := 0 to High(Numbers) do
        if (i <> SelectedIdx) and (i <> Index) then
        begin
          SetLength(NewArr, Length(NewArr) + 1);
          NewArr[High(NewArr)] := Numbers[i];
        end;
      SetLength(NewArr, Length(NewArr) + 1);
      NewArr[High(NewArr)] := Res;
      Numbers := NewArr;

      SelectedIdx := -1;
      SelectedOp := '';
      State := isSelectFirst;
      
      if (Length(Numbers) = 1) then 
      begin
        if (Abs(Numbers[0] - 24) < 0.0001) then 
        begin
          State := isWin;
        end else begin
          State := isGameOver;
        end;
      end;
    end;
  end;
  UpdateUI;
end;

procedure HandleOpClick(OpStr: string);
begin
  if State = isSelectOp then
  begin
    SelectedOp := OpStr;
    State := isSelectSecond;
    UpdateUI;
  end;
end;

procedure UpdateUI;
var
  Container: TJSHTMLElement;
  Btn: TJSHTMLButtonElement;
  Msg: string;
  i: Integer;
begin
  Container := TJSHTMLElement(document.getElementById('number-container'));
  Container.innerHTML := '';
  
  for i := 0 to High(Numbers) do
  begin
    Btn := TJSHTMLButtonElement(document.createElement('button'));
    Btn.className := 'num-btn';
    if i = SelectedIdx then Btn.classList.add('selected');
    Btn.textContent := FloatToStr(Numbers[i]);
    Btn.setAttribute('data-idx', IntToStr(i));
    Btn.onclick := @HandleNumberBtnClick;
    Container.appendChild(Btn);
  end;

  case State of
    isSelectFirst: Msg := '数字を選んでください';
    isSelectOp: Msg := '演算子を選んでください';
    isSelectSecond: Msg := '2つ目の数字を選んでください';
    isGameOver: Msg := '残念、24になりませんでした';
    isWin: Msg := 'Congratulations!おめでとう 🎉';
  end;
  document.getElementById('msg').innerHTML := Msg;
end;

procedure NewGame;
var
  i: Integer;
begin
  SetLength(Numbers, 4);
  repeat
    for i := 0 to 3 do Numbers[i] := Random(9) + 1;
  until CanSolve(Numbers);
  
  SelectedIdx := -1;
  SelectedOp := '';
  State := isSelectFirst;
  UpdateUI;
end;

// JS側から呼び出せるように公開
begin
  TJSObject(window)['game'] := TJSObject.new;
  TJSObject(TJSObject(window)['game'])['HandleOpClick'] := @HandleOpClick;
  TJSObject(TJSObject(window)['game'])['NewGame'] := @NewGame;
  NewGame;
end.