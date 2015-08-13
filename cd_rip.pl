#!/usr/bin/perl
# cd-rip
# A Program that attempts to rip CD to OGG Vorgis and tag it
# Public Domain
# version 0.1 - 27. Jan 2008

#converts a string to more appropriate filename
sub convertToFilename {
	local($param) = @_;

	#convert illegal and not appropriate characters to a better form
	$param =~ s/[^a-z0-9\-\_ ]//gi;
	$param =~ s/ /_/g;
	$param =~ s/__/_/g;

	return $param;
}

sub convertToCommandParameter {
	local($param) = @_;

	#convert illegal and not appropriate characters to a better form
	$param =~ s/\\/\\\\/g;
	$param =~ s/"/\\"/g;

	return $param;
}

my $cdTitle;
my $cdArtist;
my $cdYear;
my $cdGenre;
my $outputDirectory = "./";
my $qualityValue = 10;
my $device = "1000,0,0";

foreach (0 .. $#ARGV) {
	printf "User parameters: $ARGV[$_]\n";
	if ($ARGV[$_] eq "--directory") {
			$outputDirectory = $ARGV[$_+1];
	} elsif ($ARGV[$_] eq "--quality") {
			$qualityValue = $ARGV[$_+1];
	} elsif ($ARGV[$_] eq "--device") {
			$device = $ARGV[$_+1];
	}
}

#set wnv variables
my $server = "export CDDBP_SERVER=cddb.cddb.com";
my $port = "export CDDBP_PORT=8080";

system($server);
system($port);

#rip cd to wav
system("cd " . $outputDirectory . " && mkdir tmp && cd tmp && cdda2wav dev=" . $device . " cddb=0 -B -Owav && cd ..");

#convert to ogg and tag the audio then convert to mp3
my $cddbFile= "tmp/audio.cddb";
open(F, $cddbFile) || die("ERROR: Could not open '" . $cddbFile . "'!");
while(<F>) {
	chomp;
	@line = split("=", $_);
	my $parameter = @line[0];
	my $value = substr($_, length($parameter)+1);
	#printf $parameter . "\n\t" . substr($_, length($parameter)+1) . "\n";

	if (($cdArtist eq "") && ($parameter eq "DTITLE")) {
			@dtitle = split(" / ", $value);
			$cdArtist = @dtitle[0];
			$cdTitle = @dtitle[1];
	} elsif (($cdYear eq "") && ($parameter eq "DYEAR")) {
			$cdYear = $value;
	} elsif (($cdGenre eq "") && ($parameter eq "DGENRE")) {
			$cdGenre = $value;
	} elsif (substr($parameter, 0, 6) eq "TTITLE") {
			#create a track number in 00 format
			my $trackNumber = "0" . (substr($parameter, 6) + 1);
			$trackNumber = substr($trackNumber, length($trackNumber)-2);

			my $wavFilename = "tmp/audio_" . $trackNumber . ".wav";

			my $fileArtist = convertToFilename($cdArtist);
			my $fileTrackTitle = convertToFilename($value);

			my $oggFilename = $trackNumber . "_" . $fileArtist . "_-_" . $fileTrackTitle . ".ogg";

			my $quality = " -q " . $qualityValue;
			my $artist = " --artist \"" . convertToCommandParameter($cdArtist) . "\"";
			my $album = " --album \"" . convertToCommandParameter($cdTitle) . "\"";
			my $title = " --title \"" . convertToCommandParameter($value) . "\"";
			my $genre = " --genre \"" . convertToCommandParameter($cdGenre) . "\"";
			my $date = " --date \"" . convertToCommandParameter($cdYear) . "\"";
			my $tracknum = " --tracknum " . $trackNumber;


			my $encodeCommand = "oggenc " . $wavFilename
					. $artist . $quality . $album . $title
					. $genre . $date . $tracknum
					. " -o \"" . $oggFilename . "\"";
			system($encodeCommand);

			#my $mp3Filename = $trackNumber . "_" . $fileArtist . "_-_" . $fileTrackTitle . ".mp3";
			#my $ffmpegcommand = "ffmpeg -i " . $oggFilename . " -acodec libmp3lame -ab 192k " . $mp3Filename;
			#system($ffmpegcommand);
	}
}
close(F);
my $archivecommand = "mkdir " . convertToFilename($cdArtist) . "_" . convertToFilename($cdTitle) . "_archive && mv *.ogg " . convertToFilename($cdArtist) . "_" . convertToFilename($cdTitle) . "_archive";
system($archivecommand);
#my $mp3ivecommand = "mkdir " . convertToFilename($cdArtist) . "_" . convertToFilename($cdTitle) . " && mv *.mp3 " . convertToFilename($cdArtist) . "_" . convertToFilename($cdTitle);
#system($mp3ivecommand);

system("rm -r tmp");
