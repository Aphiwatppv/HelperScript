#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

print "1) Directory: ";
chomp(my $base_dir = <STDIN>);
die "ERROR: Directory not found: $base_dir\n" if !-d $base_dir;

print "2) File name filter (optional, press Enter to skip): ";
chomp(my $name_filter = <STDIN>);
my $nf = lc($name_filter);

print "3) Content to search (word/sentence): ";
chomp(my $needle = <STDIN>);
die "ERROR: Content keyword cannot be empty.\n" if !$needle;

my @results;

sub name_match {
    my ($filename) = @_;
    return 1 if $name_filter eq "";
    return index(lc($filename), $nf) >= 0;
}

sub file_contains {
    my ($path) = @_;
    if ($path =~ /\.gz$/) {
        my $gz = IO::Uncompress::Gunzip->new($path);
        return 0 if !$gz;
        while (my $line = <$gz>) {
            if (index($line, $needle) >= 0) { $gz->close(); return 1; }
        }
        $gz->close();
        return 0;
    } else {
        open my $fh, "<", $path or return 0;
        while (my $line = <$fh>) {
            if (index($line, $needle) >= 0) { close $fh; return 1; }
        }
        close $fh;
        return 0;
    }
}

find(sub {
    return if !-f $_;
    return if !name_match($_);
    my $path = $File::Find::name;
    push @results, $path if file_contains($path);
}, $base_dir);

print "\nResult:\n-------------------\n";
print "$_\n" for @results;
print "\nSummary\n" . ($base_dir =~ s{/$}{}r) . "/ : " . scalar(@results) . " files\n";