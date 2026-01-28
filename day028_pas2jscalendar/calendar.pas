program calendar;

uses
  browserconsole, web, sysutils, dateutils;

var
  CurrentDate: TDateTime;

procedure RenderCalendar;
var
  Container, Header, BtnPrev, BtnNext, Title, Table, Row, Cell: TJSHTMLElement;
  Year, Month, Day: Word;
  FirstDayOfMonth: TDateTime;
  DaysInMonth, StartDay, d, i: Integer;
begin
  DecodeDate(CurrentDate, Year, Month, Day);
  
  // 描画エリアの初期化
  Container := TJSHTMLElement(document.getElementById('calendar-app'));
  if Container = nil then
  begin
    Container := TJSHTMLElement(document.createElement('div'));
    Container.id := 'calendar-app';
    document.body.appendChild(Container);
  end;
  Container.innerHTML := ''; // 以前の描画をクリア

  // --- ヘッダー（年月表示とボタン） ---
  Header := TJSHTMLElement(document.createElement('div'));
  
  BtnPrev := TJSHTMLElement(document.createElement('button'));
  BtnPrev.innerText := '< 前の月';
  BtnPrev.onclick := function(Event: TJSMouseEvent): boolean
  begin
    CurrentDate := IncMonth(CurrentDate, -1);
    RenderCalendar;
    Result := False;
  end;

  Title := TJSHTMLElement(document.createElement('span'));
  Title.innerText := Format(' %d年 %d月 ', [Year, Month]);
  Title.style.setProperty('font-weight', 'bold');

  BtnNext := TJSHTMLElement(document.createElement('button'));
  BtnNext.innerText := '次の月 >';
  BtnNext.onclick := function(Event: TJSMouseEvent): boolean
  begin
    CurrentDate := IncMonth(CurrentDate, 1);
    RenderCalendar;
    Result := False;
  end;

  Header.appendChild(BtnPrev);
  Header.appendChild(Title);
  Header.appendChild(BtnNext);
  Container.appendChild(Header);

  // --- カレンダー本体 ---
  Table := TJSHTMLElement(document.createElement('table'));
  Table.style.setProperty('border-collapse', 'collapse');
  Table.style.setProperty('margin-top', '10px');
  
  // その月の1日の情報
  FirstDayOfMonth := EncodeDate(Year, Month, 1);
  DaysInMonth := DaysInAMonth(Year, Month);
  StartDay := DayOfWeek(FirstDayOfMonth); // 1:日, 2:月...

  // 曜日の行
  Row := TJSHTMLElement(document.createElement('tr'));
  for i := 1 to 7 do
  begin
    Cell := TJSHTMLElement(document.createElement('th'));
    Cell.innerText := FormatSettings.ShortDayNames[i];
    Cell.style.setProperty('border', '1px solid #ccc');
    Cell.style.setProperty('padding', '5px');
    Row.appendChild(Cell);
  end;
  Table.appendChild(Row);

  // 日付の行
  Row := TJSHTMLElement(document.createElement('tr'));
  for i := 1 to StartDay - 1 do
  begin
    Cell := TJSHTMLElement(document.createElement('td'));
    Cell.style.setProperty('border', '1px solid #ccc');
    Row.appendChild(Cell);
  end;

  for d := 1 to DaysInMonth do
  begin
    Cell := TJSHTMLElement(document.createElement('td'));
    Cell.innerText := IntToStr(d);
    Cell.style.setProperty('border', '1px solid #ccc');
    Cell.style.setProperty('padding', '10px');
    Cell.style.setProperty('text-align', 'center');
    
    Row.appendChild(Cell);

    if ((d + StartDay - 1) mod 7 = 0) and (d < DaysInMonth) then
    begin
      Table.appendChild(Row);
      Row := TJSHTMLElement(document.createElement('tr'));
    end;
  end;
  
  Table.appendChild(Row);
  Container.appendChild(Table);
end;

begin
  CurrentDate := Now;
  RenderCalendar;
end.