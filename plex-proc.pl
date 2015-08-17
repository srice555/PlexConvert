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
my $plexConvertCmd  = $plexProcBin     . "/plex-transcode.pl";

my $bar = "---------------------------------";

# Overview
# --------------------
#  Read from $IN 
#  Check if logfile in $LOG exists with the same name
#  Move to $PROC if does not exist
#  Move to $ERR if does exist
#  Call $CONVERTOR
#  Move output to $OUT

sub basename {
	my $str = shift;
	my $basename = substr $str, 0, rindex( $str, q{.} ); 
	return $basename;
}


sub readIsoFromIn(){

	my $dir = $plexProcIn;
	opendir(DIR, $dir) or die $!;

	my %outputHash = ();
	my $count=0;

	#print "Scanning $dir for ISO to process\n";
	#print "$bar\n";

	while (my $file = readdir(DIR)) {
	        # We only want files
        	next unless (-f "$dir/$file");
	        
		# Use a regular expression to find files ending in .txt
        	next unless ($file =~ m/\.iso$/i);

		# Check if file is in use        	
		my $fr = `sudo fuser '$dir/$file' 2> /dev/null`;
		if ( defined($fr) && $fr ne "" ) {
			print "Skipping '$file' : file is in use\n";
			next;
		}

		my $size = -s "$dir/$file";
		my $basename = basename($file); 

		$outputHash{$file}{'size'} = $size;
		$outputHash{$file}{'name'} = $file;
		$outputHash{$file}{'ctime'} = (stat("$dir/$file"))[10];
		$outputHash{$file}{'fullpath'} = "$dir/$file";
		$outputHash{$file}{'basename'} = $basename;

		$outputHash{$file}{'type'} = "iso";

		$count++;


		print "Found " . $outputHash{$file}{'name'} . "\n";
	}
	
	return ( %outputHash );
}

sub checkLogFiles {
	my $fileListHash = shift;

	my %outputHash = ();

	#print "Checking log directory\n";
	#print "$bar\n";

	foreach my $key ( sort keys %{$fileListHash} ) {

		my $name = ${$fileListHash}{$key}{'name'};
		my $basename = ${$fileListHash}{$key}{'basename'};
		my $size = ${$fileListHash}{$key}{'size'};

		my $logFileName = $basename . ".mkv.log";

		my $logFilePath = "$plexProcLog/$logFileName";

		if ( -e $logFilePath ) {
			print "ISO $name has already been processed\n";
		} else {

			moveIsoToDir(${$fileListHash}{$key}{'fullpath'},$plexProcProc);

			$outputHash{$name}{'name'} = ${$fileListHash}{$key}{'name'};
			$outputHash{$name}{'fullpath'} = ${$fileListHash}{$key}{'fullpath'};

			print "Added ISO $name to processing queue\n";

		}
	}	
	return ( %outputHash );
}

sub callConvertor {

	# 1) Look in proc for ISO to convert
	# 2) Kick off job if handbrake is not running

	#my $procListHash = shift;
	my %outputHash = ();
	my $count = 0;


	# Return if Handbrake is already running
	my $handbrakeCnt = `ps aux | grep "[H]andBrakeCLI" | wc -l`;
	if ( $handbrakeCnt > 0 ) {
		print "Handbrake is running: $handbrakeCnt\n";		
		return;
	}

	# Find something to process
	#print "Processing Proc directory\n";
	#print "$bar\n";

	my $dir = $plexProcProc;
	opendir(DIR, $dir) or die $!;

	while (my $file = readdir(DIR)) {
	        # We only want files
        	next unless (-f "$dir/$file");
	        
		# Use a regular expression to find files ending in .txt
        	next unless ($file =~ m/\.iso$/i);

		#foreach my $key ( sort keys %{$procListHash} ) {
		my $plexProcFile = "$dir/$file" ;

		# Execute and forget.  
		# We'll get the others on the next round

		my $cmd = "nohup $plexConvertCmd '$plexProcFile' & ";

		print "Process $plexProcFile started\n";
		#print $cmd;
		system("$cmd");

		return;

	}
}

sub moveIsoToDir(){
	my $file = shift;
	my $dir = shift;
	move($file,$dir);	
}

# Main
# --------------------

#print "\n";
#my %fileListHash = readIsoFromIn();
#my %procListHash = checkLogFiles(\%fileListHash);
#scanProcDir(\%procListHash);
#callConvertor(\%procListHash);

my $runstate = 1;
my $wait = 300;

print "Starting up.\n";

while ( $runstate > 0 ) {

	my $now = `date`;

	print "$bar\n";
	print "$now";
	
	# Scan input dir ";
	my %fileListHash = readIsoFromIn();
	my %procListHash = checkLogFiles(\%fileListHash);
	callConvertor();

	$runstate = 1;

	if ( $runstate > 0 ) {
		print "Sleeping... $wait seconds\n\n";
		sleep $wait;
	}
}


