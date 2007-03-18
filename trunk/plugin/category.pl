# simply category module
# with no params, spits out a list of pages in the category
# with params, displays a box with the categories

sub category
{
    my %params = @_;

    local $_;
    if (%params)
    {
        my @links = map(GetPageOrEditLink($_), (values %params));
        return ("<div class=wikicategorybox>".
                "<strong>Categories:</strong>  ".
                join(", ", @links).
                "</div>");
    }
    else
    {
        my $t = &GetParam('keywords', '');
        $t =~ s/_/[_ ]/g;  # spaces in titles can become underscores... ugh!
        return ("<ul>\n".
                join("",
                     map("<li>".GetPageOrEditLink($_)."</li>\n",
                         (SearchBody($t)))).
                "</ul>\n");
    }
}

1;
