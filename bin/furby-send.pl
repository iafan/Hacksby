#!/usr/bin/perl

# Copyright (C) 2013 Igor Afanasyev, https://github.com/iafan/Hacksby

use strict;

BEGIN {
    use File::Spec::Functions qw(rel2abs catfile);
    use File::Basename;
    unshift(@INC, catfile(dirname(rel2abs($0)), '../lib'));
}

use Furby::Audio;

if ($^O eq 'MSWin32') {
    require Win32::Sound;
}

$| = 1; # disable STDOUT buffering

$SIG{INT} = sub {
    print "SIGINT caught, stopping...\n";
    exit(2);
};

my $filename = 'out.wav';

my $min_number = 0;
my $max_number = 1023;

my $number = $ARGV[0];
my $interactive = $ARGV[1] eq '--interactive';

if ($number eq '' or !$interactive && $ARGV[1] ne '') {
    print "Usage: perl $0 <command> [--interactive]\n";
    exit(1);
}

if ($number < $min_number or $number > $max_number) {
    print "Command number must be in [$min_number..$max_number] range\n";
    exit(1);
}

if (!$interactive) {
    Furby::Audio::generate_wav($number, $filename);
    play_wav($filename);
} else {
    while ($number <= $max_number) {
        Furby::Audio::generate_wav($number, $filename);
        print "Command $number ... ";
        play_wav($filename);
        if ($number == $max_number) {
            print "Done\n";
            last;
        } else {
            print "Next: ";
            my $s = <STDIN>;
            chomp $s;
            if ($s eq '') {
                $number++;
            } else {
                $number = $s if ($s + 0 eq $s && $s >= $min_number && $s <= $max_number);
            }
        }
    }
}

sub play_wav {
    my ($filename) = @_;

    my $command = 'aplay'; # assube we're on some Linux desktop flavor

    if ($^O eq 'MacOS') {
        $command = 'afplay';
    }

    if ($^O eq 'MSWin32') {
        $command = '"'.catfile(dirname(rel2abs($0)), 'win32/dsplay.exe').'"';
    }

    system("$command $filename");
}
