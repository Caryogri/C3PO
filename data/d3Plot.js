// !preview r2d3 data=jsonlite::toJSON(list(structure(list(Hallmark1 = structure(c(4L, 4L, 4L, 8L, 8L, 12L, 12L), levels = c("Sustaining Proliferative Signaling", "Deregulating Cellular Energetics", "Senescent cells", "Nonmutational Epigenetic Reprogramming", "Unlocking phenotypic plasticity", "Evading Growth Suppressors", "Avoiding Immune Destruction", "Enabling Replicative Immortality", "Tumour-Promoting Inflammation", "Activating Invasion and Metastasis", "Inducing Angiogenesis", "Genome Instability and Mutation", "Resisting Cell Death"), class = "factor"), Hallmark2 = structure(c(8L, 12L, 12L, 4L, 12L, 4L, 8L), levels = c("Sustaining Proliferative Signaling", "Deregulating Cellular Energetics", "Senescent cells", "Nonmutational Epigenetic Reprogramming", "Unlocking phenotypic plasticity", "Evading Growth Suppressors", "Avoiding Immune Destruction", "Enabling Replicative Immortality", "Tumour-Promoting Inflammation", "Activating Invasion and Metastasis", "Inducing Angiogenesis", "Genome Instability and Mutation", "Resisting Cell Death"), class = "factor"), Hallmark3 = structure(c(12L, 6L, 8L, 12L, 4L, 8L, 4L), levels = c("Sustaining Proliferative Signaling", "Deregulating Cellular Energetics", "Senescent cells", "Nonmutational Epigenetic Reprogramming", "Unlocking phenotypic plasticity", "Evading Growth Suppressors", "Avoiding Immune Destruction", "Enabling Replicative Immortality", "Tumour-Promoting Inflammation", "Activating Invasion and Metastasis", "Inducing Angiogenesis", "Genome Instability and Mutation", "Resisting Cell Death"), class = "factor"), Count = c(148, 2, 190, 47, 79, 467, 128)), row.names = c(NA, -7L), class = c("data.table", "data.frame"), sorted = c("Hallmark1", "Hallmark2", "Hallmark3")), structure(list(name = c("Sustaining Proliferative Signaling", "Deregulating Cellular Energetics", "Senescent cells", "Nonmutational Epigenetic Reprogramming", "Unlocking phenotypic plasticity", "Evading Growth Suppressors", "Avoiding Immune Destruction", "Enabling Replicative Immortality", "Tumour-Promoting Inflammation", "Activating Invasion and Metastasis", "Inducing Angiogenesis", "Genome Instability and Mutation", "Resisting Cell Death"), proportion = c(0, 0, 0, 1, 0, 0.00188501413760603, 0, 0.998114985862394, 0, 0, 0, 1, 0), size = c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1), connections = c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),  Path = c("https://i.ibb.co/Jq0KsMp/Proliferative-signaling-v1.png", "https://i.ibb.co/L1m51hf/Metabolism-v1.png", "https://i.ibb.co/CHxKFxr/Senescent-v1.png", "https://i.ibb.co/QC2wWWL/Epigenetic-v1.png", "https://i.ibb.co/Y0tssLS/Plasticity-v1.png", "https://i.ibb.co/mCDff9G/Suppressed-Growth-v1.png", "https://i.ibb.co/Sr1svfW/Immune-destruction-v1.png", "https://i.ibb.co/GJtBQZH/Immortality-v1.png", "https://i.ibb.co/KqfK1wT/Inflammation-v1.png", "https://i.ibb.co/Jn7Y4ht/Metastasis-v1.png", "https://i.ibb.co/nnDr8Pc/Angiogenesis-v1.png", "https://i.ibb.co/3mPncPR/Genome-integrity-v1.png", "https://i.ibb.co/8xbsTCy/Cell-death-v1.png")), class = c("data.table", "data.frame"), row.names = c(NA, -13L)))), d3_version = 4, elementId = "diagram"
//
// r2d3: https://rstudio.github.io/r2d3
//

function updateSVGString() {
  var serializer = new XMLSerializer();
  var source = serializer.serializeToString(svg.node());

  if(!source.match(/^<svg[^>]+xmlns="http\:\/\/www\.w3\.org\/2000\/svg"/)){
    source = source.replace(/^<svg/, '<svg xmlns="http://www.w3.org/2000/svg"');
  }
  if(!source.match(/^<svg[^>]+"http\:\/\/www\.w3\.org\/1999\/xlink"/)){
    source = source.replace(/^<svg/, '<svg xmlns:xlink="http://www.w3.org/1999/xlink"');
  }
  source = '<?xml version="1.0" standalone="no"?>\r\n' + source;

  Shiny.setInputValue("d3SVG", source, {priority: "event"});
}

svg.selectAll("*").remove();
d3.select(".tooltip").remove();

//"xlink:href"" is not strictly required and could just be entered as "href", however, it doesn't appear to break the svg and may be required for conversions.

