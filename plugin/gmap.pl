# lat
# lon

sub gmap
{
    my %param = @_;
    my $width  = ($param{width} || "300px");
    my $height = ($param{height} || "300px");
    my $out = "";

    $out .= <<GMAPP1;
<div id="map" style="border: 1px solid black; width: $width; height: $height;"></div>
<script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=ABQIAAAAYDwEr2XzX7IB4-64s9x1RBQ2RnTEQ4i5D-exJzPrIkJcZYQJzRQESBiDSs0DSBDaGR5I9Cnkn5ZYfA" type="text/javascript"></script>
<script type="text/javascript">
//<![CDATA[
if (GBrowserIsCompatible())
{
    var map = new GMap2(document.getElementById("map"));
    map.addControl(new GSmallMapControl());
    map.addControl(new GMapTypeControl());
    map.setCenter(new GLatLng($param{lat}, $param{lon}), 14);
    // set up all markers
    var markers = new Array();
GMAPP1

    my $markers = getUpdatedMarkerList($param{lat}, $param{lon},
                                       $OpenPageName,
                                       ($param{marker} || "G_DEFAULT_ICON"));
    
    foreach my $m (@$markers)
    {
        $out .= sprintf("markers.push(new GMarker(new GLatLng(%s, %s), {title: '%s', icon: %s}));\n",
                        $m->{lat}, 
                        $m->{lon}, 
                        $m->{page}, 
                        ($m->{marker} || "G_DEFAULT_ICON"));
    }
#    map.addOverlay(new GMarker(new GLatLng($param{lat}, $param{lon})));
    $out .= <<GMAPP2;
    for (var i = 0; i < markers.length; i++)
    {
        map.addOverlay(markers[i]);
    }

    GEvent.addListener(map, "click",
        function(marker, point)
        {
            if (marker) {
                //log.innerHTML+='<a href="$FullUrl/'++'">'++'</a>';
                marker.openInfoWindowHtml(
                    '<a href="$FullUrl/'+
                                            marker.od.title+'">'+
                                            marker.od.title+'</a>');
            } else {
                var m = new GMarker(point);
                markers.push(m);
                map.addOverlay(m);
                m.openInfoWindowHtml(document.createTextNode("new marker at"+
                                                             point.x+", "+
                                                             point.y));
            }
        });

}    
//]]>
</script>
GMAPP2

}

sub getUpdatedMarkerList
{
    my $lat = shift;
    my $lon = shift;
    my $page = shift;
    my $marker = shift;

    my $mfile = "$DataDir/plugin/gmapmarkers.txt";
    local *F;
    my $mlist = [];
    my $updated = undef;
    my $foundentry = undef;


    if (-f $mfile)
    {
        open(F, $mfile) ||
            warn "Error: unable to open marker list $mfile: $!\n";

        while(my $l = <F>)
        {
            chomp $l;
            $l =~ s/\#.*$//;
            if ($l =~ /^([+-\d\.]+) ([+-\d\.]+) (\w+) (.+)/)
            {
                my $entry = {lat=> $1, lon => $2, marker => $3, page => $4};
                if ($entry->{page} eq $page)
                {
                    $foundentry = 1;
                    # XXX what if params change $updated++
                }
                push @$mlist, $entry;
            }
            else
            {
            }
        }
        close(F);
    }
    # if this page was not listed, add it
    if (not $foundentry)
    {
        push @$mlist, {lat=> $lat, lon => $lon,
                       marker => $marker, page => $page};
        $updated++;
    }
    # write out the updated list
    # XXX should lock file
    if ($updated)
    {
        open(F, "> $mfile") ||
            warn "Error: unable to update marker list $mfile: $!\n";
        foreach my $e (@$mlist)
        {
            printf F "%s %s %s %s\n", $e->{lat}, $e->{lon},
                                      $e->{marker}, $e->{page};
        }
        close(F);
    }
    return $mlist;
}

1;

    # generate index of pages with locations if something has changed
#    return '<iframe width="100%" height="200px" id="gmapframe" src="'.
#        $FullUrl.'/plugin/gmapframe.html">something</iframe>';
