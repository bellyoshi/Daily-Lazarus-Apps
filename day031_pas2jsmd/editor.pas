program editor;

{$mode objfpc}{$H+}

uses
  web, sysutils, js;

var
  EditorElem: TJSHTMLTextAreaElement;
  PreviewElem: TJSHTMLElement;

function ParseMarkdown(src: string): string;
var
  Lines: TStringArray;
  i: Integer;
  Line: string;
  InList: Boolean;
begin
  Result := '';
  InList := False;
  Lines := TJSString(src).split(#10); 
  
  for i := 0 to High(Lines) do
  begin
    Line := Lines[i];

    // 1. 水平線
    if Line = '---' then
    begin
      Line := '<hr />';
    end
    else
    // 2. 見出し
    if (Length(Line) > 0) and (Line[1] = '#') then
    begin
      if Copy(Line, 1, 2) = '# ' then Line := '<h1>' + Copy(Line, 3, Length(Line)) + '</h1>'
      else if Copy(Line, 1, 3) = '## ' then Line := '<h2>' + Copy(Line, 4, Length(Line)) + '</h2>';
    end
    else
    // 3. リスト (簡易版)
    if (Length(Line) >= 2) and ((Line[1] = '*') or (Line[1] = '-')) and (Line[2] = ' ') then
    begin
      Line := '<li>' + Copy(Line, 3, Length(Line)) + '</li>';
    end;

    // 4. 強調とリンク (インライン要素)
    Line := TJSString(Line).replace(TJSRegExp.New('\*\*(.*?)\*\*', 'g'), '<strong>$1</strong>');
    Line := TJSString(Line).replace(TJSRegExp.New('\[(.*?)\]\((.*?)\)', 'g'), '<a href="$2" target="_blank">$1</a>');

    // 5. 段落処理
    if (Pos('<', Line) <> 1) and (Trim(Line) <> '') then
      Line := '<p>' + Line + '</p>';

    Result := Result + Line + #10;
  end;
end;

function DoUpdate(Event: TJSEvent): boolean;
begin
  if Assigned(EditorElem) and Assigned(PreviewElem) then
    PreviewElem.innerHTML := ParseMarkdown(EditorElem.value);
  Result := True;
end;

begin
  EditorElem := TJSHTMLTextAreaElement(document.getElementById('editor'));
  PreviewElem := TJSHTMLElement(document.getElementById('preview'));

  if Assigned(EditorElem) then 
    EditorElem.oninput := @DoUpdate;

end.