program project1;

uses
  SysUtils, Web, JS, Math;

type
  TState = record
    X, Y, Angle: Double;
    LineWidth: Double;
  end;

  TLSystemPreset = record
    Axiom: string;
    RuleF: string;
    RuleX: string;
    Angle: Double;
    InitialStep: Double;
    InitialY: Double; // 描画開始位置
  end;

var
  Canvas: TJSHTMLCanvasElement;
  Ctx: TJSCanvasRenderingContext2D;
  CurrentString: string;
  CurrentPreset: TLSystemPreset;
  Depth: Integer = 3;

// プリセットデータの定義
procedure SetPreset(Kind: string);
begin
  if Kind = 'tree' then begin
    CurrentPreset.Axiom := 'X';
    CurrentPreset.RuleF := 'FF';
    CurrentPreset.RuleX := 'F[[+X]-X]-F[-FX]+X';
    CurrentPreset.Angle := 25.0;
    CurrentPreset.InitialStep := 4.0;
    CurrentPreset.InitialY := 580;
  end else if Kind = 'fern' then begin
    CurrentPreset.Axiom := 'X';
    CurrentPreset.RuleF := 'FF';
    CurrentPreset.RuleX := 'F+[[X]-X]-F[-FX]+X';
    CurrentPreset.Angle := 20.0;
    CurrentPreset.InitialStep := 3.5;
    CurrentPreset.InitialY := 580;
  end else if Kind = 'snowflake' then begin
    CurrentPreset.Axiom := 'F++F++F';
    CurrentPreset.RuleF := 'F-F++F-F';
    CurrentPreset.RuleX := '';
    CurrentPreset.Angle := 60.0;
    CurrentPreset.InitialStep := 5.0;
    CurrentPreset.InitialY := 450;
  end;
end;

// ルール適用（文字列生成）
procedure ApplyRules;
var
  NextStr: string;
  i: Integer;
  C: Char;
begin
  NextStr := '';
  for i := 1 to Length(CurrentString) do
  begin
    C := CurrentString[i];
    case C of
      'F': NextStr := NextStr + CurrentPreset.RuleF;
      'X': NextStr := NextStr + CurrentPreset.RuleX;
    else
      NextStr := NextStr + C;
    end;
  end;
  CurrentString := NextStr;
end;

// 描画メイン
procedure Render;
var
  i: Integer;
  Stack: array of TState;
  Current: TState;
  NewX, NewY: Double;
  Progress: Double;
begin
  Ctx.ClearRect(0, 0, Canvas.Width, Canvas.Height);
  
  CurrentString := CurrentPreset.Axiom;
  for i := 1 to Depth do ApplyRules;

  Current.X := Canvas.Width / 2;
  Current.Y := CurrentPreset.InitialY;
  Current.Angle := -90; // 上向き
  Current.LineWidth := Depth * 1.5 + 1;

  Ctx.BeginPath;
  Ctx.LineCap := 'round';
  
  for i := 1 to Length(CurrentString) do
  begin
    case CurrentString[i] of
      'F': begin
        NewX := Current.X + Cos(Current.Angle * PI / 180) * CurrentPreset.InitialStep;
        NewY := Current.Y + Sin(Current.Angle * PI / 180) * CurrentPreset.InitialStep;
        
        Ctx.BeginPath;
        Ctx.MoveTo(Current.X, Current.Y);
        Ctx.LineTo(NewX, NewY);
        
        // 先端ほど細く、緑色にする演出
        Progress := i / Length(CurrentString);
        Ctx.LineWidth := Current.LineWidth;
        if CurrentPreset.RuleX <> '' then
          Ctx.StrokeStyle := 'rgb(' + IntToStr(Round(100 * (1-Progress))) + ', ' + IntToStr(Round(100 + 155 * Progress)) + ', 50)'
        else
          Ctx.StrokeStyle := '#333';
          
        Ctx.Stroke;
        
        Current.X := NewX;
        Current.Y := NewY;
      end;
      '+': Current.Angle := Current.Angle + CurrentPreset.Angle;
      '-': Current.Angle := Current.Angle - CurrentPreset.Angle;
      '[': begin
        SetLength(Stack, Length(Stack) + 1);
        Stack[High(Stack)] := Current;
        Current.LineWidth := Current.LineWidth * 0.7; // 枝分かれで細く
      end;
      ']': begin
        Current := Stack[High(Stack)];
        SetLength(Stack, Length(Stack) - 1);
      end;
    end;
  end;
  document.GetElementById('status').InnerHTML := '生成文字列長: ' + IntToStr(Length(CurrentString));
end;

// イベントハンドラ
function HandleInput(Event: TEventListenerEvent): Boolean;
begin
  Depth := StrToInt(TJSHTMLInputElement(document.GetElementById('depthRange')).Value);
  document.GetElementById('depthVal').InnerHTML := IntToStr(Depth);
  Render;
  Result := True;
end;

function HandleSelect(Event: TEventListenerEvent): Boolean;
begin
  SetPreset(TJSHTMLSelectElement(TJSHTMLElement(Event.Target)).Value);
  Render;
  Result := True;
end;

// メインエントリ
begin
  Canvas := TJSHTMLCanvasElement(document.GetElementById('mainCanvas'));
  Ctx := TJSCanvasRenderingContext2D(Canvas.GetContext('2d'));

  TJSHTMLInputElement(document.GetElementById('depthRange')).OnInput := @HandleInput;
  TJSHTMLSelectElement(document.GetElementById('presetSelect')).OnChange := @HandleSelect;

  // 初期化
  SetPreset('tree');
  Render;
end.