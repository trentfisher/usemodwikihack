/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
/* Javascript based odometer */

// Constructor
// id     div ID name
// digits how many digits to display
// rate   increment per second
// start  starting number
function Odometer(id, digits, rate, start)
{
    var odiv = document.getElementById(id);
    var rings = new Array(digits);
    var log = document.getElementById("log");

    // set up odometer area
    odiv.style.border = "1px solid black";
    odiv.style.height = "2.3ex";
    odiv.style.overflow = "hidden";

    for (var i = 0; i < digits; i++)
    {
        rings[i] = document.createElement("div");
        rings[i].style.position = "relative";
        rings[i].style.backgroundColor = "lightgrey";
        rings[i].style.width = ".8em";
        rings[i].style.cssFloat = "left";
        rings[i].style.marginLeft = ".05em";
        rings[i].style.marginRight = ".05em";
        rings[i].style.paddingLeft = "0em";
        rings[i].style.paddingRight = "0em";
        rings[i].style.textAlign = "center";
        rings[i].topcnt = 0;
        rings[i].innerHTML = "0<br/>1<br/>2<br/>3<br/>4<br/>5<br/>6<br/>7<br/>8<br/>9<br/>0<br/>";

        /* IE cannot appendChild properly, though this bit of code kinda works
        odiv.innerHTML += '<div style="';
        odiv.innerHTML += rings[i].style.cssText;
        odiv.innerHTML += '>0<br/>1<br/>2<br/>3<br/>4<br/>5<br/>6<br/>7<br/>8<br/>9<br/>0<br/></div>';
        //rings[i] = odiv.lastChild;
        continue;
        */

        odiv.appendChild(rings[i]);
    }
    odiv.style.width = (0.91*digits)+"em";

    this.setRate = function(r)
    {
        rate = r;
        for (var i = 0; i < digits; i++) rings[i].style.lineHeight = "";
    };

    // update the counter
    var update = function()
    {
        // calculate dimensions here in case the text size has been changed
        var nh = rings[0].offsetHeight/11;  // height of one num
        var rh = nh*10;  // height of the "ring"
        var ssh = nh*9;  // point at which the next ring should start moving
        var incr = rate/10*nh;

        // if the rate is too fast skip over the earlier rings
        var startring = rings.length-1;
        while (incr >= nh)
        {
            // mash this ring together... kinda blury
            rings[startring].style.lineHeight = "1ex";
            rings[startring].style.top = -0.5*Math.random()*rings[startring].offsetHeight + "px";
            startring--;
            incr /= 10;
        }
        // we don't have enough rings for this rate
        if (startring < 0)
        {
            setTimeout(update, 100);
            return;
        }

        log.innerHTML = "nh = "+nh+" rh = "+rh+" ssh = "+ssh;
        for (var i = 0; i < digits; i++) log.innerHTML += " "+rings[i].topcnt

        // move the right-most ring
        rings[startring].topcnt -= incr;
        rings[startring].style.top = rings[startring].topcnt + "px";

        for (var i = startring-1; i >= 0; i--)
        {
            // at the end of the "ring" go back to the top
            if (rings[i+1].topcnt + rh <= 0)
            {
                rings[i+1].topcnt = 0;
                rings[i+1].style.top = rings[i+1].topcnt+"px";
                // force the next ring to be in the right place
                rings[i].topcnt = Math.round(rings[i].topcnt / nh) * nh;
                rings[i].style.top = rings[i].topcnt + "px";
            }
            // on the last number, we want to scroll the next number
            // at the same rate
            if (rings[i+1].topcnt + ssh < 0)
            {
                rings[i].topcnt -= incr;
                rings[i].style.top = rings[i].topcnt + "px";
            }
        }
        // make the left-most ring rotate properly
        if (rings[0].topcnt + rh <= 0)
        {
            rings[0].topcnt = -0.1*nh;
            rings[0].style.top = rings[i+1].topcnt+"px";
        }

        // the next go-around...
        setTimeout(update, 100);
    };

    update();
    setTimeout(update, 100);
}
