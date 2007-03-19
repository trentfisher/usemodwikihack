#!/usr/local/bin/perl
# simple script to feed pages from one wiki into another
# customization will be required for whichever wikis are involved
# currently written for converting OpenWiki to UseModWiki
use CGI::Util qw(unescape escape);
use LWP::UserAgent;
use URI;
use strict;

$| = 1;

# param is the page name
my $srcwiki = "http://bsr01:90/ow.asp"; # ?p=%s&a=edit";
my $dstwiki = "http://sdcccvw5:8080/cgi-bin/nexuswiki.pl";
my @srcauth = ('CORP\\tfisher', 'XXXX');

my $titles = {};
if (not @ARGV)
{
    print "Getting page list from $srcwiki...\n";
    $titles = getWikiPageList($srcwiki);
    print "  ... ", scalar(keys %$titles), "\n";
}
else
{
    grep($titles->{$_} = $_, @ARGV);
}

my $renamed = fixPageNames($titles);

foreach my $p (keys %$titles)
{
    # get page from src wiki
    my $pagetxt = getWikiPage($srcwiki, {p => $p, a=> "edit"});
    if (not $pagetxt)
    {
        warn "Error: empty page $p, skipping\n";
        next;
    }
    convertWikiFmt(\$pagetxt, $renamed);
    putWikiPage($dstwiki, {title => ($renamed->{$p} || $p),
                           text => $pagetxt,
                           oldtime => 0,
                           summary => "imported from $srcwiki by $0",
                           Save => "Save"});
}

print "That took ", (time-$^T), " seconds\n";
exit 0;

sub getWikiPageList
{
    my $url = shift;
    my $params = shift;

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => $url."?TitleIndex");
    $req->authorization_basic(@srcauth);

    # run the request
    my $res = $ua->request($req);
    print "get TitleIndex ", $res->status_line, "\n";
    my $s = $res->as_string;

    my $titles = {};
    # <a href="ow.asp?ZosTZeroCell" title...
    while ($s =~ s/href=\"ow.asp\?(\S+)\"//s)
    {
        my $p = unescape($1);
        next if $p =~ /^[ap]=/;
        next if $p =~ /^(RecentChanges|TitleIndex|UserPreferences|RandomPage|Help)/;
        $titles->{$p} = $p;
    }
    return $titles;
}

sub getWikiPage
{
    my $url = shift;
    my $params = shift;

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/x-www-form-urlencoded');
    $req->authorization_basic(@srcauth);

    {
        my $url = URI->new('http:');
        $url->query_form(%$params);
        $req->content($url->query());
    }

    # run the request
    my $res = $ua->request($req);
    print "get page ", $params->{p}, " ", $res->status_line, "\n";
    my $s = $res->as_string;
    if ($s =~ /<textarea[^>]*>(.*?)<\/textarea>/is)
    {
        return "$1";
    }
    warn "Error: unable to locate text area in $url ". join(" ", %$params);
    return undef;
}