var hallmarkList = data[1];
const mainData = data[0];

const rads = (2 * Math.PI) / (hallmarkList.length * 2);

var centerY;
var centerX;

const diameter = Math.min(width, height) * .8;
const outerRadius = diameter / 2;
const innerRadius = diameter / 3;
const radiusDifference = outerRadius - innerRadius;

const legendImageSize =  (diameter / hallmarkList.length) *.8;

const numRanked = Object.keys(mainData[0]).length - 1;

var horizontalStart;
var verticalStart;

var horizontalTravel;
var verticalTravel;

if (height > width) {
  centerX = width / 2;
  centerY = height - outerRadius;
  
  legendHorizontalTravel = 0;
  legendVerticalTravel = legendImageSize + 7;
  legendHorizontalStart = centerX-100;
  legendVerticalStart = 0;
} else {
  
  
  centerX = outerRadius;
  centerY = height / 2;
  
  legendHorizontalTravel = 0;
  legendVerticalTravel = legendImageSize + 7;
  legendHorizontalStart = (centerX + outerRadius + legendImageSize);
  legendVerticalStart = (height - hallmarkList.length * (legendImageSize + 7)) / 2;
  
lImages = svg.selectAll("legendImages")
    .data(hallmarkList)
    .enter()
    .append("image")
       .attr("xlink:href", function(d, i) {return d.Path;})
       .attr("x", function(d, i) {return legendHorizontalStart + legendHorizontalTravel * i;})
       .attr("y", function(d, i) {return legendVerticalStart + legendVerticalTravel * i;})
       .attr("height", legendImageSize)
       .attr("width", legendImageSize);

Math.max(...(hallmarkList.map(el => el.length)));

lText = svg.selectAll("legendText")
    .data(hallmarkList)
    .enter()
    .append("text")
      .text(function(d){return d.name;})
      .attr("x", function(d, i) {return legendHorizontalStart + legendImageSize + 5 + legendHorizontalTravel * i;})
      .attr("y", function(d, i) {return legendVerticalStart + legendImageSize * 1/2 + legendVerticalTravel * i;})
      .attr("text-anchor", "left")
      .style("alignment-baseline", "middle")
      .style("font", legendImageSize * 1/2 + "px sans-serif");
      
      //console.log(lText.node().getComputedTextLength());
}

var g = svg.append("g").attr("transform", "translate(" + centerX + "," + centerY + ")");

var tooltip = d3.select(".tab-pane") //<- This right here officer
  .append("div")
  .attr("class", "tooltip")
  .style("position", "absolute")
  .style('background-color', 'rgba(255,255,255,0.8)')
  .style('border-radius', '5px')
  .style('padding', '5px')
  .style("opacity", 0)
  .style("font-family", "Tahoma, Geneva, sans-serif")
  .style("font-size", "12pt");
  
  
var hallmarkPie = d3.pie()
  .value(function(d){return d.size;})
  .sort(null);

var hallmarkArc = d3.arc()
  .innerRadius(innerRadius)
  .outerRadius(outerRadius)
  .padAngle(0.01);

var hallmarkSlices = g.selectAll("arc")
  .data(hallmarkPie(hallmarkList))
  .enter()
  .append("g")
  .attr("class", "arc");

hallmarkSlices.append("path")
  .attr("fill", "#b3b5b3")
  .attr("id", function(d, i) {return hallmarkList[i].name + "-whole";})
  .attr("d", hallmarkArc)
  .on("mouseover", function(d) {
    
    tooltip.style("opacity", 1)
      .style('box-shadow', '5px 5px 5px rgba(0,0,0,0.2)');;	
    })
  .on("mouseleave", function(d) {
            tooltip.style("opacity", 0);	
  })
  .on("mousemove", function(d) {
    tooltip.html("<b>" + d.data.name + "</b><br>Present in " + (d.data.proportion * 100).toFixed(2) + "% of samples.")
        .style("left",(d3.mouse(this)[0] + centerX + 35) + "px")
        .style("top", (d3.mouse(this)[1] + centerY + 35) + "px");
  });

hallmarkSlices.append("path")
  .attr("fill", "#7e9cd6")
  .attr("d", function(d, i) {return hallmarkArc.outerRadius(innerRadius + radiusDifference * Math.sqrt(hallmarkList[i].proportion))(d, i);})
  .attr("id", function(d, i) {return hallmarkList[i].name + "-proportion";})
  //.attr("id", function(d, i) {return "BOLD1" + hallmarkList[i].name + "BOLD2:Present_in_" + (hallmarkList[i].proportion * 100).toFixed(2) + "percent_of_samples."}) Here lies my janky solution, which has been made obsolete by rolling back to d3v4. Never forget.
  .on("mouseover", function(d) {		
    tooltip.style("opacity", 1)
      .style('box-shadow', '5px 5px 5px rgba(0,0,0,0.2)');;	
    })
  .on("mouseleave", function(d) {
            tooltip.style("opacity", 0)
              .style("left, 0px")
              .style("top, 0px");	
  })
  .on("mousemove", function(d) {
    tooltip.html("<b>" + d.data.name + "</b><br>Present in " + (d.data.proportion * 100).toFixed(2) + "% of samples.")
        .style("left", (d3.mouse(this)[0] + centerX + 35) + "px")
        .style("top", (d3.mouse(this)[1] + centerY + 35) + "px");
  });

