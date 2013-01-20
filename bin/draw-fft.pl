#!/usr/bin/perl

# Copyright (C) 2013 Igor Afanasyev, https://github.com/iafan/Hacksby

use strict;

# only raw 16bit signed PCM data is supported

use GD;
use Math::FFT;

my $filename = $ARGV[0];

if ($filename eq '') {
    print "Usage: perl $0 filename.raw\n";
    exit(1);
}

if (!-f $filename) {
    print "File '$filename' doesn't exist\n";
    exit(1);
}

my $base_freq = {
    '0' => 16386,
    '1' => 16943,
    'X' => 17500, # base frequency, used to construct raw commands (delta is approx 557 Hz) // was 17498 with 556 Hz delta
    '3' => 18057,
    '2' => 18614,
};

my $allowed_deviation = abs($base_freq->{'X'} - $base_freq->{'1'}) * 0.2;

my $buffer;
my $read_block_size = 10000;
my $sample_rate = 44100;
my $size_in_samples = 256;
my $expand_index = 5;
my $max_image_width = 10000;

my $fft_min_freq = 0;
my $fft_max_freq = $sample_rate / 2;
my $fft_spectrum_size = int($size_in_samples / 2) + 1;
my $fft_freq_delta = ($fft_max_freq - $fft_min_freq) / ($fft_spectrum_size - 1);

my $spectrum_first_idx = int($base_freq->{'0'} / $fft_freq_delta) - $expand_index;
$spectrum_first_idx = 0 if $spectrum_first_idx < 0;

my $spectrum_last_idx = int(($base_freq->{'2'} + $fft_freq_delta / 2) / $fft_freq_delta) + $expand_index;
$spectrum_last_idx = $fft_spectrum_size - 1 if $spectrum_first_idx > $fft_spectrum_size - 1;

my $image_height = $spectrum_last_idx - $spectrum_first_idx + 1;

my @spectrum_frequencies;
for my $y ($spectrum_first_idx..$spectrum_last_idx) {
    $spectrum_frequencies[$y] = $fft_min_freq + $y * $fft_freq_delta;
}

my $image_width = int((-s $filename) / ($size_in_samples * 2));
if ($image_width > $max_image_width) {
    $image_width = $max_image_width;
    print "Image would be too big; it will be trimmed to first $max_image_width spectrum pxiels\n";
}

my $image = new GD::Image($image_width, $image_height, 1);

my $base_freq_colors = {
    '0' => $image->colorResolve(255,   0, 255),
    '1' => $image->colorResolve(  0, 204, 255),
    'X' => $image->colorResolve(255,   0,   0),
    '3' => $image->colorResolve(  0, 255,   0),
    '2' => $image->colorResolve(255, 255,   0),
};

open(IN, $filename);
#sysread(IN, $_, 56); # skip RIFF header
read_from_handle(*IN);
close(IN);

my $x = 0;

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

                $x++;
                last if $x > $max_image_width - 1;
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

    my $known_frequency_key;
    foreach my $key (keys %$base_freq) {
        if (abs($base_freq->{$key} - $freq) < $allowed_deviation) {
            $known_frequency_key = $key;
            last;
        }
    }

    for my $y ($spectrum_first_idx..$spectrum_last_idx) {
        my $color = $max > 0 ? int($spectrum->[$y] / $max * 255) : 0;
        $color = 255 if $color > 255;
        #$color = int($color * 0.5);
        if ($contrast < ($fft_spectrum_size / 3.5)) {
           $color = $color * 0.2;
           $color = $image->colorResolve($color, $color, $color)
        } else {
            $color = ($y == $max_y) ? $image->colorResolve(255, 255, 255) : $image->colorResolve($color, $color, $color);
            if (defined $known_frequency_key && ($y == $max_y)) {
                $color = $base_freq_colors->{$known_frequency_key};
            }
        }
        $image->setPixel($x, $image_height - 1 - ($y - $spectrum_first_idx), $color);
    }
}

print "Saving out.png...\n";
open(OUT, ">out.png");
binmode OUT;
print OUT $image->png;
close OUT;
