#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use Cwd 'abs_path';

sub contains {
    my ($haystack, $needle, $case_insensitive) = @_;
    if ($case_insensitive) {
        return lc($haystack) =~ /\Q@{[lc($needle)]}\E/;
    }
    return $haystack =~ /\Q$needle\E/;
}

sub is_text_file {
    my ($path) = @_;
    return 0 if !-f $path;
    open my $fh, "<", $path or return 0;
    binmode($fh);
    read($fh, my $buf, 4096);
    close $fh;
    return ($buf !~ /\x00/); # simple binary check
}

print "Enter base directory (e.g. /srv/folderA): ";
chomp(my $base_dir = <STDIN>);

die "ERROR: Directory not found: $base_dir\n" if !-d $base_dir;

print "\nSelect function:\n";
print "1) Search file NAME contains keyword\n";
print "2) Search file CONTENT contains keyword\n";
print "3) Search FOLDER NAME contains keyword\n";
print "Enter 1, 2 or 3: ";
chomp(my $mode = <STDIN>);

print "\nCase sensitivity:\n";
print "1) Case-INSENSITIVE\n";
print "2) Case-SENSITIVE\n";
print "Enter 1 or 2: ";
chomp(my $case_mode = <STDIN>);
my $case_insensitive = ($case_mode eq "1") ? 1 : 0;

print "\nSearch keyword: ";
chomp(my $keyword = <STDIN>);

print "\nResult:\n-------------------\n";

my @results;

if ($mode eq "1") {
    find(sub {
        return if !-f $_;
        if (contains($_, $keyword, $case_insensitive)) {
            push @results, $File::Find::name;
        }
    }, $base_dir);

    print "$_\n" for @results;
    print "\nSummary\n" . ($base_dir =~ s{/$}{}r) . "/ : " . scalar(@results) . " files\n";
    exit 0;
}

if ($mode eq "2") {
    find(sub {
        return if !-f $_;
        my $path = $File::Find::name;

        return if !is_text_file($path);

        open my $fh, "<:encoding(UTF-8)", $path or return;
        my $found = 0;

        if ($case_insensitive) {
            my $k = lc($keyword);
            while (my $line = <$fh>) {
                if (index(lc($line), $k) >= 0) { $found = 1; last; }
            }
        } else {
            while (my $line = <$fh>) {
                if (index($line, $keyword) >= 0) { $found = 1; last; }
            }
        }

        close $fh;

        if ($found) {
            push @results, $path;
        }
    }, $base_dir);

    print "$_\n" for @results;
    print "\nSummary\n" . ($base_dir =~ s{/$}{}r) . "/ : " . scalar(@results) . " files\n";
    exit 0;
}

if ($mode eq "3") {
    find(sub {
        return if !-d $_;
        return if $File::Find::name eq $base_dir; # skip base dir itself

        # Compare folder "basename"
        my $folder_name = $_;
        if (contains($folder_name, $keyword, $case_insensitive)) {
            push @results, $File::Find::name;
        }
    }, $base_dir);

    print "$_\n" for @results;
    print "\nSummary\n" . ($base_dir =~ s{/$}{}r) . "/ : " . scalar(@results) . " folders\n";
    exit 0;
}

die "ERROR: Invalid selection. Please enter 1, 2, or 3.\n";