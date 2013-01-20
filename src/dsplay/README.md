dsplay.exe is a simple console utility to play WAV files using DirectSound. The only supported format is 44100Hz 16bit mono PCM.
The reason behind using this utility is that the playback of high-pitch sound commands via DirectSound
is much smoother (no audible clicks can be heared) than via using any other old-fashioned Windows audio APIs.

Usage: dsplay.exe filename.wav
