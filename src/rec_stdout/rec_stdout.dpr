// Copyright (C) 2013 Igor Afanasyev, https://github.com/iafan/Hacksby

program rec_stdout;

// Uses freeware Wave Audio Package components from
// http://www.delphiarea.com/products/delphi-packages/waveaudio/

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  WaveUtils,
  WaveRecorders,
  Windows;

type
  TDataHandler = class(TObject)
    procedure LiveAudioRecorderData(Sender: TObject; const Buffer: Pointer;
      BufferSize: Cardinal; var FreeIt: Boolean);
  end;

var
  r: TLiveAudioRecorder;
  s: THandleStream;
  h: TDataHandler;

  NeedQuit: Boolean = false;

procedure TDataHandler.LiveAudioRecorderData(Sender: TObject; const Buffer: Pointer;
  BufferSize: Cardinal; var FreeIt: Boolean);
var
  i: Integer;
begin
  FreeIt := True;
  try
    s.WriteBuffer(Buffer^, BufferSize);
  except
    NeedQuit := true;
  end;
end;

procedure DispatchMessageLoop;
var
  Msg: TMsg;
begin
  while not NeedQuit and GetMessage(Msg, 0, 0, 0) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
    Sleep(0);
  end;
end;

begin
  try
    s := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE));
    h := TDataHandler.Create;
    r := TLiveAudioRecorder.Create(nil);
    r.PCMFormat := Mono16bit44100Hz;
    r.BufferLength := 100; // 100ms
    r.OnData := h.LiveAudioRecorderData;
    r.Active := true;
    DispatchMessageLoop;
    r.Active := false;
    r.WaitForStop;
  finally
    r.Free;
    h.Free;
    s.Free;
  end;
end.
