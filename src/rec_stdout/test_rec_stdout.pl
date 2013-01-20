use strict;

my $buf;

my $n = 0;
for (0..10) {
    my $numread = sysread(STDIN, $buf, 10000);
    $n += $numread;
    print "$numread bytes read\n";
}

print "$n total bytes read\n";