hallmarkSlices.append("image")
  .attr("xlink:href", function(d, i) {return d.data.Path;})
  .attr("width", radiusDifference / 2)
  .attr("height", radiusDifference / 2)
  .attr("x", function(d, i) {return d3.pointRadial((2*i+1) * rads, innerRadius + radiusDifference / 2)[0] - radiusDifference * .25;})
  .attr("y", function(d, i) {return d3.pointRadial((2*i+1) * rads, innerRadius + radiusDifference / 2)[1] - radiusDifference * .25;})
  .on("mouseover", function(d) {		
    tooltip.style("opacity", 1)
      .style('box-shadow', '5px 5px 5px rgba(0,0,0,0.2)');;	
    })
  .on("mouseleave", function(d) {
            tooltip.style("opacity", 0);	
  })
  .on("mousemove", function(d) {
    tooltip.html("<b>" + d.data.name + "</b><br>Present in " + (d.data.proportion * 100).toFixed(2) + "% of samples.")
        .style("left", (d3.mouse(this)[0] + centerX + 35) + "px")
        .style("top", (d3.mouse(this)[1] + centerY + 35) + "px");
  });

var pathDescriptions = {};
var pathHallmarks = {};
var corrections;
var currentSelected;

for (y = 0; y < mainData.length; y++) {  
  var log = ""
  var sampleSet = mainData[y];
  var newPath = d3.path();
  var startingCoords = null;
  var tooltipText = "";
  
  for (x = 1; x <= numRanked; x++) {
    
    var rank = "Hallmark" + x;
    
    tooltipText = tooltipText + "<b>Hallmark " + x + ":</b> " + sampleSet[rank] + "<br>";
    
    var hallmarkIndex = hallmarkList.findIndex(arr => arr.name === sampleSet[rank]);
    
    if (hallmarkList[hallmarkIndex].connections % 2 == 0) {
      corrections = hallmarkList[hallmarkIndex].connections / -2;
    } else {
      corrections = (hallmarkList[hallmarkIndex].connections + 1) / 2;
    }
    
    var hallmarkRads = rads*(hallmarkIndex*2 + 1) + corrections * rads * 1.5 / mainData.length;
    var hallmarkCoords = d3.pointRadial(hallmarkRads, innerRadius);
    
    hallmarkList[hallmarkIndex].connections++;
    
    if (x == 1) {
      newPath.moveTo(hallmarkCoords[0] + centerX, hallmarkCoords[1] + centerY);
      startingCoords = hallmarkCoords;
    } else {
      newPath.quadraticCurveTo(centerX, centerY, hallmarkCoords[0] + centerX, hallmarkCoords[1] + centerY);
    }
  }
  
  newPath.quadraticCurveTo(centerX, centerY, startingCoords[0] + centerX, startingCoords[1] + centerY);
  
  tooltipText = tooltipText + "<br>" + "<b>Number of Samples:</b> " + sampleSet["Count"];
  var id = "path" + y;
  pathDescriptions = Object.defineProperty(pathDescriptions, id, {value: tooltipText, enumerable: true, writeable: true});
  pathHallmarks = Object.defineProperty(pathHallmarks, id, {value: sampleSet, enumerable: true, writeable: true})
  
  svg.append("path")
  .attr("d", newPath)
  .attr("stroke", "black")
  .attr("fill", "none")
  .attr("id", id)
  .on("mouseover", function(d) {
    d3.select(this).attr("stroke-width", "2");
    tooltip.style("opacity", 1)
      .style('box-shadow', '5px 5px 5px rgba(0,0,0,0.2)');	
    })
  .on("mouseleave", function(d) {
      d3.select(this).attr("stroke-width", "1");
      tooltip.style("opacity", 0)
        .style("top", "0px")
        .style("left", "0px");	
  })
  .on("mousemove", function(d) {
    tooltip.html(pathDescriptions[this.id])
        .style("left", (d3.mouse(this)[0] + 35) + "px")
        .style("top", (d3.mouse(this)[1] + 35) + "px");
  })
  .on("click", function() {
    if (currentSelected != this) {
      d3.select(currentSelected).attr("stroke", "black");
      d3.select(this).attr("stroke", "red");
      currentSelected = this;
      updateSVGString();
    }
    
    Shiny.setInputValue("selectedPathData", pathHallmarks[this.id], {priority: "event"});
  });
}

for (c = 0; c < hallmarkList.length; c++) {
  hallmarkList[c].connections = 0;
}

updateSVGString();