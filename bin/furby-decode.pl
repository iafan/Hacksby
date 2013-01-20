#!/usr/bin/perl

# Copyright (C) 2013 Igor Afanasyev, https://github.com/iafan/Hacksby

use strict;

# only raw 16bit signed PCM data is supported

BEGIN {
    use File::Spec::Functions qw(rel2abs catfile);
    use File::Basename;
    unshift(@INC, catfile(dirname(rel2abs($0)), '../lib'));
}

use Math::FFT;

use Furby::Audio;
use Furby::Command;
use Furby::Packet;

$| = 1; # prevent STDOUT buffering

$SIG{INT} = sub {
    print "SIGINT caught, stopping...\n";
    exit(2);
};

my $central_freq = Furby::Audio::base_freq('X');
my $next_to_central_freq = Furby::Audio::base_freq('1');
my $lowest_freq = Furby::Audio::base_freq('0');
my $highest_freq = Furby::Audio::base_freq('2');

my $allowed_deviation = abs($central_freq - $next_to_central_freq) * 0.2;

my $buffer;
my $read_block_size = 10000;
my $sample_rate = 44100;
my $size_in_samples = 256;
my $expand_index = 5;
my $contrast_ratio = 3.5;

my $fft_min_freq = 0;
my $fft_max_freq = $sample_rate / 2;
my $fft_spectrum_size = int($size_in_samples / 2) + 1;
my $fft_freq_delta = ($fft_max_freq - $fft_min_freq) / ($fft_spectrum_size - 1);

my $spectrum_first_idx = int($lowest_freq / $fft_freq_delta) - $expand_index;
$spectrum_first_idx = 0 if $spectrum_first_idx < 0;

my $spectrum_last_idx = int(($highest_freq + $fft_freq_delta / 2) / $fft_freq_delta) + $expand_index;
$spectrum_last_idx = $fft_spectrum_size - 1 if $spectrum_first_idx > $fft_spectrum_size - 1;

my @spectrum_frequencies;
for my $y ($spectrum_first_idx..$spectrum_last_idx) {
    $spectrum_frequencies[$y] = $fft_min_freq + $y * $fft_freq_delta;
}

my $char_buffer;
my $char = undef;
my $prev_was_X = undef;
my $packet1 = -1;

my $filename = $ARGV[0];

my $use_stdin = ($filename eq '');

if ($use_stdin) {
    my $h = *STDIN;
    while (1) {
        read_from_handle($h);
    }
} else {
    if (!-f $filename) {
        print "File '$filename' doesn't exist\n";
        exit(1);
    }
    open(IN, $filename);
    read_from_handle(*IN);
    close(IN);
}

my @samples;
my $buffer_leftover;
sub read_from_handle {
    my $handle = shift;
    while ((my $n = sysread($handle, $buffer, $read_block_size)) > 0) {
        #print "Read $n bytes\n";
        $buffer = $buffer_leftover.$buffer if $buffer_leftover; # prepend leftover byte, if any
        while (length($buffer) >= 2) {
            my $sample = unpack('s<', substr($buffer, 0, 2, ''));
            push(@samples, $sample);
            if ($size_in_samples == @samples) {
                analyze_samples();
                undef @samples;
            }
        }
        $buffer_leftover = $buffer; # potentially there can be a single byte that we need to preserve for next iteration
    }
}

sub analyze_samples {
    my $fft = new Math::FFT(\@samples);
    my $spectrum = $fft->spctrm(window => 'hann');

    my $avg = 0;
    my $max = 0;
    my $max_y = -1;
    my $freq = 0;
    for my $y ($spectrum_first_idx..$spectrum_last_idx) {
        $avg += $spectrum->[$y];
        if ($spectrum->[$y] > $max) {
            $max = $spectrum->[$y];
            $max_y = $y;
            $freq = $spectrum_frequencies[$y];
        }
    }
    $avg = $avg / $fft_spectrum_size;
    my $contrast = ($avg == 0) ? $fft_spectrum_size : $max / $avg;

    if ($contrast >= ($fft_spectrum_size / $contrast_ratio)) {
        foreach my $key (Furby::Audio::base_freq_keys) {
            if (abs(Furby::Audio::base_freq($key) - $freq) < $allowed_deviation) {

                my $is_X = $key eq 'X';

                if (!$is_X) {
                    $char = $key if ($char eq '3' && $key eq '2');
                    $char = $key if ($char eq '1' && $key eq '0');
                    $char = $key unless defined $char;
                    #print "{$char}";
                }

                if ($prev_was_X ne $is_X) {
                    if ($is_X) {
                        if ($char ne '') {
                            $char_buffer .= $char;
                            #print "( $char )";
                            print "$char";
                        }
                        $char = undef;
                        print "-";
                        analyze_char_buffer();
                    }
                    $prev_was_X = $is_X;
                }

                last;
            }
        }
    }
} 

sub analyze_char_buffer {
    while (1) {
        last unless $char_buffer =~ m/^.*?(\d{4})(\d{4})1032/;
        my $packet = Furby::Packet::parse("$1$2");
        print "[ $1-$2-1032 = $packet ]\n";
        #print "( Packet = $packet )";
        if ($packet != -1) {
            if ($packet < 32) {
                $packet1 = $packet;
            } else {
                if ($packet1 != -1) {
                    my $command = $packet1 << 5 | ($packet - 32);
                    my $description = Furby::Command::description($command) || '?';
                    print "\n($command) $description\n\n";
                }
                $packet1 = -1;
            }
        }

        $char_buffer =~ s/^.*?(\d{4})(\d{4})1032//;

        $char = undef;
        $prev_was_X = undef;
    }
}
