rec_stdout.exe is a simple console utility that will record data from default input source in 44.1KHz mono 16bit signed PCM format
and write it to STDOUT.

There are two main scenarios of its use:

1) rec_stdout.exe >output.raw

This will just PCM data to an ever growing file untill you press Ctrl+C (or until the file reaches its max size).

2) rec_stdout.exe | perl test_rec_stdout.pl

This will pipe the data to any other consle application of your choice, including scripting languages.
This will allow you to examine data continuously.