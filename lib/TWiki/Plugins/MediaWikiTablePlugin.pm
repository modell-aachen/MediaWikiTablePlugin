# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2006-2009 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. For
# more details read LICENSE in the root of this distribution.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

package TWiki::Plugins::MediaWikiTablePlugin;

use strict;
use vars qw(
  $VERSION $RELEASE $NO_PREFS_IN_TOPIC $SHORTDESCRIPTION
  $doneHeader $header $isInitialized
);

$VERSION = '$Rev$';
$RELEASE = 'v1.11';
$NO_PREFS_IN_TOPIC = 1;
$SHORTDESCRIPTION = 'Format tables the <nop>MediaWiki way';

$header = <<'HERE';
<link rel="stylesheet" href="%PUBURLPATH%/%TWIKIWEB%/MediaWikiTablePlugin/style.css" type="text/css" media="all" />
HERE

###############################################################################
sub initPlugin { 
  $isInitialized = 0;
  $doneHeader = 0;
  return 1; 
}

###############################################################################
sub commonTagsHandler {
# text, topic, web
  handleMWTable($_[2], $_[1], $_[0]) if $_[0] =~ /(^|[\n\r])\s*{\|/;

  return if $doneHeader;
  $doneHeader = 1 if  $_[0] =~ s/<head>(.*?[\r\n]+)/<head>$1$header/o;
}

###############################################################################
sub handleMWTable {
  unless ($isInitialized) {
    require TWiki::Plugins::MediaWikiTablePlugin::Core;
    $isInitialized = 1;
  }
  return TWiki::Plugins::MediaWikiTablePlugin::Core::handleMWTable(@_);
}

1;
