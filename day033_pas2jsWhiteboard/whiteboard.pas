program whiteboard;

{$mode objfpc}{$H+}

uses
  browserapp, JS, Web, sysutils, Math;

type
  { 図形の基底クラス }
  TShape = class
    X, Y, W, H: Integer;
    Color: String;
    constructor Create(AX, AY, AW, AH: Integer; AColor: String);
    procedure Draw(Ctx: TJSCanvasRenderingContext2D); virtual; abstract;
    function Contains(PX, PY: Integer): Boolean; virtual;
  end;

  { 矩形クラス }
  TRectangle = class(TShape)
    procedure Draw(Ctx: TJSCanvasRenderingContext2D); override;
  end;

  { 円クラス }
  TCircle = class(TShape)
    procedure Draw(Ctx: TJSCanvasRenderingContext2D); override;
    function Contains(PX, PY: Integer): Boolean; override;
  end;

  { 線クラス }
  TLine = class(TShape)
    procedure Draw(Ctx: TJSCanvasRenderingContext2D); override;
    function Contains(PX, PY: Integer): Boolean; override;
  end;

  TToolMode = (tmSelect, tmRect, tmCircle, tmLine);

{ --- TShape の実装 --- }
constructor TShape.Create(AX, AY, AW, AH: Integer; AColor: String);
begin
  X := AX; Y := AY; W := AW; H := AH; Color := AColor;
end;

function TShape.Contains(PX, PY: Integer): Boolean;
begin
  Result := (PX >= X) and (PX <= X + W) and (PY >= Y) and (PY <= Y + H);
end;

{ --- TRectangle の実装 --- }
procedure TRectangle.Draw(Ctx: TJSCanvasRenderingContext2D);
begin
  Ctx.fillStyle := Color;
  Ctx.fillRect(X, Y, W, H);
  Ctx.strokeStyle := 'black';
  Ctx.lineWidth := 2;
  Ctx.strokeRect(X, Y, W, H);
end;

{ --- TCircle の実装 --- }
procedure TCircle.Draw(Ctx: TJSCanvasRenderingContext2D);
var
  cx, cy, r: Double;
begin
  if (W <= 0) or (H <= 0) then Exit;
  cx := X + W / 2;
  cy := Y + H / 2;
  r := Min(W, H) / 2;
  Ctx.fillStyle := Color;
  Ctx.beginPath;
  Ctx.arc(cx, cy, r, 0, 2 * Pi, false);
  Ctx.fill;
  Ctx.strokeStyle := 'black';
  Ctx.lineWidth := 2;
  Ctx.stroke;
end;

function TCircle.Contains(PX, PY: Integer): Boolean;
var
  cx, cy, r, dx, dy: Double;
begin
  if (W <= 0) or (H <= 0) then Exit(False);
  cx := X + W / 2;
  cy := Y + H / 2;
  r := Min(W, H) / 2;
  dx := PX - cx;
  dy := PY - cy;
  Result := (dx * dx + dy * dy) <= (r * r);
end;

{ --- TLine の実装 --- }
procedure TLine.Draw(Ctx: TJSCanvasRenderingContext2D);
begin
  Ctx.strokeStyle := Color;
  Ctx.lineWidth := 3;
  Ctx.beginPath;
  Ctx.moveTo(X, Y);
  Ctx.lineTo(X + W, Y + H);
  Ctx.stroke;
end;

function TLine.Contains(PX, PY: Integer): Boolean;
const
  HitPad = 6;
var
  x1, y1, x2, y2, l, r, t, b: Integer;
begin
  x1 := X;
  y1 := Y;
  x2 := X + W;
  y2 := Y + H;
  l := Min(x1, x2) - HitPad;
  r := Max(x1, x2) + HitPad;
  t := Min(y1, y2) - HitPad;
  b := Max(y1, y2) + HitPad;
  Result := (PX >= l) and (PX <= r) and (PY >= t) and (PY <= b);
end;

