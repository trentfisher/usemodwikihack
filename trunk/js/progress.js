/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
**
** This is a simple module for displaying a progress bar in a div
** This is for long-running CGI processes
** Call like so:

<div id="progress" style="border: 1px solid black;">loading...</div>
<script type="text/javascript">
    var prog = new ProgressBar("progress", "I am doing X");
</script>

Then on each update, send this to the client (where the numbers are the
Items to do and the total estimated), the text is optional.

<script type="text/javascript">prog.update(1, 100, "I am doing Y");</script>

 */
function ProgressBar(id, action)
{
    this.div = document.getElementById(id);
    this.starttime = new Date();
    if (action == undefined) { action = "Loading"; }

    // set up the divs
    this.div.style.overflow = "hidden";
    this.div.style.position = "relative";
    this.div.style.height   = "3ex";
    this.div.innerHTML = "<div></div><div></div>";
    this.bardiv = this.div.childNodes[0];
    this.bardiv.style.background = "lightgrey";
    this.bardiv.style.position   = "relative";
    this.bardiv.style.width      = "0%";
    this.bardiv.style.height     = "3ex";
    this.bardiv.style.zIndex     = "-1";
    this.txtdiv = this.div.childNodes[1];
    this.txtdiv.style.textAlign = "center"; 
    this.txtdiv.style.position  = "relative"; 
    this.txtdiv.style.height    = "3ex"; 
    this.txtdiv.style.top       = "-2.8ex";

    // update the status bar
    this.update = function(cur, tot, newact)
    {
        if (newact != undefined) { action = newact; }
        var now = new Date();
        var timespan = (now.valueOf() - this.starttime.valueOf())/1000;
        var msg;
        if (tot > 0)
        {
            var percent = cur/tot;
            var tottime = tot*(timespan/cur);
            this.txtdiv.innerHTML =
                printf("%s... %d of %d (%.1f%s) %s ETA %s",
                       action, cur, tot, (100*percent), "%",
                       this.formatTime(timespan),
                       this.formatTime(tottime-timespan));
            this.bardiv.style.width = (100*percent)+"%";
        }
        else
        {
            this.txtdiv.innerHTML =
                action+"... "+cur+", "+this.formatTime(timespan);
            this.bardiv.style.width = "5%";
            // get out your trig textbooks... mapping a sine wave to the
            // width of the div we are in... minus the width of the "bar"
            var halfwid = this.div.offsetWidth/2 * 0.95;
            this.bardiv.style.left =
                (halfwid +
                 halfwid * Math.sin(10*Math.PI *
                                    (timespan / (halfwid))))+"px";
        }
    };

    // format time from seconds to something more readable
    this.formatTime = function(t)
    {
        if (t < 60) { return Math.round(t)+"s"; }
        return Math.floor(t/60)+"m "+Math.round(t%60)+"s";
    };
}
