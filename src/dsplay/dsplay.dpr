// Copyright (C) 2013 Igor Afanasyev, https://github.com/iafan/Hacksby

program dsplay;

// Uses DirectX 9 units from
// http://clootie.ru/delphi/download_dx92.html

{$APPTYPE CONSOLE}

uses
  Classes,
  DirectSound,
  MMSystem,
  SysUtils,
  Windows;

const
  SLEEP_EXTRA_TIME_BEFORE_CLOSE = 40; // ms

var
  FileName: String;
  DirectSound: IDirectSound = nil;
  PrimarySoundBuffer: IDirectSoundBuffer = nil;
  SecondarySoundBuffer: IDirectSoundBuffer = nil;
  Status: DWord;

procedure WriteDataToBuffer(
  Buffer: IDirectSoundBuffer; OffSet: DWord; var SoundData;
  SoundBytes: DWord);
const
  LockErrorMessage = 'DirectSoundBuffer.Lock failed';
var
  AudioPtr1, AudioPtr2: Pointer;
  AudioBytes1, AudioBytes2: DWord;
  h: HResult;
  Temp: Pointer;
begin
  H := Buffer.Lock(OffSet, SoundBytes, @AudioPtr1, @AudioBytes1, @AudioPtr2, @AudioBytes2, 0(*DSBLOCK_ENTIREBUFFER*));

  if H = DSERR_BUFFERLOST then
  begin
    Buffer.Restore;
    if Buffer.Lock(OffSet, SoundBytes, @AudioPtr1, @AudioBytes1, @AudioPtr2, @AudioBytes2, 0) <> DS_OK then
      raise Exception.Create(LockErrorMessage);
  end else
  if H <> DS_OK then
    raise Exception.Create(LockErrorMessage);

  Temp := @SoundData;
  Move(Temp^, AudioPtr1^, AudioBytes1);

  if AudioPtr2 <> nil then
  begin
    Temp := @SoundData; Inc(Integer(Temp), AudioBytes1);
    Move(Temp^, AudioPtr2^, AudioBytes2);
  end;

  if Buffer.UnLock(AudioPtr1, AudioBytes1, AudioPtr2, AudioBytes2) <> DS_OK then
    raise Exception.Create(LockErrorMessage);
end;

procedure CreateWritePrimaryBuffer;
var
  Handle: THandle;
  BufferDesc: DSBUFFERDESC;
  PCM: TWaveFormatEx;
begin
  FillChar(BufferDesc, SizeOf(DSBUFFERDESC), 0);
  FillChar(PCM, SizeOf(TWaveFormatEx), 0);
  with BufferDesc do
  begin
    PCM.wFormatTag := WAVE_FORMAT_PCM;
    PCM.nChannels := 2;
    PCM.nSamplesPerSec := 44100;
    PCM.nBlockAlign := 4;
    PCM.nAvgBytesPerSec := PCM.nSamplesPerSec * PCM.nBlockAlign;
    PCM.wBitsPerSample := 16;
    PCM.cbSize := 0;
    dwSize := SizeOf(DSBUFFERDESC);
    dwFlags := DSBCAPS_PRIMARYBUFFER;
    dwBufferBytes := 0;
    lpwfxFormat := nil;
  end;

  Handle := GetForegroundWindow();
  if (Handle = 0) then
    Handle := GetDesktopWindow();

  if DirectSound.SetCooperativeLevel(Handle, DSSCL_WRITEPRIMARY) <> DS_OK then
    raise Exception.Create('DirectSound.SetCooperativeLevel(DSSCL_WRITEPRIMARY) failed');

  if DirectSound.CreateSoundBuffer(BufferDesc, PrimarySoundBuffer, nil) <> DS_OK then
    raise Exception.Create('DirectSound.CreateSoundBuffer failed');

  if PrimarySoundBuffer.SetFormat(Addr(PCM)) <> DS_OK then
    raise Exception.Create('PrimarySoundBuffer.SetFormat failed');

  if DirectSound.SetCooperativeLevel(Handle, DSSCL_NORMAL) <> DS_OK then
    raise Exception.Create('DirectSound.SetCooperativeLevel(DSSCL_NORMAL) failed');