var
  Canvas: TJSHTMLCanvasElement;
  Ctx: TJSCanvasRenderingContext2D;
  Shapes: array of TShape;
  SelectedShape: TShape = nil;
  OffsetX, OffsetY: Integer;
  CurrentTool: TToolMode = tmSelect;
  IsDrawing: Boolean = False;
  DragStartX, DragStartY: Integer;
  PreviewW, PreviewH: Integer;
  DefaultColor: String = 'skyblue';

{ プレビュー描画（ドラッグ中の仮形） }
procedure DrawPreview;
var
  x0, y0, w, h: Integer;
  cx, cy, r: Double;
begin
  x0 := Min(DragStartX, DragStartX + PreviewW);
  y0 := Min(DragStartY, DragStartY + PreviewH);
  w := Abs(PreviewW);
  h := Abs(PreviewH);
  Ctx.strokeStyle := 'gray';
  Ctx.lineWidth := 2;
  case CurrentTool of
    tmRect:
      begin
        Ctx.strokeRect(x0, y0, w, h);
      end;
    tmCircle:
      begin
        if (w > 0) and (h > 0) then
        begin
          cx := x0 + w / 2;
          cy := y0 + h / 2;
          r := Min(w, h) / 2;
          Ctx.beginPath;
          Ctx.arc(cx, cy, r, 0, 2 * Pi, false);
          Ctx.stroke;
        end;
      end;
    tmLine:
      begin
        Ctx.beginPath;
        Ctx.moveTo(DragStartX, DragStartY);
        Ctx.lineTo(DragStartX + PreviewW, DragStartY + PreviewH);
        Ctx.stroke;
      end;
    else ;
  end;
end;

{ 全描画リフレッシュ }
procedure Render;
var
  s: TShape;
begin
  Ctx.clearRect(0, 0, Canvas.width, Canvas.height);
  for s in Shapes do s.Draw(Ctx);
  if IsDrawing then DrawPreview;
end;

{ マウスイベントハンドラ }
function MouseDown(Event: TJSMouseEvent): boolean;
var
  i: Integer;
  Rect: TJSDOMRect;
  MX, MY: Integer;
begin
  Rect := Canvas.getBoundingClientRect;
  MX := Round(Event.clientX - Rect.left);
  MY := Round(Event.clientY - Rect.top);

  if CurrentTool = tmSelect then
  begin
    SelectedShape := nil;
    for i := High(Shapes) downto Low(Shapes) do
    begin
      if Shapes[i].Contains(MX, MY) then
      begin
        SelectedShape := Shapes[i];
        OffsetX := MX - SelectedShape.X;
        OffsetY := MY - SelectedShape.Y;
        Break;
      end;
    end;
  end
  else
  begin
    { 四角・丸・線：ドラッグ開始 }
    IsDrawing := True;
    DragStartX := MX;
    DragStartY := MY;
    PreviewW := 0;
    PreviewH := 0;
  end;
  Result := False;
end;

function MouseMove(Event: TJSMouseEvent): boolean;
var
  Rect: TJSDOMRect;
  MX, MY: Integer;
begin
  Rect := Canvas.getBoundingClientRect;
  MX := Round(Event.clientX - Rect.left);
  MY := Round(Event.clientY - Rect.top);
  if IsDrawing then
  begin
    PreviewW := MX - DragStartX;
    PreviewH := MY - DragStartY;
    Render;
  end
  else if SelectedShape <> nil then
  begin
    SelectedShape.X := MX - OffsetX;
    SelectedShape.Y := MY - OffsetY;
    Render;
  end;
  Result := False;
end;

function MouseUp(Event: TJSMouseEvent): boolean;
var
  n: Integer;
  x0, y0, w, h: Integer;
begin
  if IsDrawing then
  begin
    w := PreviewW;
    h := PreviewH;
    { 最小サイズチェック（線は除く） }
    if (CurrentTool = tmRect) or (CurrentTool = tmCircle) then
    begin
      if (Abs(w) < 4) and (Abs(h) < 4) then
      begin
        IsDrawing := False;
        Result := False;
        Exit;
      end;
      x0 := Min(DragStartX, DragStartX + w);
      y0 := Min(DragStartY, DragStartY + h);
      w := Abs(w);
      h := Abs(h);
    end
    else
    begin
      x0 := DragStartX;
      y0 := DragStartY;
    end;
    n := Length(Shapes);
    SetLength(Shapes, n + 1);
    case CurrentTool of
      tmRect:  Shapes[n] := TRectangle.Create(x0, y0, w, h, DefaultColor);
      tmCircle: Shapes[n] := TCircle.Create(x0, y0, w, h, DefaultColor);
      tmLine:   Shapes[n] := TLine.Create(x0, y0, w, h, DefaultColor);
      else ;
    end;
    IsDrawing := False;
    Render;
  end
  else
    SelectedShape := nil;
  Result := False;
