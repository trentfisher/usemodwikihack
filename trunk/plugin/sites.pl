# simple plugin to list sites from cm-hosts.txt;

use lib "/vobs/cm/lib/perlmod";
use Siebel::ClearCase::Conf qw(CCparam);

sub sites
{
    my $out = "";
    $out .= "<p>See <a href=\"../pod/Siebel/ClearCase/Conf.html\">Siebel::ClearCase::Conf</a> for more information</p>\n";

    $out .= "<table class=wikitable>\n";
    foreach my $s (@{CCparam("FindSites")})
    {
        $out .= "<tr><th class=wikitable colspan=2>Site $s</th></tr>\n";
        foreach my $t (qw(license registry repository vob view build))
        {
            $out .= tableline("td class=wikitable", "",
                              ucfirst($t),
                              join(" ",
                                   @{CCparam("FindHosts",
                                             site => $s, role => $t)}));
        }
    }
    $out .= "</table>\n";

    return $out;
}

# print a list as an HTML table row
sub tableline
{
    my $tag = shift;
    my $style = shift;
    my @data = @_;

    foreach my $i (@data)
    {
	$i = "&nbsp;" unless $i;
	$i =~ s/^$/&nbsp;/;
    }
    return(
           "<tr>\n".
	   "    <$tag>" . join("</$tag>\n    <$tag>", @data) . "</$tag>\n".
	   "  </tr>\n");
}

1;
