
sub groups
{
my $conf = "/vobs/cm/utils/audit/acl/vobs.conf";

my %groups;
my %vobgroup;

open(F, $conf) || warn "Error: cannot open $conf: $!\n";
while(<F>)
{
    chomp;
    # get rid of comments, skip blank lines
    s/\s*\#.*//;
    next if /^\s*$/;

    my ($v, @f) = split;

    grep((s(^all$)(ALL)i, $vobgroup{$v}{$_}++, $group{$_}++), @f);
}
close(F);

my $out;
my @grouplist = sort keys %group;
$out .= "<table class=wikitable >\n";
my @groupheaders = @grouplist;
grep((uc($_) ne "ALL") &&
     ($_ = "<a href=\"/policy/group.cgi?group=$_\">$_</a>"),
     @groupheaders);
$out .= $q->Tr({"class=wikitable"},
               $q->th({"class=wikitable"}, ["", @groupheaders])). "\n";
foreach my $v (sort keys %vobgroup)
{
    my @c;
    foreach my $g (@grouplist)
    {
        push @c, ($vobgroup{$v}{$g} ? "X" : "&nbsp;");
    }
    my $sv = $v; $sv =~ s(/vobs/)();  # chop off /vobs
    $out .= $q->Tr(
                   $q->th({q(style="background-color: lightgrey; text-align: left; font-family: courier, lucida console, sans-serif;")},
                          $q->a({-href => "/policy/attrexp.cgi?path=$v"}, $sv)).
                   $q->td({q(style="text-align: center; background-color: lightgrey;")}, \@c)). "\n";
}
$out .= "</table>\n";

return $out;
}
