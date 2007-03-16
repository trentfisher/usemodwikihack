#
# simple plugin to show certain files on the server side
#

sub showfile
{
    my %params = @_;
    my $out = "";
    foreach my $id (values %params)
    {
        if ($id eq "intermap")
        {
            $out .= "<table class=wikitable>\n";
            $out .= "<tr><th colspan=2>InterWiki Links</th></tr>\n";
            $out .= "<tr><th>Prefix</th><th>URL Prefix</th></tr>\n";
            GetSiteUrl("nothing");  # initialize the hash
            foreach my $pre (sort keys %InterSite)
            {
                my $url = $InterSite{$pre};
                $out .= "<tr><td>$pre</td><td>$url</td></tr>\n";
            }
            $out .= "</table>\n";
        }
    }
    return $out;
}

1;
