#!/usr/bin/perl

###############################################################################
#
#  wiki-update-diff.cgi
#
#  Created by Michael Buschbeck <michael.buschbeck@bitshapers.com>
#  Free for use and modification.
#
#  Updates the diff caches of a UseMod Wiki installation. Install into the
#  same directory as wiki.cgi, set the necessary file permissions and execute.
#  This script will not run without an active global edit lock on the Wiki.
#
#  Use at your own risk. Making a full backup of your data before executing
#  this script is highly advised.
#
#  $Revision: 1.3 $
#  $Date: 2002/08/03 11:06:05 $
#


BEGIN {
  $wiki = shift || 'wiki.cgi';

  if (not -e $wiki) {
    print "Content-Type: text/plain\n\n";
    print "Unable to find Wiki script $wiki. Exiting.\n";
    exit;
    }

  map require $wiki, 'nocgi';
  }


package UseModWiki;

do $ConfigFile
  if $UseConfig and defined $ConfigFile and -f $ConfigFile;

setDirNames();
InitLinkPatterns();

$| = 1;
print "Content-Type: text/plain\n\n";

if (not -f "$DataDir/noedit") {
  print "You must enable a global edit lock before attempting to perform a diff cache update. Exiting.\n";
  exit;
  }

print "Updating diff caches for all pages. Please wait.\n\n";

@pageIds = AllPagesList();

$countPagesTotal = @pageIds;
$countPagesCurrent = 0;
$countPagesCleared = 0;
$countPagesSkipped = 0;

$lengthCount = length $countPagesTotal;

foreach $pageId (@pageIds) {
  OpenPage($pageId);
  OpenDefaultText();
  
  $flagEdit      = $Text{minor};
  $flagAuthorNew = $Text{newauthor};
  
  $textRevisionCurrent = $Text{text};

  $revisionCurrent = $Page{revision};
  $revisionMinor   = $Page{revision} - 1;

  $pageTitle = $pageId;
  $pageTitle =~ tr/_/ /;

  printf "%3d%% %${lengthCount}d/%d %s... ",
    $countPagesCurrent / ($countPagesTotal > 1 ? $countPagesTotal - 1 : 1) * 100.0,
    $countPagesCurrent + 1, $countPagesTotal,
    $pageTitle;

  if ($revisionCurrent == 1) {
    print "First revision, no diffs needed.\n";
    $countPagesSkipped++;
    }
  
  else {
    OpenKeptRevisions('text_default');

    if (not defined $KeptRevisions{$revisionMinor}) {
      print "Previous revision ($revisionMinor) not found. ";
      $countPagesCleared++;
      
      SetPageCache('diff_default_minor',  '');
      SetPageCache('diff_default_major',  '');
      SetPageCache('diff_default_author', '');
      }
    
    else {
      OpenKeptRevision($revisionMinor);
      $textRevisionMinor = $Text{text};
     
      $UseDiffLog = 0;
      UpdateDiffs($pageId, undef, $textRevisionMinor, $textRevisionCurrent, $flagEdit, $flagAuthorNew);
      }

    $pageFile = GetPageFile($OpenPageName);
    WriteStringToFile($pageFile, join $FS1, %Page);

    print "Done.\n";
    }

  $countPagesCurrent++;
  }

print "\n";
print "All diff caches updated ($countPagesTotal pages total, $countPagesSkipped pages skipped, $countPagesCleared diffs unavailable).\n";
