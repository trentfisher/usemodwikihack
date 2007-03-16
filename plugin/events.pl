
# pick out events from the current events page
sub events
{
# configuration (this should be parameterized)
my $c = "page/C/CurrentEvents.db";
$numevents = 4;

open(F, $c) || warn "Error: cannot open $c: $!\n";
while(<F>)
{
    s/^\s+//;
    s/\s+$//;
    push @event, "$1: \'\'$2\'\'" if /^\|\|\s*(.*?)\s*\|\|\s*(.*?)\s*\|\|/;
}
close(F);

    local %SaveUrl;
    local %SaveNumUrl;
    local $SaveUrlIndex;
    local $SaveNumUrlIndex;
return WikiToHTML(join("...  ", @event[0..$numevents]). " ............. \n");
}

1;
