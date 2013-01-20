# Copyright (C) 2013 Igor Afanasyev, https://github.com/iafan/Hacksby

package Furby::Audio;

use strict;

use Audio::Wav;

use Furby::Packet;

my $base_freq = {
    '0' => 16386,
    '1' => 16943,
    'X' => 17500, # base frequency, used to construct raw commands (delta is approx 557Hz)
    '3' => 18057,
    '2' => 18614,
};

my $PI = (22 / 7) * 2;

my $bits_sample = 16;
my $sample_rate = 44100;
my $top_freq = $sample_rate / 2;

my $base_freq_length          = 0.016; # 16ms
my $xfade_length              = 0.004; #  4ms
my $lead_silence_gap_length   = 0.005; #  5ms
my $lead_length               = 0.005; #  5ms
my $silence_gap_length        = 0.5 - $lead_length * 2; # 0.5s in total
my $xfade_volume_samples      = 220;
my $lead_xfade_volume_samples = $sample_rate * $lead_length; # entire length

sub base_freq {
    my $char = shift;
    die "Unknown frequency name '$char'" unless exists $base_freq->{$char};
    return $base_freq->{$char};
}

sub base_freq_keys {
    return keys %$base_freq;
}

sub generate_wav {
    my ($command, $filename) = @_;

    my $wav = new Audio::Wav;

    my $wav_output = $wav->write($filename, {
        'bits_sample'   => $bits_sample,
        'sample_rate'   => $sample_rate,
        'channels'      => 1,
    });

    my $data = Furby::Packet::make($command);
    my ($str1, $str2) = split(' ', $data);

    add_silence($wav_output, $lead_silence_gap_length);
    add_packet($wav_output, $str1);
    add_silence($wav_output, $silence_gap_length);
    add_packet($wav_output, $str2);
    add_silence($wav_output, $lead_silence_gap_length);

    $wav_output->finish();
}

sub add_packet {
    my ($wav_output, $str) = @_;

    # remove irrelevant splitter symbols
    $str =~ s/[^0123]//g;

    # interleave all digits with the base frequency:
    # 0123 => X0X1X2X3X
    my @a = ('', split(//, $str), '');
    add_raw_packet($wav_output, join('X', @a));
}

sub add_raw_packet {
    my ($wav_output, $str) = @_;
    my @a = split(//, $str);
    my $max_idx = $#a;

    add_sine($wav_output, $top_freq, base_freq($a[0]), $lead_length, $lead_xfade_volume_samples, $xfade_volume_samples);

    for my $i (0..$max_idx) {
        add_sine($wav_output, base_freq($a[$i]), base_freq($a[$i]), $base_freq_length, $xfade_volume_samples, $xfade_volume_samples);
        if ($i < $max_idx) {
          add_sine($wav_output, base_freq($a[$i]), base_freq($a[$i+1]), $xfade_length, $xfade_volume_samples, $xfade_volume_samples);
        }
    }

    add_sine($wav_output, base_freq($a[$max_idx]), $top_freq, $lead_length, $lead_xfade_volume_samples, $xfade_volume_samples);
}

sub add_sine {
    my ($wav_output, $hz1, $hz2, $length, $fadein_volume_samples, $fadeout_volume_samples, $volume) = @_;
    $hz2 = ($hz1 + $hz2) / 2; # fft magic
    $volume = 1 unless defined $volume;
    $length *= $sample_rate;
    my $max_no = (2 ** $bits_sample) / 2 - 1;
    my $cur_vol = 0;
    my $phase;
    for my $pos (0 .. $length-1) {
        my $time = $pos / $sample_rate;
        my $hz = $pos / ($length - 1) * ($hz2 - $hz1) + $hz1;
        $phase = $PI * $time * $hz;
    
        $cur_vol = $volume;
        if ($fadein_volume_samples > 0) {
            if ($pos < $fadein_volume_samples) {
                $cur_vol = $pos / ($fadein_volume_samples + 1) * $cur_vol;
            }
        }
        if ($fadeout_volume_samples > 0) {
            if ($length - 1 - $pos < $fadeout_volume_samples) {
                $cur_vol = ($length - 1 - $pos) / ($fadeout_volume_samples + 1) * $cur_vol;
            }
        }

        $wav_output->write(sin($phase) * $max_no * $cur_vol);
    }
}

sub add_silence {
    my ($wav_output, $length) = @_;
    $length *= $sample_rate;
    for my $pos (0..$length) {
        $wav_output->write(0);
    }
}

1;