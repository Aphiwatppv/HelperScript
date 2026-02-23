#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use POSIX qw(strftime);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

print "1) Directory: ";
chomp(my $base_dir = <STDIN>);
die "ERROR: Directory not found: $base_dir\n" if !-d $base_dir;

print "2) File name filter (optional, press Enter to skip): ";
chomp(my $name_filter = <STDIN>);
my $nf = lc($name_filter);

print "3) Content to search (word/sentence): ";
chomp(my $needle = <STDIN>);
die "ERROR: Content to search cannot be empty.\n" if $needle !~ /\S/;

my $date_yyyymmdd = strftime("%Y%m%d", localtime);
my $out_file = "contextSearch_${date_yyyymmdd}.txt";

my @results;

sub name_match {
    my ($filename) = @_;
    return 1 if $name_filter eq "";
    return index(lc($filename), $nf) >= 0;
}

sub csv_escape {
    my ($s) = @_;
    $s =~ s/"/""/g;
    return $s;
}

sub search_in_file {
    my ($path) = @_;

    if ($path =~ /\.gz$/) {
        my $gz = IO::Uncompress::Gunzip->new($path);
        return if !$gz;
        while (my $line = <$gz>) {
            chomp($line);
            if (index($line, $needle) >= 0) {
                push @results, [$path, $line];
            }
        }
        $gz->close();
    } else {
        open my $fh, "<", $path or return;
        while (my $line = <$fh>) {
            chomp($line);
            if (index($line, $needle) >= 0) {
                push @results, [$path, $line];
            }
        }
        close $fh;
    }
}

find(
    {
        wanted => sub {
            return if !-f $_;
            return if !name_match($_);
            search_in_file($File::Find::name);
        },
        no_chdir => 1
    },
    $base_dir
);

open my $out, ">", $out_file or die "Cannot write $out_file: $!\n";
print $out "no,fullpaths,linedetail\n";

my $i = 1;
for my $r (@results) {
    my ($path, $line) = @$r;
    $path = csv_escape($path);
    $line = csv_escape($line);
    print $out $i . ",\"$path\",\"$line\"\n";
    $i++;
}

close $out;
print "Wrote: $out_file\n";