program project1;

uses
  browserapp, JS, Web, sysutils;

var
  StartDateInput: TJSHTMLInputElement;
  DisplaySpan: TJSHTMLElement;

procedure CalculateDays(Event: TJSEvent);
var
  StartDate, Today: TDateTime;
  Diff: Integer;
  S: string;
  y, m, d: Integer;
begin
  try
    S := StartDateInput.Value;
    // YYYY-MM-DD を手動でパース
    y := StrToInt(Copy(S, 1, 4));
    m := StrToInt(Copy(S, 6, 2));
    d := StrToInt(Copy(S, 9, 2));
    StartDate := EncodeDate(y, m, d);
    Today := Date;
    Diff := Trunc(Today - StartDate) + 1;
    DisplaySpan.innerText := IntToStr(Diff);
  except
    DisplaySpan.innerText := '--';
  end;
end;

procedure Initialize;
begin
  StartDateInput := TJSHTMLInputElement(document.getElementById('start-date'));
  DisplaySpan := TJSHTMLElement(document.getElementById('day-count'));

  // 今年の一月一日をセット
  StartDateInput.Value := FormatDateTime('YYYY', Date) + '-01-01';

  StartDateInput.addEventListener('change', @CalculateDays);
  CalculateDays(nil);
end;

begin
  window.addEventListener('load', @Initialize);
end.