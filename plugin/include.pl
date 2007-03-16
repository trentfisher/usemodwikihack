# simple module for including wiki pages in other ones
# It can be used in these ways:
# include all the listed pages:
#     {{include PageOne "Page Two with Spaces"}}
# include the listed page:
#     {{include page="Page Two with Spaces"}}
# include the one section from PageOne, including subsections
#     {{include page=PageOne section=SectionFive}}
# same as the previous one
#     {{include page=PageOne section=SectionFive subsection=1}}
# omit subsections (headers with greater depth)
#     {{include page=PageOne section=SectionFive subsection=0}}

my $included = {};   # keep track of what has been included

sub include
{
    my %params = @_;
    my $out = "";
    if ($params{page})
    {
        my $id = $params{page};
        if ($included->{$id}++)
        {
            return "<strong>Circular includes on $id!</strong>";
        }
        my $page = GetPage($id);
        my $text = $page->{text_default}{data}{html};
        my $frag;
        if (my $section = $params{section})
        {
            # chop off text before and including header
            # NOTE if the html output fmt ever changes, this will
            #      need to change as well
            #<H2><a name="Nexus_Team_Aliases"></a>Nexus Team Aliases</H2>
            if ($text =~ s,^.*<H(\d)><a name="(.+?)"></a>([\d\.]+ )?$section</H\d>,,s)
            {
                my $depth = join("", (1..$1));
                # by default we include sub-sections. if subsection
                # is set to false, remove them
                $depth = "\\d"
                    if defined $params{subsection} and not $params{subsection};
                # save the fragment id
                $frag = $2;

                # now chop off the trailing part
                $text =~ s,<H[$depth]><a name="(.+?)"></a>.+?</H[$depth]>.*$,,s;
            }
        }
        $out .= $text."\n". '<div align="right"><small>[goto '.
            ($frag ?
             GetPageLinkText($id."\#".$frag, $frag. " in ". $id) :
             GetPageLinkText($id, $id)).
            ']</small></div><p/>'."\n";
    }
    else
    {
        foreach my $id (values %params)
        {
            if ($included->{$id}++)
            {
                return "<strong>Circular includes on $id!</strong>";
            }
            my $page = GetPage($id);
            $out .= $page->{text_default}{data}{html}.
                "\n". '<div align="right"><small>[goto '.
                GetPageLinkText($id, $id).
                ']</small></div><p/>'."\n";
        }
    }
    return $out;
}

my $pagecache = {};

sub GetPage
{
    my $id = shift;

    # return things from the cache
    return $pagecache->{$id} if $pagecache->{$id};

    local %SaveUrl;
    local %SaveNumUrl;
    local $SaveUrlIndex;
    local $SaveNumUrlIndex;

    my $pfile = GetPageFile(FreeToNormal($id));
    my ($stat, $data) = ReadFile($pfile);
    return {} unless $stat;
    my %Page = split(/$FS1/, $data, -1);  # -1 keeps trailing null fields
    my %Section = split(/$FS2/, $Page{"text_default"}, -1);
    my %Text = split(/$FS3/, $Section{'data'}, -1);
    my $p = \%Page;
    $p->{"text_default"} = \%Section;
    $p->{"text_default"}{"data"} = \%Text;
    $p->{"text_default"}{"data"}{html} =
        WikiToHTML($p->{text_default}{data}{text});

    $pagecache->{$id} = $p;   # save in the cache

    return $p;
}

1;
