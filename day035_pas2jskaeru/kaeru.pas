program kaeru;

uses
  web, js, webaudio;

type
  TNote = record
    Freq: Double;
    Len: Double;
  end;

var
  AudioCtx: TJSAudioContext;

const
  // 周波数
  C=261.63; D=293.66; E=329.63; F=349.23; G=392.00; A=440.00;
  
  MELODY: array[0..31] of TNote = (
    (Freq: C; Len: 1.0), (Freq: D; Len: 1.0), (Freq: E; Len: 1.0), (Freq: F; Len: 1.0),
    (Freq: E; Len: 1.0), (Freq: D; Len: 1.0), (Freq: C; Len: 1.0), (Freq: 0; Len: 1.0),
    (Freq: E; Len: 1.0), (Freq: F; Len: 1.0), (Freq: G; Len: 1.0), (Freq: A; Len: 1.0),
    (Freq: G; Len: 1.0), (Freq: F; Len: 1.0), (Freq: E; Len: 1.0), (Freq: 0; Len: 1.0),
    (Freq: C; Len: 2.0), (Freq: C; Len: 2.0), (Freq: C; Len: 2.0), (Freq: C; Len: 2.0),
    (Freq: C; Len: 0.5), (Freq: C; Len: 0.5), (Freq: D; Len: 0.5), (Freq: D; Len: 0.5),
    (Freq: E; Len: 0.5), (Freq: E; Len: 0.5), (Freq: F; Len: 0.5), (Freq: F; Len: 0.5),
    (Freq: E; Len: 1.0), (Freq: D; Len: 1.0), (Freq: C; Len: 1.0), (Freq: 0; Len: 1.0)
  );

procedure PlayNote(Freq: Double; StartTime, Duration, Vol: Double);
var
  Osc: TJSOscillatorNode;
  Gain: TJSGainNode;
begin
  Osc := AudioCtx.createOscillator;
  Gain := AudioCtx.createGain;
  
  Osc.connect(Gain);
  Gain.connect(AudioCtx.destination);
  
  Osc.type_ := 'triangle';
  Osc.frequency.setValueAtTime(Freq, StartTime);
  
  // エンベロープ制御（プツプツ音の防止と減衰）
  Gain.gain.setValueAtTime(0, StartTime);
  Gain.gain.linearRampToValueAtTime(Vol, StartTime + 0.05);
  Gain.gain.exponentialRampToValueAtTime(0.001, StartTime + Duration);
  
  Osc.start(StartTime);
  Osc.stop(StartTime + Duration);
end;

procedure PlayPart(StartTime: Double; Vol: Double);
var
  CurrentTime: Double;
  Tempo: Double;
  I: Integer;
begin
  Tempo := 0.4; // 1拍の長さ
  CurrentTime := StartTime;
  
  for I := Low(MELODY) to High(MELODY) do
  begin
    if MELODY[I].Freq > 0 then
      PlayNote(MELODY[I].Freq, CurrentTime, MELODY[I].Len * Tempo, Vol);
    
    CurrentTime := CurrentTime + (MELODY[I].Len * Tempo);
  end;
end;

// JSから呼ばれるエクスポート関数
procedure StartRinsho;
var
  BaseTime: Double;
begin
  if AudioCtx = nil then
    AudioCtx := TJSAudioContext.New;
    
  if AudioCtx.state = 'suspended' then
    AudioCtx.resume;

  BaseTime := AudioCtx.currentTime + 0.1;
  
  // 輪唱：8拍（約3.2秒）ずつずらして3パート演奏
  PlayPart(BaseTime, 0.3);
  PlayPart(BaseTime + (8 * 0.4), 0.2);
  PlayPart(BaseTime + (16 * 0.4), 0.1);
end;

// HTMLのボタンから呼べるようにwindowオブジェクトに登録
begin
  window['StartRinsho'] := @StartRinsho;
end.