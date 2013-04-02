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
use v5.16;
my $progversion="3.0.0.3";
our $debugmode=0;
our ($directories,$varfound,$filename,$searchpath,$fullinstall,$line,@files,@pluginproclist,@spath);
our $path='';
our $pluginsdone;
use Term::ANSIColor;
use Getopt::Long;
Getopt::Long::Configure(qw(bundling no_getopt_compat));
&ArgParser;    
&ScriptHeader;

#dprint ("The path was set as ".$path."\n");
#print "Plugin directory:$path\n";
#

use WWW::Mechanize;
#use File::Find;
my $mech = WWW::Mechanize->new( autocheck => 0 );
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

foreach my $path (@spath)
{
	chdir($path);
	print "Processing plugins from directory: $path\n";
	my @folders = File::Find::Rule->directory->maxdepth(1)
		->in( $path )
		;
	foreach my $i (@folders){
		my ($volume, $directories, $file) = File::Spec->splitpath( $i );
		if (@pluginproclist)
		{					
			for my $pluginp (@pluginproclist)
			{			
				if ( $pluginp eq $file )
				{					
					push @plugins, $file;
					push @filepath, $i;
				}			
			}
		}
		else
		{	
			if ( $file ne "plugins" )
			{
				push @plugins, $file;
				push @filepath, $i;			
			}
		}
	}


	for (my $i = 0; $i < @plugins ; $i++ ) 
	{
		dprint ("Processing ".$plugins[$i]."...");    
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
			
	OUT: 	foreach my $file (@files) 
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
	if (!@pluginproclist)
	{
		print color 'red';	
		print "Summary of scanning plugin directory\n";
		print "------------------------------------\n";
		printf("%-4s %-45s %3s\n", "No", "Name", "Version");
		print color 'reset';
		for (my $i = 0; $i < @plugins ; $i++ ) 
		{
			my $v = $pluginversion[$i];
			$v =~ s/[^a-zA-Z0-9\.]*//g;	
			printf("%-4s %-45s %3s\n", $i, $plugins[$i], $v );
			#print "$i\t$plugins[$i]\t$pluginversion[$i]\n";
		}
		print "\n";
	}

	$pluginsdone=0;

	if(defined($ARGV[1])) {
		my $name = $ARGV[1];
		&update_plugin($name);
	}
	else {
		my $i=-1;
		for my $name (@plugins) {
			$i++;
			&update_plugin($name,$i);
		}
	}

	if ( $pluginsdone > 1 )
	{
		print "$pluginsdone plugin(s) were updated.\n";
	}
	else
	{
		print "Plugins were already up-to-date. Nothing done.\n";
	}
}
sub update_plugin {
	
    my $name = $_[0];
	my $index = $_[1];
    my $url = "$wp_base_url/$name";    
	$mech->get( $url );
	if ( $mech->success() )
	{				
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
		my $oldversion = $pluginversion[$index];
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
	else
	{
		my $error_msg="Error while processing plugin - $name Maybe it's deleted from Wordpress! Error Code is:";
		print colored($error_msg, 'red');
		my $errorcode=$mech->status()."\n";
		print colored($errorcode, 'red');
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
    my $st=substr($line,rindex($line, ":")+1);
    for ($st)
    {
     s/^\s+//;
     s/\s+$//;
    }
    $st;
}

sub dprint
{
	my $debugtext=$_[0];
	if ($debugmode) 
	{
		print $debugtext."\n";
	}
}	

sub ArgParser
{
	my $help='';
	my $prtversion='';
	my $dmode='';
	my @wpath;
	#GetOptions ('help|h:s' => \$help);
	GetOptions ('help|h' => \$help,				
				'version|v' => \$prtversion,
				'debug|d' => \$dmode,
				'plugin|p=s' => \@pluginproclist,
				'source|s=s' => \@spath,
				'wp-path|w=s' => \@wpath
				);
	if ($help)
	{
		&print_help;
		exit;
	}
	if ($prtversion)
	{
		print "Version:$progversion\n";
		exit;
	}	
	if ($dmode)
	{
		$debugmode=1;
	}
	if (@pluginproclist)
	{
		my @totalpluginlist;
		my @temparray;
		for my $pluginp (@pluginproclist)
		{
			my @totalpluginlist = split(',', $pluginp);				
			push(@temparray, @totalpluginlist);
		}	
		@pluginproclist=@temparray;
	}

	if (!@spath && !@wpath)
	{
		print "Source path for plugins was not specified. If you need to specify it, use --source=/path/to/plugindir or -s/path/to/plugindir.\n";
		print "Would you like to specify path now (y/N)?";
		chomp(my $spec =<>);
		if ($spec =~ /y/i )
		{
			print "\nEnter path to plugin folder:";
			chomp($path=<>);			
		}
		else
		{
			print "\nHard coded path will now be used.\n";
			$path="/var/www/virtual/joel.co.in/vettathu.com/htdocs/wp-content/plugins";
		}
		if ( -d $path )
		{
			dprint ("Path verified\n");
			push @spath, $path;
		}
		else
		{
			dprint ("The path does not exist\n");
			exit;
		}
	}
	else 
	{
		my @totalpathlist;
		my @temparray;
		for my $pluginp (@spath)
		{
			my @totalpathlist = split(',', $pluginp);				
			push(@temparray, @totalpathlist);
		}	
		@spath=@temparray;
	}
	if (@wpath)
	{
		my @totalw;
		my @tempw;
		for my $wp (@wpath)
		{
			my @totalw = split(',', $wp);				
			push(@tempw, @totalw);
		}	
		for my $wp (@tempw)
		{
			push (@spath,$wp."/wp-content/plugins");
		}
	}
}

sub ScriptHeader
{
	print "\n";
	print color 'bold blue';
	print "Wordpress Plugin Updater script v$progversion.\n";
	print color 'reset';
}

sub print_help 
{
&ScriptHeader;
print '
Wordpress plugin updater script is a perl script to check specified locations on your web server or Wordpress plugin updates. It will scan the folder, and
compare plugin versions to those on Wordpress.org central repository and update if updates are found. It can batch process all plugins. Alternately, you can
 specify command line options for the plugin names, and update just required plugins.

Usage:
--help or -h: Display this help message
--source=/path/to/plugindirectory or -s/path/to/plugindirectory
	Multiple folders can be specified at a time.
	Eg: ./updater.pl --source=/var/www/virtual/joel.co.in/vettathu.com/htdocs/wp-content/plugins,/var/www/virtual/joel.co.in/drjoel.in/htdocs/wp-content/plugins
--version or -v: Display script version information
--plugin=PluginName or -pPluginName: Specify one or more plugins to process instead of all plugins under source directory. To specify more than one plugin,
you can either repeat this option, like:
	Eg: ./updater.pl --plugin=nextgen-gallery --plugin=genesis-beta-tester
	  Or,
you can alternately specify a comma seperated list of plugins, like:
	Eg: ./updater.pl --plugin=nextgen-gallery,genesis-beta-tester
--wp-path= or -w: Specify wordpress root directory instead of plugin directory
	Eg: ./updater.pl --wp-path=/var/www/virtual/joel.co.in/droidzone.in/htdocs,/var/www/virtual/joel.co.in/vettathu.com/htdocs
'."\n";

}

