/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
/*
** Javascript object for generating "sparkline" graphs
** See http://www.edwardtufte.com/bboard/q-and-a-fetch-msg?msg_id=0001OR&topic_id=1&topic=
*/

function SparkLine(id)
{
    // this is where we are drawing the graph
    this.canvasdiv = document.getElementById(id);
    this.canvas = new jsGraphics(id);

    // The data to be plotted
    this.dataset = new Array();
    this.datasetEnable = new Array();

    // margin between the edge of the DIV and the actual graph
    this.offsetL = 0;
    this.offsetR = 0;
    this.offsetT = 0;
    this.offsetB = 0;

    // color spectrum... should we use shades of certain colours instead?
    this.colors = new Array("Black", "Red", "Orange", "Yellow",
                            "Green", "Blue", "Indigo", "Violet");

    this.normalBarColor = "lightgrey";
    this.normalMax;
    this.normalMin;
    this.normalMid;

    //----------------------------------------------------------------------
    // add a data point to the graph
    //
    this.addPoint = function(s, x, y)
    {
        if (! this.dataset[s])
           this.dataset[s] = {px:new Array(), py:new Array};
        this.dataset[s].px.push(Number(x));
        this.dataset[s].py.push(Number(y));
        this.datasetEnable[s] = 1;
    };

    //----------------------------------------------------------------------
    // add a data set... arrays for x and y
    //
    this.addSet = function(s, x, y)
    {
        this.dataset[s] = { px: x, py: y };
        this.datasetEnable[s] = 1;
    };

    // enable or disable a dataset
    this.enableSet = function(s, toggle)
    {
        this.datasetEnable[s] = toggle;
    };

    //----------------------------------------------------------------------
    // plot the graph
    //
    this.plot = function()
    {
        // clear off the canvas first
        this.canvas.clear();
        this.canvas.paint();

        this.calculateBounds();
        // height and width of the graphable area of the canvas
        // allow 2 pixels for the border and 2 for padding inside border
        this.gHeight = this.canvasdiv.offsetHeight-2;
        this.gWidth = this.canvasdiv.offsetWidth-2;

        // draw the normal bar
        if (this.normalMax != undefined && this.normalMin != undefined)
        {
            this.canvas.setColor(this.normalBarColor);
            var pmax = this.graph2canvasY(this.normalMax);
            var pmin = this.graph2canvasY(this.normalMin);
            if (this.normalMid == undefined)
            {
                this.canvas.fillRect(0, pmax,
                                     this.canvasdiv.offsetWidth-2, pmin);
            }
            else
            {
                //XXX this doesn't work right!  Don't know why!
                var pmid = this.graph2canvasY(this.normalMid);
                this.canvas.fillRect(0, pmax,
                                     this.canvasdiv.offsetWidth-2, pmid-1);
                this.canvas.drawRect(0, pmid+1,
                                     this.canvasdiv.offsetWidth-2, pmin);
            }
        }

        for (d = 0; d < this.dataset.length; d++)
        {
            if (! this.dataset[d]) continue;  // no such dataset
            if (! this.datasetEnable[d]) continue; // disabled

            this.canvas.setColor(this.colors[d]);
            var lastX = undefined;
            var lastY = undefined;
            for (i = 0; i < this.dataset[d].px.length; i++)
            {
                var x = this.graph2canvasX(this.dataset[d].px[i]);
                var y = this.graph2canvasY(this.dataset[d].py[i]);
                // check if this data point is out of bounds
                if (x < 0 ||
                    x > this.canvasdiv.offsetWidth-1 ||
                    y < 0 ||
                    y > this.canvasdiv.offsetHeight-1 )
                {
                    this.LOG(2, "out of range dataset "+d+" "+
                             this.dataset[d].px[i]+","+
                             this.dataset[d].py[i]+" to "+x+","+y);
                    // XXX put in an indicator that we went off the graph
                    // put a break in a line if we are drawing one
                    lastX = lastY = undefined;
                    continue;
                }
                this.LOG(2, "plotting dataset "+d+" "+this.dataset[d].px[i]+","+
                         this.dataset[d].py[i]+" to "+x+","+y);
                if (lastX != undefined && lastY != undefined)
                {
                    this.canvas.drawLine(lastX, lastY, x, y);
                }
                // last data point
                if (i == this.dataset[d].px.length-1)
                {
                    this.canvas.setColor("red");
                    this.canvas.drawRect(x-1, y-1, 2, 2);
                }
                lastX = x;
                lastY = y;
            }
        }
        this.canvas.paint();
    };


    //----------------------------------------------------------------------
    // Figure out the minimum/maximum numbers on each axis
    // we use these as boundaries for the graph unless the user
    // wants other dimensions
    this.calculateBounds = function()
    {
        // no data!
        if (!this.dataset[0]) return;

        // figure out the min/max of the data
        this.maxXdata = this.dataset[0].px[0];
        this.maxYdata = this.dataset[0].py[0];
        this.minXdata = this.dataset[0].px[0];
        this.minYdata = this.dataset[0].py[0];
        for (var d = 0; d < this.dataset.length; d++)
        {
            if (! this.dataset[d]) continue;  // no such dataset

            // NOTE: we assume PX and PY are the same length!
            for (var i = 0; i < this.dataset[d].px.length; i++)
            {
                if (this.dataset[d].px[i] > this.maxXdata)
                    this.maxXdata = this.dataset[d].px[i];
                if (this.dataset[d].px[i] < this.minXdata)
                    this.minXdata = this.dataset[d].px[i];
                if (this.dataset[d].py[i] > this.maxYdata)
                    this.maxYdata = this.dataset[d].py[i];
                if (this.dataset[d].py[i] < this.minYdata)
                    this.minYdata = this.dataset[d].py[i];
            }
        }
        // set dimensions of the graph using the data min/max unless
        // overridden by the user
        this.maxX = Number(this.maxXgraph == null ? this.maxXdata : this.maxXgraph);
        this.minX = Number(this.minXgraph == null ? this.minXdata : this.minXgraph);
        this.maxY = Number(this.maxYgraph == null ? this.maxYdata : this.maxYgraph);
        this.minY = Number(this.minYgraph == null ? this.minYdata : this.minYgraph);

    };

    //----------------------------------------------------------------------
    // Convert between data scale and pixel location for both X and Y
    //
    this.graph2canvasX = function(x)
    {
        if (this.maxX==this.minX)
        {
            return Math.round(this.gWidth/2);
        }
        return Math.round(this.gWidth / (this.maxX-this.minX) *
                          (x - this.minX));
    };
    this.graph2canvasY = function(y)
    {
        // only one data point
        if (this.maxY==this.minY)
        {
            return(this.gHeight / 2);
        }
        return Math.round(this.gHeight -
                          (this.gHeight / (this.maxY-this.minY)) *
                          (y - this.minY));
    };

    //------------------------------------------------------------------------
    // logging functions
    //
	this.logdiv = undefined;
    this.setLog = function(id, level)
    {
        this.logdiv = document.getElementById(id);
        this.loglevel = level;
        this.starttime = new Date();
    };
	this.LOG = function(level, msg)
    {
        if (this.logdiv != undefined && level <= this.loglevel)
        {
            var now = new Date();
            var indent = "";
            for (var i = 1; i < level; i++) { indent += " "; };
            this.logdiv.innerHTML += "+"+
                                   (now.valueOf() - this.starttime.valueOf())+
                                   ":  "+indent+msg+"<br/>";
        }
	};
}
