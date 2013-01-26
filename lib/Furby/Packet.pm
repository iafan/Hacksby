# Copyright (C) 2013 Igor Afanasyev, https://github.com/iafan/Hacksby

package Furby::Packet;

use strict;

my @checksums = (
    # First packet (higher 5 bits of the command number)
    '0000', #  0
    '0110', #  1
    '0210', #  2
    '0300', #  3
    '1023', #  4
    '1133', #  5
    '1233', #  6
    '1323', #  7
    '0120', #  8
    '0201', #  9
    '0330', # 10
    '1021', # 11
    '1103', # 12
    '1222', # 13
    '1313', # 14
    '2021', # 15
    '0220', # 16
    '0330', # 17
    '1000', # 18
    '1110', # 19
    '1203', # 20
    '1313', # 21
    '2000', # 22
    '2110', # 23
    '0300', # 24
    '1011', # 25
    '1120', # 26
    '1201', # 27
    '1323', # 28
    '2011', # 29
    '2120', # 30
    '2201', # 31

    # Second packet (lower 5 bits of the command number + 32)
    '1033', #  0 + 32
    '1123', #  1 + 32
    '1223', #  2 + 32
    '1333', #  3 + 32
    '2033', #  4 + 32
    '2123', #  5 + 32
    '2223', #  6 + 32
    '2333', #  7 + 32
    '1113', #  8 + 32
    '1232', #  9 + 32
    '1303', # 10 + 32
    '2031', # 11 + 32
    '2113', # 12 + 32
    '2232', # 13 + 32
    '2303', # 14 + 32
    '3012', # 15 + 32
    '1213', # 16 + 32
    '1303', # 17 + 32
    '2010', # 18 + 32
    '2100', # 19 + 32
    '2213', # 20 + 32
    '2303', # 21 + 32
    '3033', # 22 + 32
    '3123', # 23 + 32
    '1333', # 24 + 32
    '2001', # 25 + 32
    '2130', # 26 + 32
    '2211', # 27 + 32
    '2333', # 28 + 32
    '3022', # 29 + 32
    '3113', # 30 + 32
    '3232', # 31 + 32
);

sub make {
    my ($command) = @_;

    die "Command number must be in [0..1023] range" if ($command < 0 or $command > 1023);

    my $packet1 = $command >> 5;        # high 5 bits (paddded to 6 bits)
    my $packet2 = ($command & 31) + 32; # low 5 bits (with 6th bit set to 1)

    my $s1 = bin2quad('11'.dec2bin($packet1)).'-'.$checksums[$packet1].'-1032';
    my $s2 = bin2quad('11'.dec2bin($packet2)).'-'.$checksums[$packet2].'-1032';

    return "$s1 $s2";
}

sub parse {
    my ($sequence) = @_;
    $sequence =~ s/[^0123]//g; # leave just digits
    $sequence =~ s/1032$//; # remove identifier at the end, if any
    die "Sequence should contain 8 or 12 quaternary digits" unless $sequence =~ m/^([0123]{4})([0123]{4})$/;

    my $byte = quad2dec($1);
    return -1 unless ($byte & 192) == 192; # two higer bits must be set
    #print "{$byte}";

    $byte &= 63; # use 6 leftmost bits
    my $checksum = $checksums[$byte];
    return -1 unless ($checksum == $2); # checksums must match

    #print "<$1><$2>=<$byte><$checksum>\n";

    return $byte;
}

sub quad2dec {
    my $s = shift;
    my $out = 0;
    foreach my $digit (split(//, $s)) {
        $out = ($out << 2) | $digit;
    }
    return $out;
}

sub bin2quad {
    my $s = shift;
    my $out;
    foreach my $pair (split(/(\d\d)/, $s)) {
        $out .= bin2dec($pair) if $pair ne '';
    }
    return $out;
}

sub dec2bin {
    return sprintf('%06b', shift);
}

sub bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

1;