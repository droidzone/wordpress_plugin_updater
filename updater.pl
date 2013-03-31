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

if(!defined($ARGV[0])) {
    	print "No arguments supplied for folder path\n";
	$path="/var/www/virtual/joel.co.in/vettathu.com/htdocs/wp-content/plugins";
}
else {
    $path=$ARGV[0];
    print "Path was specified on the command line\n";
    if ( -d $path )
    {
	print "Path verified\n";
    }
    else
    {
	print "The path does not exist\n";
	exit;
    }
}

print "The path was set as ".$path."\n";

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
my @plugins;
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
    }
}

################################################

if(defined($ARGV[1])) {
    my $name = $ARGV[1];
    &update_plugin($name);
}
else {
    for my $name (@plugins) {
        &update_plugin($name);
    }
}

sub update_plugin {
    my $name = shift;
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
    print "\nPlugin: $name | Version $version\n";
    print "\nDescription: $description\n\n";
    `/bin/rm -f $file`; print "Downloading: \t$url\n";
    `/usr/bin/wget -q $url`; print "Unzipping: \t$file\n";
    `/usr/bin/unzip -o $file`; print "Installed: \t$name\n";
    `/bin/rm -f $file`;
}
