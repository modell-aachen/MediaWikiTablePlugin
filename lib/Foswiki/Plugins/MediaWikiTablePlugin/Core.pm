# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2006-2014 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::MediaWikiTablePlugin::Core;

use strict;
use warnings;

use Foswiki::Func ();

use constant TRACE => 0; # toggle me

###############################################################################
sub writeDebug {
  #&Foswiki::Func::writeDebug('- MediaWikiTablePlugin::Core - '.$_[0]) if TRACE;
  print STDERR '- MediaWikiTablePlugin::Core - '.$_[0]."\n" if TRACE;
}

###############################################################################
sub handleMWTable {

  my $i = 0;
  while ($_[0] =~ s/(^|[\n\r])(\s*{\|(?!.*?(^|[\n\r])\s*{\|).*?[\n\r]\s*\|})/$1.&_handleTable($2)/ges) {
    $i++;
    #writeDebug("### nesting $i");
  };
}

###############################################################################
sub _handleTable {
  my $text = shift;

  #writeDebug("### called _handleTable");
  return '' unless $text;
  #writeDebug("in:\n'$text'");

  my @result;
  my $foundRow = 0;
  my $foundCell = 0;
  my $foundHead = 0;
  my $foundTable = 0;
  my $foundCaption = 0;
  my $rowTag = 'oddrow';

  foreach my $line (split(/[\n\r]/,$text)) {
  
    # tables
    if ($line =~ s/^\s*{\|(.*)$/<table $1>/) { # begin table
      die "second table found" if $foundTable;
      unless ($line =~ s/(class=[\\"'])/$1wikitable /) {
	$line =~ s/<table /<table class='wikitable' /;
      }
      $foundTable = 1;
    }
    if ($line =~ s/^\s*\|}/<\/td><\/tr>\n<\/table>/) { # end table
      $foundTable = 0;
      $foundRow = 0;
      $foundCell = 0;
      $foundHead = 0;
    }

    # cells
    if ($line =~ s/^\s*\|([^}\+\-].*)?$/&_handleTableCells($1, 0)/e) {
      unless ($foundRow) {
	$line = "<tr class=\"$rowTag\">".$line;
	$foundRow = 1;
	$rowTag = ($rowTag eq 'oddrow') ? 'evenrow' : 'oddrow'; 
      }
      if ($foundCaption) {
	$line = "</caption>".$line;
	$foundCaption = 0;
      }
      if ($foundCell) {
	$line = "</td>".$line;
	$foundCell = 0;
      } elsif ($foundHead) {
	$line = "</th>".$line;
	$foundHead = 0;
      }
      $foundCell = 1;
    }

    # head
    if ($line =~ s/^\s*!([^}\+\-].*)$/&_handleTableCells($1, 1)/e) {
      unless ($foundRow) {
	$line = "<tr>".$line;
	$foundRow = 1;
      }
      if ($foundCaption) {
	$line = "</caption>".$line;
	$foundCaption = 0;
      }
      $line = "</th>\n$line" if $foundHead;
      $foundHead = 1;
    }

    # captions
    if ($line =~ s/^\s*\|\+(.*)?$/&_handleTableCells($1, 2)/e) {
      if ($foundCell) {
	$line = "</td>".$line;
	$foundCell = 0;
      }
      if ($foundRow) {
	$line = "</tr>".$line;
	$foundRow = 0;
      }
      if ($foundCaption) {
	$line = "</caption>".$line;
      }
      $foundCaption = 1;
    }

    # rows
    if ($line =~ s/^\s*\|-+(.*)$/<tr $1>/) { # begin row
      unless ($line =~ s/(class=[\\"'])/$1$rowTag /) {
	$line =~ s/<tr /<tr class=\"$rowTag\" /;
      } 
      if ($foundCaption) {
	$line = "</caption>".$line;
	$foundCaption = 0;
      }
      $line = "</tr>\n".$line if $foundRow;
      $foundRow = 1;
      $rowTag = ($rowTag eq 'oddrow') ? 'evenrow' : 'oddrow'; 
      if ($foundCell) {
	$line = "</td>".$line;
	$foundCell = 0;
      } elsif ($foundHead) {
	$line = "</th>".$line;
	$foundHead = 0;
      }
    }

    #writeDebug("line=$line");
    push (@result, $line);
  }
  my $result = join("\n", @result);

  #writeDebug("out:\n'$result'");
  return $result;
}

##############################################################################
sub _handleTableCells {
  my ($text, $flag) = @_;

  #writeDebug("text=$text, flag=$flag");
  my $cellTag = 'td';
  $cellTag = 'th' if $flag == 1;
  $cellTag = 'caption' if $flag == 2;
  unless ($text) {
    return "<$cellTag>";
  }
  my @cells;
  foreach my $cell (split(/!{2}|\|{2}/,$text)) {
    #writeDebug("cell=$cell");
    my $params = '';
    $cell =~ s/<!--/<<nop>!--/go; # take care of html comments
    if ($cell =~ /^(.*?)(?<!<nop>)[!\|](.*)$/) {
      $params = ' '.$1;
      $cell = $2;
    }
    $cell =~ s/<<nop>!--/<!--/go;
    push (@cells, "<$cellTag$params>$cell");
  }

  my $result =join("</$cellTag>\n", @cells);
  #writeDebug("result=$result");
  return $result;
}

1;
