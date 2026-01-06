unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, DateUtils;

type

  { TForm1 }

  TForm1 = class(TForm)
    Image1: TImage;
    LabelLondon: TLabel;
    LabelNewYork: TLabel;
    LabelTokyo: TLabel;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure UpdateClocks;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Set form size to match the map
  ClientWidth := 800;
  ClientHeight := 400;
  Caption := 'World Clock - Day 006';

  // Load the map image
  if FileExists('world_map.bmp') then
    Image1.Picture.LoadFromFile('world_map.bmp')
  else
    ShowMessage('world_map.bmp not found!');

  // Initial update
  UpdateClocks;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  UpdateClocks;
end;

procedure TForm1.UpdateClocks;
var
  UTCTime: TDateTime;
begin
  // Get current UTC time
  // Note: specific timezone handling involves more complex libraries, 
  // keeping it simple with fixed offsets for this exercise.
  // Ideally use GetLocalTime and Convert with TimeZone info.
  // For now, assuming user system time is valid and we calculate from UTC.
  // But Lazarus DateUtils doesn't have robust TimeZone conversion out of the box without libs independently.
  // We'll approximate from LocalTime if we consider the user is in Japan (based on request language/TZ).
  // Actually, easiest is to get UTC time.
  
  UTCTime := LocalTimeToUniversal(Now);

  LabelTokyo.Caption := 'Tokyo' + sLineBreak + FormatDateTime('hh:nn:ss', IncHour(UTCTime, 9));
  LabelLondon.Caption := 'London' + sLineBreak + FormatDateTime('hh:nn:ss', UTCTime);
  LabelNewYork.Caption := 'New York' + sLineBreak + FormatDateTime('hh:nn:ss', IncHour(UTCTime, -5));
end;

end.
