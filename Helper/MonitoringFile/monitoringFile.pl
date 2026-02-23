#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use POSIX qw(strftime);
use File::Path qw(make_path);

# Usage:
#   ./monitoringFile.pl /folder/log [/path/to/config]
# Default config: ./monitoring_paths.conf (same dir as script)

my $log_dir = $ARGV[0] // "";
my $config  = $ARGV[1];

if (!$log_dir) {
    die "Usage: $0 /folder/log [/path/to/config]\n";
}

make_path($log_dir) if !-d $log_dir;

my $script_dir = do {
    my $p = $0;
    $p =~ s{/[^/]+$}{};
    $p ||= ".";
    $p;
};

my $default_config = "$script_dir/monitoring_paths.conf";
$config ||= $default_config;

die "ERROR: Config file not found: $config\n" if !-f $config;

my $date_yyyymmdd = strftime("%Y%m%d", localtime);
my $now_str       = strftime("%Y-%m-%d %H:%M:%S", localtime);
my $out_file      = "$log_dir/filecount_${date_yyyymmdd}.txt";

# Header if new file
if (!-f $out_file) {
    open my $fh, ">>", $out_file or die "Cannot write $out_file: $!\n";
    print $fh "date_time,folder_name,filecount,foldercount\n";
    close $fh;
}

open my $cfg, "<", $config or die "Cannot read $config: $!\n";

open my $out, ">>", $out_file or die "Cannot write $out_file: $!\n";

while (my $line = <$cfg>) {
    chomp($line);
    $line =~ s/^\s+|\s+$//g;
    next if $line eq "" || $line =~ /^#/;

    my $folder = $line;

    if (!-d $folder) {
        print $out "$now_str,$folder,0,0\n";
        next;
    }

    my $filecount = 0;
    my $foldercount = 0;

    find(
        {
            wanted => sub {
                return if $File::Find::name eq $folder; # exclude root folder from foldercount
                if (-f $_) { $filecount++; }
                elsif (-d $_) { $foldercount++; }
            },
            no_chdir => 1
        },
        $folder
    );

    print $out "$now_str,$folder,$filecount,$foldercount\n";
}

close $out;
close $cfg;

print "Wrote: $out_file\n";