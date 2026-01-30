program color;

uses
  web, sysutils;

var
  InputBox: TJSHTMLInputElement;
  ColorDisplay: TJSHTMLElement;

procedure HandleInput(Event: TJSEvent);
begin
  // 入力された値を背景色に反映
  ColorDisplay.style.setProperty('background-color', InputBox.value);
end;

procedure DocumentLoaded(Event: TJSEvent);
var
  Container: TJSHTMLElement;
begin
  Container := TJSHTMLElement(document.createElement('div'));
  Container.style.setProperty('text-align', 'center');
  Container.style.setProperty('margin-top', '50px');
  document.body.appendChild(Container);

  InputBox := TJSHTMLInputElement(document.createElement('input'));
  // Error回避: setAttribute を使用して type を指定
  InputBox.setAttribute('type', 'text');
  InputBox.setAttribute('placeholder', '#RRGGBB or color name');
  
  InputBox.style.setProperty('padding', '10px');
  InputBox.style.setProperty('font-size', '18px');
  Container.appendChild(InputBox);

  ColorDisplay := TJSHTMLElement(document.createElement('div'));
  ColorDisplay.style.setProperty('width', '200px');
  ColorDisplay.style.setProperty('height', '200px');
  ColorDisplay.style.setProperty('margin', '20px auto');
  ColorDisplay.style.setProperty('border', '2px solid #333');
  ColorDisplay.style.setProperty('transition', 'background-color 0.3s'); // おまけ：アニメーション
  ColorDisplay.style.setProperty('background-color', '#ccc');
  Container.appendChild(ColorDisplay);

  InputBox.addEventListener('input', @HandleInput);
end;

begin
  window.addEventListener('load', @DocumentLoaded);
end.