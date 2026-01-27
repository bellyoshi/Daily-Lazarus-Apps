program todo;

uses
  Web, sysutils, JS;

var
  InputText: TJSHTMLInputElement;
  AddButton: TJSHTMLElement;
  TodoList: TJSHTMLElement;

function AddTodo(Event: TJSEvent): boolean;
var
  ListItem, SpanText, DeleteBtn: TJSHTMLElement;
  CheckBox: TJSHTMLInputElement;
  TaskText: string;
begin
  Result := True;
  TaskText := InputText.Value;
  if TaskText = '' then Exit;

  ListItem := TJSHTMLElement(document.createElement('li'));

  CheckBox := TJSHTMLInputElement(document.createElement('input'));
  TJSObject(CheckBox)['type'] := 'checkbox';
  
  SpanText := TJSHTMLElement(document.createElement('span'));
  SpanText.innerText := ' ' + TaskText + ' ';

  DeleteBtn := TJSHTMLElement(document.createElement('button'));
  DeleteBtn.innerText := '削除';

  TJSObject(CheckBox)['onchange'] := function(E: TJSEvent): boolean
    begin
      if CheckBox.checked then
        SpanText.style.setProperty('text-decoration', 'line-through')
      else
        SpanText.style.setProperty('text-decoration', 'none');
      Result := True;
    end;

  TJSObject(DeleteBtn)['onclick'] := function(E: TJSEvent): boolean
    begin
      ListItem.remove;
      Result := True;
    end;

  ListItem.appendChild(CheckBox);
  ListItem.appendChild(SpanText);
  ListItem.appendChild(DeleteBtn);
  TodoList.appendChild(ListItem);

  InputText.Value := '';
  InputText.focus;
end;

// キー入力を判定する関数（TJSObjectでkeyCodeを取得）
function HandleKeyPress(Event: TJSEvent): boolean;
begin
  Result := True;
  // EventをTJSObjectとして扱い、'keyCode' または 'key' にアクセス
  if (TJSObject(Event)['keyCode'] = 13) or (TJSObject(Event)['key'] = 'Enter') then
    AddTodo(Event);
end;

begin
  document.body.insertAdjacentHTML('afterbegin', '<h1>Pascal Todo App</h1>');

  InputText := TJSHTMLInputElement(document.createElement('input'));
  InputText.placeholder := 'タスクを入力してEnter...';
  
  // イベント登録もTJSObject経由で確実に
  TJSObject(InputText)['onkeypress'] := @HandleKeyPress;
  document.body.appendChild(InputText);

  AddButton := TJSHTMLElement(document.createElement('button'));
  AddButton.innerText := '追加';
  TJSObject(AddButton)['onclick'] := @AddTodo;
  document.body.appendChild(AddButton);

  TodoList := TJSHTMLElement(document.createElement('ul'));
  document.body.appendChild(TodoList);
end.