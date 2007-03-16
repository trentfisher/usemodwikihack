#!/vobs/cmweb/bin/perl

$|=1;
use lib ("/vobs/cmweb/lib");
use CMweb::Progress;
use CGI;

my $c=new CGI;

print $c->header();

print $c->start_html(-title=>"progress bar test with module",
		     -style=> {'src' => '/default.css'},
                     -script=>[
                               {-language=>'javascript',
                                -src=>'printf.js'},
                               {-language=>'javascript',
                                -src=>'progress.js'}]);
print $c->h1("Progress test with module\n");

my $iter = 20;
my $p1 = new CMweb::Progress();
my $p2 = new CMweb::Progress();

print $p1->start();
print $p2->start();
sleep(1);

my $act = 1;
foreach my $i (0..$iter)
{
    if (rand(10) < 2)
    {
        print $p1->update($i, $iter, "Doing action ".$act);
        print $p2->update($i, undef, "Doing action ".$act);
        $act++;
        sleep(1);
    }
    else
    {
        print $p1->update($i, $iter);
        print $p2->update($i);
    }
    sleep int(rand(1));
}

print $p1->finish($iter, $iter, "Done!");
print $p2->finish($iter, undef, "Done!");

print $c->end_html();

exit 0;