end;

procedure CreateWriteSecondaryBuffer(
  var Buffer: IDirectSoundBuffer; SamplesPerSec: Integer;
  Bits: Word; isStereo: Boolean; SizeInBytes: Integer);

var
  BufferDesc: DSBUFFERDESC;
  PCM: TWaveFormatEx;
begin
  FillChar(BufferDesc, SizeOf(DSBUFFERDESC), 0);
  FillChar(PCM, SizeOf(TWaveFormatEx), 0);

  with BufferDesc do
  begin
    PCM.wFormatTag := WAVE_FORMAT_PCM;

    if isStereo then
      PCM.nChannels := 2
    else
      PCM.nChannels := 1;

    PCM.nSamplesPerSec := SamplesPerSec;
    PCM.nBlockAlign := (Bits div 8) * PCM.nChannels;
    PCM.nAvgBytesPerSec := PCM.nSamplesPerSec * PCM.nBlockAlign;
    PCM.wBitsPerSample := Bits;
    PCM.cbSize := 0;

    dwSize := SizeOf(DSBUFFERDESC);
    dwFlags := DSBCAPS_STATIC;
    dwBufferBytes := SizeInBytes;//Time * PCM.nAvgBytesPerSec;
    lpwfxFormat := @PCM;
  end;

  if DirectSound.CreateSoundBuffer(BufferDesc, Buffer, nil) <> DS_OK then
    raise Exception.Create('DirectSound.CreateSoundBuffer[secondary] failed');
end;

procedure LoadWAVToSecondaryBuffer(Name: PChar; var Buffer: IDirectSoundBuffer);
var
  Data: PByteArray;
  FName: TFileStream;
  DataSize: DWord;
  Chunk: string[4];
  Pos: Integer;
begin
  FName := TFileStream.Create(Name, fmOpenRead);
  try
    Pos := 24;
    SetLength(Chunk, 4);

    repeat
      FName.Seek(Pos, soFromBeginning);
      FName.Read(Chunk[1], 4);
      Inc(Pos);
    until Chunk = 'data';

    FName.Seek(Pos + 3, soFromBeginning);
    FName.Read(DataSize, SizeOf(DWord));

    CreateWriteSecondaryBuffer(SecondarySoundBuffer, 44100, 16, False, DataSize);

    GetMem(Data, DataSize);
    try
      FName.Read(Data^, DataSize);
      WriteDataToBuffer(Buffer, 0, Data^, DataSize);
    finally
      FreeMem(Data, DataSize);
    end;
  finally
    FName.Free;
  end;
end;

begin
  FileName := Trim(ParamStr(1));
  if FileName = '' then
  begin
    WriteLn('Usage: dsplay filename.wav');
    WriteLn('The only supported format is 44100Hz 16bit mono PCM');
    Exit;
  end;

  if not FileExists(FileName) then
  begin
    WriteLn(Format('File ''%s'' doesn''t exist', [FileName]));
    Exit;
  end;

  try
    if DirectSoundCreate(nil, DirectSound, nil) <> DS_OK then
      raise Exception.Create('DirectSoundCreate failed');

    CreateWritePrimaryBuffer;
    LoadWAVToSecondaryBuffer(PWideChar(FileName), SecondarySoundBuffer);

    if SecondarySoundBuffer.Play(0, 0, 0) <> DS_OK then
      raise Exception.Create('SecondarySoundBuffer.Play failed');

    // wait till the sund has finished playing
    while True do
    begin
      Sleep(1);

      if SecondarySoundBuffer.GetStatus(Status) <> DS_OK then
        raise Exception.Create('SecondarySoundBuffer.GetStatus failed');

      if (Status <> DSBSTATUS_PLAYING) then
        Break;
    end;

    // Sleep some extra milliseconds, otherwise an audible click
    // will be heard on destroying the sound buffers
    Sleep(SLEEP_EXTRA_TIME_BEFORE_CLOSE);

  finally
    // Assign nil to variables to release their COM references
    PrimarySoundBuffer := nil;
    SecondarySoundBuffer := nil;
    DirectSound := nil;
  end;
end.

