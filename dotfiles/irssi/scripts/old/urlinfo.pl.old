#!/usr/bin/perl -w
# This script will catch incoming urls, grab their <title> and display. It has
# some rudimentary caching.

# WISHLIST
#  * grab and add tags, if provided with original msg
#  * equivalence rules - some urls are identical
#    (like http://42.pl/u/..._description)
#  * configurable output (theme item)

use strict;

use HTML::TokeParser;
use LWP::UserAgent;
use Digest::MD5 qw(md5_hex);
use POSIX;

use Irssi;
our ($VERSION, %IRSSI);

$VERSION = "0.2";
%IRSSI=(
    author  => 'yacoob',
    contact => 'yacoob@gmail.com',
    name    => 'Display info about urls that irssi sees.',
    license => 'GPL',
    modules => 'HTML::TokeParser LWP::UserAgent Digest::MD5 POSIX',
    url     => 'http://iceteajunkie.wordpress.com'
);

our ($browser, %urls);

# handler for incoming messages
sub look_for_urls {
  my ($server, $msg, $nick, $address, $target) = @_;
  my $urlre = qr#((?:https?://[^\s<>"]+|www\.[-a-z0-9.]+)[^\s.,;<">\):])#;

  # are there any urls to handle?
  my @all_urls = ($msg =~ /$urlre/g);

  # exit if there were no urls
  return if (scalar(@all_urls) == 0);

  # if age of
  my $max_age = Irssi::settings_get_int('urlinfo_validity_time');

  # if there was more than one url on the line, flip the switch to output
  # information in multiple lines
  my $annotate = 0;
  if (scalar(@all_urls) > 1) {
    $annotate = 1;
  }

  # handle private msgs
  unless (defined($target)) {
    $target = $nick;
  }

  # loop through URLs
  while (my $url = shift @all_urls) {
  
    # skip URL if it's something we can't parse
    next if ($url =~ /\.(iso|png|jpe?g|bin|sh|c|gif|tiff|mp3|wav|ogg|mpu|pls|wmv|avi|mov|qt|mpe?g)$/i);

    # check whether we've seen this URL already?
    my $hashed_url = md5_hex($url);
    if (defined($urls{$hashed_url}) && ((time() - $urls{$hashed_url}{lastseen}) <= $max_age)) {
      my $info = ">*< " . $urls{$hashed_url}{description};
      if ($annotate) {
        $info .= " - <" . $urls{$hashed_url}{url} . ">";
      }
      # added via timeout ONLY to pop up below original line 8)
      Irssi::timeout_add_once(10, 'display_info', [$info, $server, $target]);
      next;
    } 

    # setup pipe for parent<->child communication
    my ($rh, $wh);
    pipe ($rh, $wh);

    # FIXME: limit number of forks here, to avoid DoS
    my $child = fork();
    unless (defined $child) {
      print "Argh, fork failed. No info about $url will be given.";
    }

    # main process - call wait on kid, setup watcher for incoming data over pipe
    if ($child >0) {
      close ($wh);
      Irssi::pidwait_add($child);
      my $pipetag;
      my $args = [$rh, \$pipetag, $url, $server, $target, $annotate];
      $pipetag  = Irssi::input_add(fileno($rh), INPUT_READ, 'read_info', $args);
    } 

    # kid - get description for url, throw it down the pipe, exit
    if ($child == 0) {
      my $i = handle_url($url);
      binmode ($wh, ":utf8");
      print ($wh $i);
      close ($wh);
      POSIX::_exit(1);
    }
  }

  # purge stale entries from the cache
  # FIXME: find better place for this
  purge_stale_entries()
}

# handler for outgoing messages
sub urlinfo_own {
  if (Irssi::settings_get_bool('urlinfo_describe_own')) {
    look_for_urls(@_);
  }
}

sub purge_stale_entries() {
 my $max_age = Irssi::settings_get_int('urlinfo_validity_time');
 map {
   if ((time() - $urls{$_}{lastseen}) > $max_age) {
     delete $urls{$_};
   }
 } keys %urls;
}

# get response from forked process, display it
sub read_info {
  my $args = shift @_;
  my ($rh, $pipetag, $url, $server, $target, $annotate) = @$args;

  my $d;
  while (<$rh>) {
    $d .= $_;
  }
  close ($rh);
  Irssi::input_remove($$pipetag);

  my $output = "::: $d";
  if ($annotate) {
    $output .= " - <$url>";
  }
  
  display_info([$output, $server, $target]);

  # update list of seen urls
  my $hashed_url = md5_hex($url);
  $urls{$hashed_url}{lastseen} = time();
  $urls{$hashed_url}{url} = $url;
  $urls{$hashed_url}{description} = $d;
}

# fetch webpage, parse it, try to get <title>
sub handle_url {    
  my ($url) = @_;
  
  # add http:// if it isn't there
  $url = "http://$url" if ($url !~ /^http/);
  
  my $info;
  my $response = $browser->get($url);
  if ($response->is_success) {
    my $stream = HTML::TokeParser->new(\$response->decoded_content);
    $stream->get_tag('title');
    $info = $stream->get_trimmed_text('/title');

    $info = "No title." if (!$info);
  } else {
    $info = "Error getting $url";
  }

  return $info;
}

# display fetched info to proper target
sub display_info {
  my $args = shift @_;
  my ($output, $server, $target) = @$args;

  my $witem;
  if (defined $server) {
    $witem = $server->window_item_find($target);
  } else {
    $witem = Irssi::window_item_find($target);
  }

  if (defined $witem) {
    $witem->print($output);
  }
}


# Main section

# create browser
$browser = LWP::UserAgent->new();
$browser->max_size(1000);
$browser->agent('Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14');
$browser->env_proxy;
$browser->timeout(3);

# define settings
Irssi::settings_add_int('urlinfo', 'urlinfo_validity_time', 60 * 60 * 2);
Irssi::settings_add_bool('urlinfo', 'urlinfo_describe_own', 1);

# hook on irssi signals
Irssi::signal_add('message public', 'look_for_urls');
Irssi::signal_add('message private', 'look_for_urls');
Irssi::signal_add('message own_public', 'urlinfo_own');
Irssi::signal_add('message own_private', 'urlinfo_own');
