#!/usr/bin/perl -w
# Original Author: Ventz Petkov
# Last updated by Original Author on
# Date: 06-15-2011
# Last: 12-20-2012
# Version: 2.0
#
# Rewritten by: Droidzone
# Date 31-03-2013 www.droidzone.in
# Version 3.0.0.2
# Usage:
# ./update-wp-plugins.pl
#   or
# ./update-wp-plugins.pl registered-name-of-plugin
# (and this works to update an exiting plugin or download+install a new one)

$progversion="3.0.0.2";
$debugmode=0;
use Term::ANSIColor;
print color 'bold blue';
print "Wordpress Plugin Updater script v$progversion.\n";
print color 'reset';
&argparser(@$ARGV);


if(!defined($ARGV[0])) {
    dprint ("No arguments supplied for folder path");
	$path="/var/www/virtual/joel.co.in/vettathu.com/htdocs/wp-content/plugins";
	dprint ("Path was specified on the command line\n");
}
else {
	#my @values = split(',', $ARGV[0]);	
	#foreach my $val (@values) 
	$path=$ARGV[0];
	print "Working on directory: $path\n";	    
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
print "Plugin directory:$path\n";
chdir($path);

use WWW::Mechanize;
#use File::Find;
my $mech = WWW::Mechanize->new();
$mech->agent_alias( 'Mac Safari' );
my $wp_base_url = "http://wordpress.org/extend/plugins";

################################################
# Add New plugins Here:
# Format:
#   'registered-name-of-plugin',
#
my (@plugins, @plugins_notfound, @filepath, @pluginversion);

use File::Find::Rule;
use File::Spec;

my @folders = File::Find::Rule->directory->maxdepth(1)
    ->in( $path )
    ;
	
foreach my $i (@folders){
    ( $volume, $directories, $file ) = File::Spec->splitpath( $i );
	undef $volume, $directories;
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
		open("txt", $filename);
		while($line = <txt>) 
		{			
			if ( $line =~ /^\s*\**\s*\bVersion:(.*)/i )
			{
				$pluginversion[$i]=$1;
				dprint ("Version found in file ".$filename);						
				$varfound=1;										
				dprint ($pluginversion[$i]."\n");
				dprint ("Array Num ".$i." Stored plugin name:".$plugins[$i]." Version found and stored ".$pluginversion[$i]);
			}
		}
		close("txt");			
    }
    else
    {
		$searchpath=$path."/".$plugins[$i];
		@files = <$searchpath/*.php>;
		dprint ("Search path is ".$searchpath."\n");
OUT: 	foreach $file (@files) 
		{
			dprint ("Checking alternate php file: ".$file."\n");
			open("txt", $file);
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
			close("txt");	
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
print color 'red';
#print colored("Summary of scanning plugin directory", 'red'), "\n";
print "Summary of scanning plugin directory\n";
print "------------------------------------\n";
printf("%-4s %-45s %3s\n", "No", "Name", "Version");
print color 'reset';
#print "No:\tName\tVersion\n";
for (my $i = 0; $i < @plugins ; $i++ ) 
{
	$v = $pluginversion[$i];
	$v =~ s/[^a-zA-Z0-9\.]*//g;	
	printf("%-4s %-45s %3s\n", $i, $plugins[$i], $v );
	#print "$i\t$plugins[$i]\t$pluginversion[$i]\n";
}
print "\n";


################################################
$pluginsdone=0;

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

print "Plugin updation completed successfully.\n";

if ( $pluginsdone > 1 )
{
	print "$pluginsdone plugin(s) were updated.\n";
}
elsif ( $pluginsdone > 1 )
{
	print "1 plugin was updated.\n";
}
else
{
	print "Plugins were already up-to-date. Nothing done.\n";
}

sub update_plugin {
	
    my $name = $_[0];
	my $index = $_[1];
    my $url = "$wp_base_url/$name";
    $mech->get( $url );
    my $page = $mech->content;
	$url="";
    my ($version,$description,$file) = "";
    if($page =~ /.*<p class="button"><a itemprop='downloadUrl' href='(.*)'>Download Version (.*)<\/a><\/p>.*/) 
	{
		$url = $1;
		$version = $2;
		if($page =~ /.*<p itemprop="description" class="shortdesc">\n(\s+)?(.*  
	)(\s+)(\t+)?<\/p>.*/) 
		{
			$description = $2;
		}
		if($url =~ /http:\/\/downloads\.wordpress\.org\/plugin\/(.*)/) 
		{
			$file = $1;
		}
    }	
	$oldversion = $pluginversion[$index];
	$version =~ s/[^a-zA-Z0-9\.]*//g;	
	$oldversion =~ s/[^a-zA-Z0-9\.]*//g;
	
    print "Processing plugin: ";
	print colored($name, 'green');	
	print " | Local version ";
	print colored($oldversion, 'green');		
	print " | Remote version ";
	
	if ( $version eq $oldversion )
	{
		print colored($version, 'green');	
		print " | ";
		print colored("Already update\n", 'green');
	}
	else
	{
		print colored($version, 'red');	
		print " | ";
		$pluginsdone++;
		print colored("Updating now..\n\n", 'blue');
		#print "Updating plugin $name now";
		`/bin/rm -f $file`; print "Downloading: \t$url\n";
		`/usr/bin/wget -q $url`; print "Unzipping: \t$file\n";
		`/usr/bin/unzip -o $file`; 
		print colored("Installed: \t$name\n\n", 'green');		
		`/bin/rm -f $file`;
	}
}
 
sub read_extract
{
	my $pl_version="";
    open("txt", my $file=$_[0]);
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
    close("txt");
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
	$debugtext=$_[0];
	if ($debugmode) 
	{
		print $debugtext."\n";
	}
}	

sub print_help 
{
	print "\nCommand syntax:";
	print "\n";
	print "wpupdater [path/to/plugin dir] [plugin name]\n";
	print "\nBoth arguments are optional\n\n";
}

sub argparser
{
	foreach (@ARGV) {
		$argu=$_;
		#print "Argument:$argu";
		if ($argu eq "--help")
		{
			&print_help;
			exit;
		}
	}

}
