#!/usr/bin/perl
# Original Author: Ventz Petkov
# Last updated by Original Author on
# Date: 06-15-2011
# Last: 12-20-2012
# Version: 2.0
#
# Rewritten by: Droidzone
# Date 31-03-2013 www.droidzone.in
# Version 3.0.0.1
# Usage:
# ./update-wp-plugins.pl
#   or
# ./update-wp-plugins.pl registered-name-of-plugin
# (and this works to update an exiting plugin or download+install a new one)

$debugmode=0;

if(!defined($ARGV[0])) {
    dprint ("No arguments supplied for folder path");
	$path="/var/www/virtual/joel.co.in/vettathu.com/htdocs/wp-content/plugins";
}
else {
    $path=$ARGV[0];
    dprint ("Path was specified on the command line\n");
    if ( -d $path )
    {
	dprint ("Path verified\n");
    }
    else
    {
	dprint ("The path does not exist\n");
	exit;
    }
}

dprint ("The path was set as ".$path."\n");

chdir($path);

use WWW::Mechanize;
use File::Find;
my $mech = WWW::Mechanize->new();
$mech->agent_alias( 'Mac Safari' );
my $wp_base_url = "http://wordpress.org/extend/plugins";

################################################
# Add New plugins Here:
# Format:
#   'registered-name-of-plugin',
#
my @plugins, @plugins_notfound, @filepath, @pluginversion;

use File::Find::Rule;
use File::Spec;

my @folders = File::Find::Rule->directory->maxdepth(1)
    ->in( $path )
    ;
	
foreach my $i (@folders){
    ( $volume, $directories, $file ) = File::Spec->splitpath( $i );
    if ( $file ne "plugins" )
    {
        push @plugins, $file;
		push @filepath, $i;
		#print "Path: ".$i."\t Name: ".$file."\n";
    }
}


for (my $i = 0; $i < @plugins ; $i++ ) 
{
    dprint ("Processing ".$plugins[$i]."...");
    #print "Filename:".$filepath[$i]."/".$plugins[$i].".php"."\n";
    $filename=$filepath[$i]."/".$plugins[$i].".php";
	$varfound=0;
    if ( -f $filename ) 
    {
		dprint ("Meta File found at default location.\n");
		$ver=&read_extract($filename);
		dprint ("Version:".$ver."\n");
		$pluginversion[$i]=$ver;
		$varfound=1;
    }
    else
    {
		#print "File does NOT exist\n";
		$searchpath=$path."/".$plugins[$i];
		@files = <$searchpath/*.php>;
		dprint ("Search path is ".$searchpath."\n");
OUT: 	foreach $file (@files) 
		{
			dprint ("Checking alternate php file: ".$file."\n");
			open(txt, $file);
			while($line = <txt>) 
			{
				#  $line =~ /^[\s\*]*Version:(.*)/i
				# Discussion on regex: http://stackoverflow.com/questions/15728671/perl-regex-logic-error
				if ( $line =~ /^\s*\**\s*\bVersion:(.*)/i )
				{
					$pluginversion[$i]=$1;
					dprint ("Version found in file ".$file);						
					$varfound=1;										
					dprint ($pluginversion[$i]."\n");
					dprint ("Array Num ".$i." Stored plugin name:".$plugins[$i]." Version found and stored ".$pluginversion[$i]);
					last OUT;
				}
			}
			close(txt);	
		}
    }
	push @plugins_notfound, $plugins[$i];
}

if ( ! $varfound) 
{
	print "\nCould not parse version no from the follwing plugins:\n";
	for (my $i = 0; $i < @plugins_notfound ; $i++ ) 
	{
		print $i." ".$plugins_notfound[$i]."\n";
	}
}
else 
{
	dprint ("We found all version numbers");
}

print "Summary of scanning plugin directory\n";
print "------------------------------------\n";
print "No:\tName\tVersion\n";
for (my $i = 0; $i < @plugins ; $i++ ) 
{
	print "$i\t$plugins[$i]\t$pluginversion[$i]\n";
}


################################################

if(defined($ARGV[1])) {
    my $name = $ARGV[1];
    &update_plugin($name);
}
else {
	$i=-1;
    for my $name (@plugins) {
		$i++;
        &update_plugin($name,$i);
    }
}


sub update_plugin {
    my $name = $_[0];
	my $index = $_[1];
    my $url = "$wp_base_url/$name";
    $mech->get( $url );
    my $page = $mech->content;
    my ($url,$version,$description,$file) = "";
    if($page =~ /.*<p class="button"><a itemprop='downloadUrl' href='(.*)'>Download Version (.*)<\/a><\/p>.*/) {
	$url = $1;
	$version = $2;
                if($page =~ /.*<p itemprop="description" class="shortdesc">\n(\s+)?(.*  
)(\s+)(\t+)?<\/p>.*/) {
                    $description = $2;
                }
	if($url =~ /http:\/\/downloads\.wordpress\.org\/plugin\/(.*)/) {
	    $file = $1;
	}
    }
    print "\nPlugin: $name | Remote version $version | Local version $pluginversion[$index]\n";
    print "\nDescription: $description\n\n";
	
    `/bin/rm -f $file`; print "Downloading: \t$url\n";
    `/usr/bin/wget -q $url`; print "Unzipping: \t$file\n";
    `/usr/bin/unzip -o $file`; print "Installed: \t$name\n";
    `/bin/rm -f $file`;
}
 
sub read_extract
{
	my $pl_version="";
    open(txt, my $file=$_[0]);
    while($line = <txt>)
    {
		for ($line)
		{
		 s/^\s+//;
		 s/\s+$//;
		}			
        if ( $line =~ /^Version:|^version:|^\* Version:/ )
        {
            $pl_version=&extract_version($line);
        }
    }
    close(txt);
	$pl_version;
}

sub extract_version
{
    my $line=$_[0];
    $string=substr($line,rindex($line, ":")+1);
    for ($string)
    {
     s/^\s+//;
     s/\s+$//;
    }
    $string;
}

sub dprint
{
	$debugmode;
	$debugtext=$_[0];
	if ($debugmode) 
	{
		print $debugtext."\n";
	}
}	
	