end;

{ パレット：ツール切り替え }
procedure SetToolSelect; begin CurrentTool := tmSelect; end;
procedure SetToolRect;   begin CurrentTool := tmRect;   end;
procedure SetToolCircle; begin CurrentTool := tmCircle; end;
procedure SetToolLine;   begin CurrentTool := tmLine;   end;

procedure UpdatePaletteUI;
var
  el: TJSHTMLElement;
begin
  el := TJSHTMLElement(document.getElementById('btnSelect'));
  el.classList.remove('active');
  el := TJSHTMLElement(document.getElementById('btnRect'));
  el.classList.remove('active');
  el := TJSHTMLElement(document.getElementById('btnCircle'));
  el.classList.remove('active');
  el := TJSHTMLElement(document.getElementById('btnLine'));
  el.classList.remove('active');
  case CurrentTool of
    tmSelect: TJSHTMLElement(document.getElementById('btnSelect')).classList.add('active');
    tmRect:   TJSHTMLElement(document.getElementById('btnRect')).classList.add('active');
    tmCircle: TJSHTMLElement(document.getElementById('btnCircle')).classList.add('active');
    tmLine:   TJSHTMLElement(document.getElementById('btnLine')).classList.add('active');
    else ;
  end;
end;

procedure ToolSelectClick(Event: TJSEvent); begin SetToolSelect; UpdatePaletteUI; end;
procedure ToolRectClick(Event: TJSEvent);   begin SetToolRect;   UpdatePaletteUI; end;
procedure ToolCircleClick(Event: TJSEvent); begin SetToolCircle; UpdatePaletteUI; end;
procedure ToolLineClick(Event: TJSEvent);  begin SetToolLine;   UpdatePaletteUI; end;

{ 色パレット：選択した色を新規図形に適用 }
procedure UpdateColorPreview;
begin
  TJSHTMLElement(document.getElementById('colorPreview')).style.setProperty('background-color', DefaultColor);
end;

procedure ColorSwatchClick(Event: TJSEvent);
var
  el: TJSHTMLElement;
  c: String;
  i: Integer;
  swatches: TJSNodeList;
begin
  el := TJSHTMLElement(TJSEvent(Event).target);
  if el.classList.contains('color-swatch') then
  begin
    c := el.getAttribute('data-color');
    if c <> '' then
    begin
      DefaultColor := c;
      UpdateColorPreview;
      swatches := document.querySelectorAll('.color-swatch');
      for i := 0 to swatches.length - 1 do
        TJSHTMLElement(swatches[i]).classList.remove('active');
      el.classList.add('active');
    end;
  end;
end;

begin
  { 初期化 }
  Canvas := TJSHTMLCanvasElement(document.getElementById('paintCanvas'));
  Ctx := TJSCanvasRenderingContext2D(Canvas.getContext('2d'));
  SetLength(Shapes, 0);

  { パレットボタンにツールを割り当て }
  document.getElementById('btnSelect').addEventListener('click', @ToolSelectClick);
  document.getElementById('btnRect').addEventListener('click', @ToolRectClick);
  document.getElementById('btnCircle').addEventListener('click', @ToolCircleClick);
  document.getElementById('btnLine').addEventListener('click', @ToolLineClick);

  { 色パレット（親にリスナーを付け、クリックで色を切り替え） }
  document.getElementById('colorPalette').addEventListener('click', @ColorSwatchClick);
  UpdateColorPreview;

  { キャンバス・ウィンドウのイベント登録 }
  Canvas.onmousedown := @MouseDown;
  window.onmousemove := @MouseMove;
  window.onmouseup := @MouseUp;

  UpdatePaletteUI;
  Render;
end.