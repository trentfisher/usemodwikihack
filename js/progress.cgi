#!/vobs/cmweb/bin/perl

$|=1;
use CGI;

my $c=new CGI;

print $c->header();

print $c->start_html(-title=>"progress bar test",
		     -style=> {'src' => '/default.css'},
                     -script=>[
                               {-language=>'javascript',
                                -src=>'printf.js'},
                               {-language=>'javascript',
                                -src=>'progress.js'}]);
print $c->h1("Progress test\n");

my $c = 1000;
print <<CHUMBA;
<div id="progress1" style="border: 1px solid black;">Loading...</div>
<div id="progress2" style="border: 1px solid black;">Loading...</div>
<script type="text/javascript">
    var prog1 = new ProgressBar("progress1");
    var prog2 = new ProgressBar("progress2");
</script>
CHUMBA

sleep(1);

my $act = 1;
foreach my $i (0..$c)
{
    if (rand(10) < 2)
    {
        print "<script type=\"text/javascript\">prog1.update($i, $c, \"",
        "Doing action ",$act,"\");</script>\n";
        print "<script type=\"text/javascript\">prog2.update($i, undefined, \"",
        "Doing action ",$act,"\");</script>\n";
        $act++;
        sleep(1);
    }
    else
    {
        print "<script type=\"text/javascript\">prog1.update($i, $c);</script>\n";
        print "<script type=\"text/javascript\">prog2.update($i);</script>\n";
    }
    sleep int(rand(1));
}

