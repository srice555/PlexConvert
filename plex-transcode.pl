#!/usr/bin/perl

use strict;
use warnings;

use File::Copy;

my $plexProcHomeDir = "/plex/PlexConvert";
my $plexProcArch    = $plexProcHomeDir . "/arch";
my $plexProcBin     = $plexProcHomeDir . "/bin";
my $plexProcErr     = $plexProcHomeDir . "/err";
my $plexProcIn      = $plexProcHomeDir . "/in";
my $plexProcLog     = $plexProcHomeDir . "/log";
my $plexProcOut     = $plexProcHomeDir . "/out";
my $plexProcProc    = $plexProcHomeDir . "/proc";
my $plexConvertCmd  = $plexProcBin     . "/transcode-video.sh";

my $bar = "---------------------------------";
my $execute_cmd = 1;

# Overview
# --------------------
# 1) Execute Handbrake
# 2) If ERROR
#	move ISO to $plexProcErr
#	move LOG to ProcLog
#	delete MKV 
# 3) Else 
#	move ISO to ProcArch
#       move Log to ProcLog
#       move MKV to ProcOut

chdir $plexProcProc;

my $file_iso=$ARGV[0];
if ( ! -e $file_iso ) {
	print "Error: Unable to find file '$file_iso'!\n";
	exit 1;	
}


# MKV and log files are managed by the script
my $file_mkv=$file_iso . ".mkv";
my $file_log=$file_mkv . ".log";


# Execute handbrake     
my $cmd = "$plexConvertCmd --mkv --720p '$file_iso' 2>&1";
print "$cmd\n";

my $rc = "";
my $result = "";

if ( $execute_cmd == 1 ) {
	$result = `$cmd`;
	$rc = $?;
}       

if ( $rc eq "" ) {
	print "No return code, exit!\n";
}

if ( $rc gt 0 ) {

	open  (LogFile, ">$file_log");
	print LogFile $result;
	close (LogFile);

	print "$plexConvertCmd failed!\n";
	move($file_iso,$plexProcErr)  if -e $file_iso;
	unlink($file_mkv)             if -e $file_mkv;
	move($file_log,$plexProcErr)  if -e $file_log;
}

if ( $rc eq 0 ) {
	print "$plexConvertCmd completed!\n";
	move($file_iso,$plexProcArch) if -e $file_iso;
	move($file_mkv,$plexProcOut)  if -e $file_mkv;
	move($file_log,$plexProcLog)  if -e $file_log;
}


