/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
/* javascript counter */

// Constructor:
// id     div ID name
// start  starting number
// rate   increment per second
// delay  update interval in milliseconds
function Counter(id, start, rate, delay)
{
    var div = document.getElementById(id);
    var starttime = new Date();
    var update = function()
    {
        var now = new Date();
        var timespan = (now.valueOf() - starttime.valueOf())/1000;
        div.innerHTML = Math.round(start+(timespan*rate));
        setTimeout(update, delay);
    }
    update();
    setTimeout(update, delay);
}
