About Hacksby
=============

### Hacksby = Hack-a-Furby project

Hasbro's Furby toy (year 2012 model) uses audio protocol to communicate with other
nearby Furbys and with the official 'Furby' applications for iOS and Android.

This project is an educational attempt to analyze and re-create the audio protocol
and communicate with Furby using computer in a search for some easter eggs or
otherwise undocumented features.

At its current state, the project includes:

 1. Description on the audio protocol (see below)
 2. [An incomplete] description of various Furby commands
 3. An Perl library and scripts that can generate and play WAV files
    with arbitrary commands (to talk to Furby)
 4. A script that can decode commands from a provided audio stream
    (to interpret Furby's responses).


Disclaimer
==========

### This information is provided for personal educational purposes only.
### The author does not guarantee the accuracy of this information.
### By using the provided information, libraries or software, you solely take the risks of damaging your hardware or your ears.

See `MIT-LICENSE.txt` for more information.


Audio Protocol
==============

Furby audio protocol uses high-pitch frequencies to encode special commands (command
is an integer number in [0..1023] range). Furby decodes such commands using its built-in
microphone and may respond to some of them. When an event occurs (Furby pronounces
some phrase or performs an action), he can also emit such a command in addition to
an audible sound. This feature is used in the official application 'Translator'
mode, when it recognizes what Furby said and provides an instant translation.

Each command is divided into two packages with 0.5 sec gap in between.
The first package carries the higher 5 bits of the command number, and the second one
carries the lower 5 bits. 

If you record the responce from Furby or from iOS application and view its spectrum,
You will see that each packet looks like this: 

    2  --------##--------------------------------------##----
    3  ----##----------------------##--##----------##--------
    X  --##--##--##--##--##--##--##--##--##--##--##--##--##--
    1  --------------------##--------------##----------------
    0  ------------##--##------##--------------##------------

The total length of the packet is 0.5 second. Here `X` is a central frequency (17500 Hz),
and `0`, `1`, `2` and `3` are the data frequencies. The distance between each adjacent frequency
is approx. 557 Hz.

The central frequency carries no data and was likely introduce to aid in packet decoding.
The other four frequencies carry data. If one writes down the packet depicted above as a number in the
quaternary numeral system using 0, 1, 2, 3 digits after the name of each frequency, he would
get the following number: `3200 1033 1032` (for clarity, the number is separated into three quadruplets
each representing a byte).

The first byte, `3200`, if written in the binary form, will look like this: `11 1 00000`, where the first
two bits are always `11`, the second bit will be `0` for the first packet and `1` for the second, and
the remainder `00000` represents the 5 data bits themselves.

The second byte, `1033`, depends on the data bits and is used as a checksum (original algorithm is unknown).
The `lib/Furby/Packet.pm` file lists all 64 checksums (32 for the first packet and 32 for the second) needed
to reconstruct any arbitrary command in [0..1023] range.

The last byte, `1032`, is always the same.

To eliminate ticks when playing back such audio packets, the original waveform uses smooth changes in
frequency between each data tone. Also, such frequencies are not noticable if combined with pretty loud
audible responses Furby generates at the same time.


Commands
========

Based on initial research, a list of known commands (or events) and their descriptions is provided in
`lib/Furby/Commands.pm` and `lib/Furby/Dictionary.pm`. The list is incomplete and the already existing
descriptions may be inaccurate.

The task of interpreting the meaning of the commands is complicated further by the fact that Furby
can be in one of 6 personalities, and depending on its current personality, may respond to commands
differently and produce different events on its own.

### Furby Personality

When Furby understands a command, it will respond back with his current personality id.
Known personalities (as listed in official Android application) are:

  1. Princess (command id `901`) — a lovable one
  2. Diva (command id `902`) — a musical one
  3. Warrior (command id `903`) — also known as 'evil'
  4. Joker (command id = `904`) — also known ad 'mad' or 'freaky'
  5. Gossip Queen (command id `905`) — a chatty one

There is no known way to instantly change Furby's personality via some special command. Sending a command
with the personality id back to Furby seems to produce no effect.

### Communication Mode

When Furby chats or performs any action, it will ignore any commands sent to him.
So one needs to ensure Furby is listenting before sending any command. Luckily, there's command `820`
which will put him into such listening mode for one minute (during this period, Furby just stay awake
and listen for other commands). This comamnd is used in the official applications and is sent every 40
seconds or so to keep Furby listen and stop doing silly things.

Unfortunately, even if one sends this command periodically, Furby will go into deep sleep mode after
10 minutes of inactivity. The only way to prevent it from sleep is turning or flippng Furby periodically
so that its orientation sensor detects the movement.

Tools
=====

Tools are located in `bin` directory.

### Send Commands to Furby

**CAUTION: setting the volume too high while playing back Furby commands may damage your ears!**

Put your Furby near the speaker connected to your computer (or connect an earbud to a headphone jack
and put it in front of Furby). Turn the volume all the way down. Wake up Furby and wait till it listens quietly.
Run the command below:

    perl furby-send.pl 350

Turn the volume up a little and run the command again to see if Furby recognizes it
(he should chew and then say something like "mmm, yum!"). If it doesn't, turn the volume up a bit and repeat
the procedure until it does.

#### Troubleshooting

If you can hear a discomforting high-pitch noise when the command plays but Furby doesn't repsond,
then something is wrong. Try putting Furby closer to the speaker or the earbud and make sure Furby doesn't
do anything on his own while you play back the command. Normally, Furby should pick up the command even if
you are not hearing it yet.

#### Interactive Mode

You can also run the tool in interactive mode:

    perl furby-send.pl 350 --interactive

After playing back the first command (`350`), the script will wait for your input. You can just press Enter to
play the next command in the range, or input a command number to play, or input anything else that doesn't
evaluate to a number (for example, `r`) to repeat the last command. This mode will allow you to explore the
Furby reactions to different commands.

The generated WAV file is saved as `out.wav` in the current directory. Under Windows, the playback is performed
using the provided command-line utility (`bin/win32/dsplay.exe`). Under Unix / Mac, an attempt to use
already existing console players is used (but not tested).


### Listen and Decode Furby Commands

The provided `furby-decode.pl` decodes the RAW PCM data from STDIN and displays any commands it decodes.
The only supported format is 44.1KHz mono 16bit signed PCM format.

You can pre-record a WAV file using your microphone and then decode it using this tool like this:

    perl furby-decode.pl < record.wav

or pipe in PCM data from a streaming application or virtual device. Under Windows, a binary tool is included 
(`bin/win32/rec_stdout.exe`) which records data from a default input source and constantly streams it to STDOUT.
You can use it like this:

    win32\rec_stdout.exe | perl furby-decode.pl

or just run

    furby-listen.bat

Before you run this command, make sure you have a microphone plugged in, that it is selected in Sound settings
as a default capturing device and put your microphone close to Furby.

The sound capture hasn't been tested on platforms other than Windows.

#### Troubleshooting

Some microphones (especially the ones integrated into web cameras) use a low-pass filter that would essentially
wipe out all frequencies that are used to transmit commands. If your decoding doesn't work, try recording
the audio sample into the 44.1KHz mono 16bit signed PCM WAV file (touch Furby's head or tum to make sure it responds
to your interaction and thus emits an event command), then open the file in a sound editor like Audacity,
make sure the audio format is correct, switch to a spectrum view and see if there are any frequencies recorded
around the 17.5KHz range (you will clearly see if there are command packets there).


### Feedback

Feedback and any further research results are always welcome.