# fix the names of any pages that need to be renamed
sub fixPageNames
{
    my $titles = shift;
    # hardwire special cases here
    my $renamed = {
        "Nexus2Fusion/Infra/Exceptions" => "Nexus2Fusion/InfraExceptions",
    };

    foreach my $t (keys %$titles)
    {
        local $_ = $t;
        # skip if we already have a special case for this one
        next if $renamed->{$t};

        # this is from FreeLinkPattern in UseMod
        if (s/[^-,.\(\)\'_0-9A-Za-z\/]/_/g)
        {
            $renamed->{$t} = $_;
            print "converting $t to $_\n";
        }
        # if there are multiple slashes, convert them all to _
        elsif (m(/.*/))
        {
            s(/)(_)g;
            $renamed->{$t} = $_;
            print "converting $t to $_\n";
        }            
        #print "$t\n" if not /^\w+$/;
    }
    return $renamed;
}
sub convertWikiFmt
{
    my $t = shift;

    # fix some entities
    $$t =~ s,&(amp|lt|gt);,($1 eq "amp" ? "&" :
                            $1 eq "lt"  ? "<" :
                            $1 eq "gt"  ? ">" : ""),egsi;

    # **bold** //italic// **//bold italic//**
    $$t =~ s,\*\*//([^\n]+?)//\*\*,\'\'\'\'\'$1\'\'\'\'\',gsi;
    $$t =~ s,\*\*([^\n]+?)\*\*,\'\'\'$1\'\'\',gsi;
    $$t =~ s,(?<!tp:)//([^\n/]+?)//,\'\'$1\'\',gsi;
    $$t =~ s,__([^\n]+?)__,<u>$1</u>,gsi;

    # lists
    # All lists start with 2 spaces at the beginning of a line.
    # Sublists are created by adding an additional 2 spaces for every
    # level that you want to add.
    $$t = "\n". $$t;  # to make the pattern work
    $$t =~ s,\n( +)(\w)\.,"\n#".("#"x(length($1)/2-.5)),gse;  # numbered lists
    $$t =~ s,\n( +)(\w)\) ,"\n#".("#"x(length($1)/2-.5)),gse;  # numbered lists
    $$t =~ s,\n( +)\*,"\n*".("*"x(length($1)/2-.5)),gse;
    $$t =~ s,\n( +):,"\n:".(":"x(length($1)/2-.5)),gse;
    $$t =~ s,\n( +);,\n;,gs;
    # this is really a preformatted section
    #$$t =~ s,(?<=\n)( +)([^\r\n]*),(warn $2)&&"\n:".(":"x(length($1)/2-1.5))."<tt>$2</tt>",gse;# && warn "Leading spaces $2\n";
    # chop the leading newlines off
    $$t =~ s,^\n+,,s;
 

    # correct lines... they need to be by themselves
    $$t =~ s,\n+----+,\n\n-------\n,gs;

    # emoticons
#    $$t =~ s,(?<!{{{)/i\\,upload:icon-info.gif,gsi;
#    $$t =~ s,(?<!{{{)\(m\),upload:emoticon-m.gif,gsi;
    my %emoticons = (
                     "/i\\", "icon-info.gif",
                     "/s\\", "icon-error.gif",
                     "/w\\", "icon-warning.gif",
                     "(m)",  "emoticon-M.gif",
                     "(M)",  "emoticon-M.gif",
                     "(l)",  "emoticon-L.gif",
                     "(L)",  "emoticon-L.gif",
                     "(u)",  "emoticon-u.gif",
                     "(b)",  "emoticon-b.gif",
                     "(B)",  "emoticon-b.gif",
                     "(c)",  "emoticon-c.gif",
                     "(C)",  "emoticon-c.gif",
                     "(d)",  "emoticon-d.gif",
                     "(D)",  "emoticon-d.gif",
                     "(e)",  "emoticon-E.gif",
                     "(E)",  "emoticon-E.gif",
                     "(Y)",  "emoticon-Y.gif",
                     "(y)",  "emoticon-Y.gif",
                     "(N)",  "emoticon-N.gif",
                     "(n)",  "emoticon-N.gif",
                     "(i)",  "emoticon-i.gif",
                     "(I)",  "emoticon-i.gif",
                     "(S)",  "emoticon-S.gif",
                     "(*)",  "emoticon-star.gif",
                     );
    $$t =~ s,(/[iws]\\)\s,"image:".$emoticons{lc($1)}." ",gsie;
#    $$t =~ s{(\([\w\@\*]\))[\s\r\n]}{($emoticons{$1} ? (warn("got $1\n"), "image:".$emoticons{$1}) : warn("Unknown emoticon $1\n"), "XXX".$1)." "}gsie;
    $$t =~ s{(\([a-zA-Z\@\*]\))[\s\r\n]}{($emoticons{$1} ? "image:".$emoticons{$1} : $1)." "}gsie;

    $$t =~ s,{{{([^\n]+?)}}},<tt><nowiki>$1</nowiki></tt>,gsi;
    $$t =~ s,{{{(.+?)}}},fixpreformat($1),gse;
#    $$t =~ s,}}},</pre>,gsi;
    $$t =~ s,(&lt;|<)code(&gt;|>)([^\n]+?)(&lt;|<)/code(&gt;|>),<tt><nowiki>$3</nowiki></tt>,gsi;
    $$t =~ s,(&lt;|<)code(&gt;|>)(.+?)(&lt;|<)/code(&gt;|>),fixpreformat($3),gsie;

    # what about: <TableOfContents>
    $$t =~ s,(<|&lt;)TableOfContents[\s/]*(>|&gt;),<toc>,gsi;

    # <Include(AppsBuildEnvironment)>
    $$t =~ s,(<|&lt;)Include\((.+?)\)(>|&gt;),{{include $2}},gsi;
    
    # fix links for pages that were renamed
    my $rp = join("|", map(quotemeta($_), keys %$renamed));
    $$t =~ s,\b($rp)\b,$renamed->{$1},gsx;

    # escape camelcase links
    # ~TestProcessService
    $$t =~ s,~([A-Z][a-zA-Z]+[A-Z]\w+),<nowiki>$1</nowiki>,gs;

    # Nevermind... we will correct these manually after import...
    # too many weird cases
    # fix links hardwired to old wiki
    # <a href='http://bsr01:90/ow.asp?blah'>WebSphere</a>
    #$$t =~ s,<a href=[\"\']$srcwiki\?(?:p=)?(.+?)[\"\']>(.+?)</a>,[$1 $2],gs;
    # [http://bsr01:90/ow.asp?blah WebSphere]
    #$$t =~ s,\[$srcwiki\?(?:p=)?([^\s\]]+)(.*?)\],[$1 $2],gs;
    #$$t =~ s,$srcwiki(?:\?p=)?(.+?),[[$1]],gs;
    #$$t =~ s,$srcwiki,$dstwiki,gs;

    #print $$t;
}

# helper for preformat translation above
sub fixpreformat
{
    my $txt = shift;
    my $out = "";
    foreach my $l (split(/\r?\n/, $txt))
    {
        $l =~ s/^[ \t]*(:+)/" ".("  "x length($1))/e;
        $l =~ s/^[ \t]*$/ &nbsp;/;
        # escape camel case links
        $l =~ s,(/?[A-Z][a-zA-Z]+[A-Z]\w+),<nowiki>$1</nowiki>,g;
        # make sure of leading space, if none yet
        $l = " ".$l if $l =~ /^[^\s]/;
        $out .= $l."\n";
    }
    # remove leading and trailing blank lines
    1 while ($out =~ s/^ &nbsp;\r?\n//s);
    1 while ($out =~ s/\n &nbsp;\r?\n$/\n/s);

    return $out;
}

sub putWikiPage
{
    my $url = shift;
    my $params = shift;

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/x-www-form-urlencoded');

    {
        my $url = URI->new('http:');
        $url->query_form(%$params);
        $req->content($url->query());
    }

    # run the request
    my $res = $ua->request($req);
    print "put page ", $params->{title}, " ", $res->status_line, "\n";
    my $s = $res->as_string;
#    print $s;
    if ($s =~ /Invalid Page/)
    {
        warn "Error: Invalid page ".$params->{title}."\n";
    }
}
