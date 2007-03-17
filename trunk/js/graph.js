/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
/*
 * JavaScript object for generating XY graphs
 */

// Conversion factors from seconds
var MSEC = 1000;
var MIN  = 60;
var HOUR = 60*MIN;
var DAY  = 24*HOUR;
var WEEK = 7*DAY;

// Constructor
function oGraph(id)
{
    // this is where we are drawing the graph
    this.canvasdiv = document.getElementById(id);
    this.canvas = new jsGraphics(id);

    // The data to be plotted
    this.dataset = new Array();
    this.datasetEnable = new Array();

    // margin between the edge of the DIV and the actual graph
    this.offsetL = 10;
    this.offsetR = 3;
    this.offsetT = 1;
    this.offsetB = 10;

    // how many tics to have on each axis, and how long they should be
    this.ticsX = 5;
    this.ticsY = 5;
    this.ticLen = 3;
    this.labelFontSz = 10;
    // color spectrum... should we use shades of certain colours instead?
    this.colors = new Array("Red", "Orange", "Yellow",
                            "Green", "Blue", "Indigo", "Violet");

    // grid
    this.showGrid = 1;
    this.showAxis = 1;

    // plot type
    this.plotPoints = 1;
    this.plotLines = 1;
    this.timeSeries = 0;  // this only affects how the grid/tics/labels
    this.stackGraph = 0;

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
        this.starttime = new Date();  // reset time index
        this.LOG(1, "Plotting Graph");
        // clear off the canvas first
        this.canvas.clear();
        this.canvas.paint();

        this.calculateBounds();
        // height and width of the graphable area of the canvas
        // allow 2 pixels for the border and 2 for padding inside border
        this.gHeight = this.canvasdiv.offsetHeight-this.offsetT-this.offsetB-4;
        this.gWidth = this.canvasdiv.offsetWidth-this.offsetR-this.offsetL-4;

        if (this.stackGraph)
        {
            this._stackPlot();
        }
        else
        {
            this._plot();
        }
        this.canvas.paint();
        this.LOG(1, "Done Plotting Graph");
    };

    // plot an XY graph -- INTERNAL FUNCTION
    this._plot = function()
    {
      this.drawGrid();
      this.drawAxis();
      this.drawBorder();

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
              if (x < this.offsetL+1 ||
                  x > this.canvasdiv.offsetWidth-this.offsetR-1 ||
                  y < this.offsetT+1 ||
                  y > this.canvasdiv.offsetHeight-this.offsetB-1 )
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
              if (this.plotLines)
              {
                  if (lastX != undefined && lastY != undefined)
                  {
                      this.canvas.drawLine(lastX, lastY, x, y);
                  }
              }
              if (this.plotPoints)
              {
                  this.canvas.drawRect(x-1, y-1, 2, 2);
              }
              lastX = x;
              lastY = y;
          }
      }
    };

    //----------------------------------------------------------------------
    // draw a stacked "area" graph
    // XXX does not deal with datapoints "off the graph"
    this._stackPlot = function()
    {
        var stackdata = this.stackData();

        // height and width of the graphable area of the canvas
        // allow 2 pixels for the border and 2 for padding inside border
        this.gHeight = this.canvasdiv.offsetHeight-this.offsetT-this.offsetB-4;
        this.gWidth = this.canvasdiv.offsetWidth-this.offsetR-this.offsetL-4;

        this.drawGrid();
        this.drawAxis();
        this.drawBorder();

        // go through each stack and come up with a polygon
        // biggest one first, so we go through the list backwards
        for (var s = stackdata.stack.length-1; s >= 0; s--)
        {
            if (! this.dataset[s]) continue;  // no such dataset
            if (! this.datasetEnable[s]) continue; // disabled

            var polyX = new Array(this.graph2canvasX(this.maxX),
                                  this.graph2canvasX(this.minX));
            var polyY = new Array(this.graph2canvasY(this.minY),
                                  this.graph2canvasY(this.minY));
            for (var t = 0; t < stackdata.time.length; t++)
            {
                polyX.push(this.graph2canvasX(stackdata.time[t]));
                polyY.push(this.graph2canvasY(stackdata.stack[s][t]));
            }
            this.canvas.setColor(this.colors[s]);
            this.canvas.fillPolygon(polyX, polyY);

            // draw points, where there are datapoints
            if (this.plotPoints)
            {
                this.canvas.setColor('black');
                for (var t = 0; t < stackdata.time.length; t++)
                {
                    if (stackdata.data[s][t] == undefined) continue;
                    this.canvas.drawRect(polyX[2+t] - 1, polyY[2+t] - 1,
                                         2, 2);
                }
            }
        }
        this.canvas.paint();
        this.LOG(1, "Done Plotting Stacked Graph");
    };

    // helper for stackPlot... gathers data together into a common X axis
    // and interpolates points so that time-series stacks look right
    this.stackData = function()
    {
        // these counters are for keeping track of how much of each
        // dataset we have processed
        var counters = new Array(this.dataset.length);
        for (var i = 0; i < counters.length; i++)
        {
            if (this.dataset[i] && this.datasetEnable[i])
            {
                counters[i] = 0;
            }
            else
            {
                // this dataset is either disabled or non-existent
                counters[i] = this.dataset[i].length+1;
            }
        }

        // helper - find which dataset has the smallest y value
        // according to the counters
        function minIndex(c, ds)
        {
            var min = Infinity;
            var mini = 0;
            for (var i = 0; i < c.length; i++)
            {
                if (c[i] < ds[i].px.length && ds[i].px[c[i]] < min)
                {
                    min = ds[i].px[c[i]];
                    mini = i;
                }
            }
            return mini;
        }
        // helper - are there any data points left to be processed
        // we are done when all counters pass the end of all lists
        function remaining(c, ds)
        {
            for (var i = 0; i < c.length; i++)
            {
                if (c[i] < ds[i].px.length)
                return 1;
            }
            return 0;
        }

        //
        // construct the stacked data structure
        //
        var stackdata = {time:new Array(), data:new Array(),
                         stack:new Array()};
        for (var i = 0; i < counters.length; i++)
        {
            stackdata.data[i] = new Array();
            stackdata.stack[i] = new Array();
        }
        var tindex = 0;
        var lastt;
        while(remaining(counters, this.dataset))
        {
            var t = minIndex(counters, this.dataset);
            if (lastt == undefined) lastt = this.dataset[t].px[counters[t]];
            if (lastt != this.dataset[t].px[counters[t]]) tindex++;

            // store it in the new structure
            stackdata.time[tindex] = this.dataset[t].px[counters[t]];
            stackdata.data[t][tindex] = this.dataset[t].py[counters[t]];

            lastt = this.dataset[t].px[counters[t]];
            counters[t]++;
        }

        //
        // now generate the "stacked" data values
        //
        for (var t = 0; t < stackdata.time.length; t++)
        {
            for (var d = 0; d < stackdata.data.length; d++)
            {
                var thisdata = stackdata.data[d][t];

                // if this dataset is disabled or nonexistent,
                // we give zero to prevent NaN from propagating through
                if (! this.dataset[d] || ! this.datasetEnable[d])
                    thisdata = 0;
  
                // if there is no data value for this timeslot, interpolate
                if (thisdata == undefined)
                {
                    // find the next data point
                    var nextt = undefined;
                    for (var i = t+1; i < stackdata.time.length; i++)
                        if (stackdata.data[d][i] != undefined)
                        { nextt = i; break; }
                    // find the previous data point
                    var prevt = undefined;
                    for (var i = t-1; i >= 0; i--)
                        if (stackdata.data[d][i] != undefined)
                        { prevt = i; break; }

                    // this shouldn't happen, but just in case
                    if (nextt == undefined && prevt == undefined)
                        thisdata = 0;
                    // no ending data
                    if (nextt == undefined)
                        thisdata = stackdata.data[d][prevt];
                    // no starting data
                    else if (prevt == undefined)
                        thisdata = stackdata.data[d][nextt];
                    // interpolate
                    else
                        thisdata = (stackdata.time[t]-stackdata.time[prevt]) *
                            ((stackdata.data[d][nextt]-stackdata.data[d][prevt]) /
                             (stackdata.time[nextt]-stackdata.time[prevt])) +
                            stackdata.data[d][prevt];
                }

                // now, add it to the data from the last stack line
                stackdata.stack[d][t] = (d > 0 ? stackdata.stack[d-1][t] : 0) +
                                        thisdata;
                // fix the y axis
                this.maxY = Math.max(this.maxY, stackdata.stack[d][t]);
            }
        }
        return stackdata;
    };

    //----------------------------------------------------------------------
    // draw the grid on the graph... must be called after calculateBounds()
    //
    this.drawBorder = function()
    {
      // draw a box around the whole thing
      this.canvas.setColor("#000000");
      this.canvas.drawRect(this.offsetL, this.offsetT,
                           this.canvasdiv.offsetWidth - this.offsetR - this.offsetL,
                           this.canvasdiv.offsetHeight - this.offsetB - this.offsetT);

      // tic marks ...
      var ticincrX = (this.maxX-this.minX)/(this.ticsX-1);
      if (ticincrX == 0) ticincrX = 1;  // all data has same x
      var ticstart = this.minX;
      if (this.timeSeries)
      {
          var d = new Date(this.minX*MSEC);
          if (this.maxX-this.minX < HOUR)
          {
              ticincrX = 5*MIN;
              // start on a 5 min boundary
              d.setMinutes(d.getMinutes()+d.getMinutes()%5);
              d.setSeconds(0); d.setMilliseconds(0);
              ticstart = d.getTime()/MSEC;
          }
          else if (this.maxX-this.minX < DAY)
          {
              ticincrX = HOUR;
              // start on a hour boundary
              d.setMinutes(0);
              d.setSeconds(0); d.setMilliseconds(0);
              ticstart = d.getTime()/MSEC + HOUR;
          }
          else if (this.maxX-this.minX < 3*DAY)
          {
              ticincrX = 6*HOUR;
              // start on a 6 hour boundary
              var h = d.getHours();
              d.setHours(h+h%6); d.setMinutes(0);
              d.setSeconds(0); d.setMilliseconds(0);
              ticstart = d.getTime()/MSEC;
          }
          else if (this.maxX-this.minX < 10*WEEK)
          {
              ticincrX = DAY;
              // start on a day boundary
              d.setHours(0); d.setMinutes(0);
              d.setSeconds(0); d.setMilliseconds(0);
              ticstart = (d.getTime()+DAY*MSEC)/MSEC;
          }
          this.ticsX = (this.maxX-this.minX)/ticincrX;
      }
      this.LOG(2, "tics X "+this.ticsX+" data range "+
               this.minX+" - "+this.maxX+" ticincr = "+ticincrX);
      for (var t = 0; t < this.ticsX; t++)
      {
        var lastlabel;
        var lastdate;
        var x = ticstart + t * ticincrX;
        var dx = this.graph2canvasX(x);
        this.LOG(2, "tic mark on X at "+x+" => "+dx);
        this.canvas.drawLine(dx, this.canvasdiv.offsetHeight-this.offsetB,
                             dx, this.canvasdiv.offsetHeight-this.offsetB-this.ticLen);
        var label = x;
        if (this.timeSeries)
        {
            var d = new Date(x*MSEC);
            var zeropad = function(n, d)
                {
                    n = String(n);
                    while (n.length < d) n = "0"+n;
                    return n;
                };
            if (this.maxX-this.minX < DAY)
            {
                label = zeropad(d.getHours(),2)+":"+
                    zeropad(d.getMinutes(),2); //+":"+d.getSeconds();
            }
            else if (this.maxX-this.minX < WEEK)
            {
                label = (d.getMonth()+1)+"/"+d.getDate();
                if (lastdate && lastdate.getDate() == d.getDate())
                    label = zeropad(d.getHours(),2)+":"+
                        zeropad(d.getMinutes(),2);
            }
            else if (this.maxX-this.minX < 20*WEEK)
            {
                label = (d.getMonth()+1)+"/"+d.getDate();
            }
            // XXX days, weeks, months and other time spans
            lastdate = d;
        }
        this.canvas.drawString(label,
                               dx - this.labelFontSz/2,
                               this.canvasdiv.offsetHeight-this.offsetB);
        lastlabel = label;
      }

      // Y axis
      var ticincrY = (this.maxY-this.minY)/(this.ticsY-1);
      if (ticincrY == 0) ticincrY = 1;
      ticstart = this.minY;
      // adjust tics by rounding
      ticincrY = Number(displaySigFigs(ticincrY, 3, -99, 0));
      if (ticincrY > 1) ticincrY = Math.round(ticincrY);
      ticstart = Number(displaySigFigs(ticstart, 3, -99, 0));
      this.LOG(2, "tics Y "+this.ticsY+" data range "+
               this.minY+" - "+this.maxY+" ticincr = "+ticincrY);
      for (var t = 0; t < this.ticsY; t++)
      {
        var y = ticstart + t * ticincrY;
        var dy = this.graph2canvasY(y);
        this.LOG(2, "tic mark on Y at "+y+" => "+dy);
        this.canvas.drawLine(this.offsetL, dy,
                             this.offsetL+this.ticLen, dy);
        this.canvas.drawString(y, 0, dy - this.labelFontSz/2);
      }
    };

    //----------------------------------------------------------------------
    // draw the axis if the data croses the origin
    //
    this.drawAxis = function()
    {
        if (! this.showAxis) return;
        this.canvas.setColor("#666666");
        if (this.minX < 0 && this.maxX > 0)
        {
            var origin = this.graph2canvasX(0);
            this.canvas.drawLine(origin, this.offsetT,
                                 origin, this.canvasdiv.offsetHeight-this.offsetB);
            // XXX tic code should be taken from the border code, once it
            // is stable
        }
        if (this.minY < 0 && this.maxY > 0)
        {
            var origin = this.graph2canvasY(0);
            this.canvas.drawLine(this.offsetL, origin,
                                 this.canvasdiv.offsetWidth-this.offsetR, origin);
            // XXX tic code should be taken from the border code, once it
            // is stable
        }
    };

    //----------------------------------------------------------------------
    this.drawGrid = function()
    {
        if (! this.showGrid) return;
        if (this.timeSeries)
        {
            if (this.maxX-this.minX < DAY)
            {
            }
            else if (this.maxX-this.minX < 20*WEEK)
            {
                // mark the weekends
                var d = new Date(this.minX*MSEC);
                d.setHours(0); d.setMinutes(0);
                d.setSeconds(0); d.setMilliseconds(0);
                // find next saturday
                var weekend = (d.getTime()/MSEC)+(6-d.getDay())*DAY;
                this.canvas.setColor("#eeeeee");
                while (weekend < this.maxX)
                {
                    var ws = this.graph2canvasX(weekend);
                    if (ws < this.offsetL) ws = this.offsetL;
                    var we = this.graph2canvasX(weekend+2*DAY);
                    if (we > this.canvasdiv.offsetWidth-this.offsetR)
                        we = this.canvasdiv.offsetWidth-this.offsetR;

                    this.canvas.fillRect(ws, this.offsetT,
                                         we-ws, this.canvasdiv.offsetHeight-this.offsetB-this.offsetT);
                    weekend += WEEK;
                }
            }
        }
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

        // figure out how much space we need for the labels
        this.canvas.setFont("sans-serif", this.labelFontSz+"px",Font.PLAIN);
        this.offsetL = String(Number(displaySigFigs(this.maxY, 3, -99, 0))).length*(this.labelFontSz*.75)+this.labelFontSz/2;

    };

    //----------------------------------------------------------------------
    // Convert between data scale and pixel location for both X and Y
    //
    this.graph2canvasX = function(x)
    {
        if (this.maxX==this.minX)
        {
            return Math.round(this.gWidth/2 + this.offsetL);
        }
        return Math.round(this.gWidth / (this.maxX-this.minX) *
                          (x - this.minX) + this.offsetL + 2);
    };
    this.graph2canvasY = function(y)
    {
        // only one data point
        if (this.maxY==this.minY)
        {
            return(this.gHeight / 2 + this.offsetT);
        }
        return Math.round(this.gHeight -
                          (this.gHeight / (this.maxY-this.minY)) *
                          (y - this.minY) + this.offsetT + 2);
    };

    //------------------------------------------------------------------------
    // Generate graph controls in a DIV and initialize
    //
    this.graphControls = function(myname, divname)
    {
        document.getElementById(divname).innerHTML =
        '<h3>Graph Controls</h3>\n'+
        '<input name="" onchange="'+myname+'.showAxis=this.checked; '+myname+'.plot();" id="showaxis" type="checkbox">Show Axis\n'+
        '<input name="" onchange="'+myname+'.plotPoints=this.checked; '+myname+'.plot();" id="plotpoints" type="checkbox">Plot Points\n'+
        '<input name="" onchange="'+myname+'.plotLines = this.checked; '+myname+'.plot();" id="plotlines" type="checkbox">Plot Lines\n'+
        '<input name="" onchange="'+myname+'.timeSeries=this.checked; '+myname+'.plot();" id="timeseries" type="checkbox">Time Series\n'+
        '<input name="" value="on" onchange="'+myname+'.stackGraph=this.checked; '+myname+'.plot();" id="stackgraph" type="checkbox">Stacked Area Graph\n'+
        '<h4>Graph Bounds</h4>\n'+
        'Top: <input name="" size="5" onchange="'+myname+'.maxYgraph=this.value; '+myname+'.plot();" id="maxy" type="text">\n'+
        'Bottom: <input name="" size="5" onchange="'+myname+'.minYgraph=this.value; '+myname+'.plot();" id="miny" type="text">\n'+
        'Left: <input name="" size="5" onchange="'+myname+'.minXgraph=this.value '+myname+'.plot();;" id="minx" type="text">\n'+
        'Right: <input name="" size="5" onchange="'+myname+'.maxXgraph=this.value; '+myname+'.plot();" id="maxx" type="text">\n';

        /*  Tics X: <input name="ticsx" type="text" size="5" onchange="jg.ticsX=this.value">
  Y: <input name="ticsy" type="text" size="5" onchange="jg.ticsY=this.value">
        */
        // now initialize the fields appropriately
        document.getElementById('showaxis').checked   = this.showAxis;
        document.getElementById('plotpoints').checked = this.plotPoints;
        document.getElementById('plotlines').checked  = this.plotLines;
        document.getElementById('timeseries').checked = this.timeSeries;
        document.getElementById('stackgraph').checked = this.stackGraph;
        document.getElementById('maxy').value = this.maxY;
        document.getElementById('maxx').value = this.maxX;
        document.getElementById('miny').value = this.minY;
        document.getElementById('minx').value = this.minX;
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
    }
	this.LOG = function(level, msg) {
      if (this.logdiv != undefined && level <= this.loglevel)
      {
          var now = new Date();
          var indent = "";
          for (var i = 1; i < level; i++) { indent += " "; };
          this.logdiv.innerHTML += "+"+
                                   (now.valueOf() - this.starttime.valueOf())+
                                   ":  "+indent+msg+"<br/>";
      }
	}
}
