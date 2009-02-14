var NO_OWNER = 1000;

function DGRegion(name, color_index) {
  this.name = name;
  this.owner = "";
  this.alliance = NO_OWNER;

  this.soldiers = [];
  this.soldier_type = 0;
  this.stroke_color = strokeColor[color_index];
  this.fill_color = fillColor[color_index];
  this.opacity = 0.2;
  this.polygon = new GPolygon(stateBorders[this.name], this.stroke_color, 3, 1, this.fill_color, this.opacity);

  GEvent.addListener(this.polygon, "click", function(point) {
    //polygon.setFillStyle({opacity:(polygon.unsavedStyle.fillOpacity || polygon.savedStyle.fillOpacity) + 0.3});
    //alert("click"); 
    //this.polygon.show();

    //map.openInfoWindowHtml(point, "<H1>" + username + "</H1><br><b>"+ name + "</b> point: " + point.lat() + "," + point.lng() + '<br>');
    attack_region(name);
  });
  this.polygon.hide();
}

DGRegion.prototype.refresh = function()    // Define Method
{
  //alert("refresh");
  if (this.polygon) {
    this.polygon.setFillStyle({color:this.fill_color, weight:1, opacity:this.opacity});
    this.polygon.setStrokeStyle({color:this.stroke_color, weight:3 });
    // draw Soldiers
    //var bounds = this.polygon.getBounds();
    //var center = bounds.getCenter();
  }
}

DGRegion.prototype.show = function()    // Define Method
{
  this.polygon.setFillStyle({color:this.fill_color, weight:1, opacity:this.opacity});
  this.polygon.setStrokeStyle({color:this.stroke_color, weight:3 });
  this.polygon.show();
}

var dgList = {
  'WA' : new DGRegion("WA", alliance),
  'OR' : new DGRegion("OR", alliance),
  'CA' : new DGRegion("CA", alliance),
  'ID' : new DGRegion("ID", alliance),
  'NV' : new DGRegion("NV", alliance),
  'MT' : new DGRegion("MT", alliance),
  'TX' : new DGRegion("TX", alliance),
  'ND' : new DGRegion("ND", alliance),
  'MN' : new DGRegion("MN", alliance),
  'SD' : new DGRegion("SD", alliance),
  'LA' : new DGRegion("LA", alliance),
  'AZ' : new DGRegion("AZ", alliance),
  'NM' : new DGRegion("NM", alliance),
  'CO' : new DGRegion("CO", alliance),
  'KS' : new DGRegion("KS", alliance),
  'NE' : new DGRegion("NE", alliance),
  'FL' : new DGRegion("FL", alliance),
  'MS' : new DGRegion("MS", alliance),
  'GA' : new DGRegion("GA", alliance),
  'SC' : new DGRegion("SC", alliance),
  'NC' : new DGRegion("NC", alliance),
  'VA' : new DGRegion("VA", alliance),
  'AL' : new DGRegion("AL", alliance),
  'OK' : new DGRegion("OK", alliance),
  'AR' : new DGRegion("AR", alliance),
  'MO' : new DGRegion("MO", alliance),
  'TN' : new DGRegion("TN", alliance),
  'UT' : new DGRegion("UT", alliance),
  'WY' : new DGRegion("WY", alliance),
  'IL' : new DGRegion("IL", alliance),
  'KY' : new DGRegion("KY", alliance),
  'IN' : new DGRegion("IN", alliance),
  'IA' : new DGRegion("IA", alliance),
  'WI' : new DGRegion("WI", alliance),
  'MI' : new DGRegion("MI", alliance),
  'OH' : new DGRegion("OH", alliance),
  'WV' : new DGRegion("WV", alliance),
  'MD' : new DGRegion("MD", alliance),
  'PA' : new DGRegion("PA", alliance),
  'NY' : new DGRegion("NY", alliance),
  'DE' : new DGRegion("DE", alliance),
  'NJ' : new DGRegion("NJ", alliance),
  'VT' : new DGRegion("VT", alliance),
  'NH' : new DGRegion("NH", alliance),
  'MA' : new DGRegion("MA", alliance),
  'CT' : new DGRegion("CT", alliance),
  'RI' : new DGRegion("RI", alliance),
  'ME' : new DGRegion("ME", alliance),
};

function removeSoldiers(region) {
  //remove all soldiers
  for (var i = 0; i < region.soldiers.length; i++) {
    var tmpMarker = region.soldiers[i];
    map.removeOverlay(tmpMarker);
  }
}

function drawSoldiers(region, alliance, soldiers) {
  var bounds = region.polygon.getBounds();
  var center = bounds.getCenter();
  var interval = 1.0;

  removeSoldiers(region);
  //redraw all soldiers..
  for (var i = 0; i < soldiers; i++) {
    var point = new GLatLng(center.lat(), center.lng() - interval * (soldiers / 2 - i));
    var soldier = createSoldier(point, 0, alliance);
    region.soldiers.push(soldier); 
    map.addOverlay(soldier);
  }
}

function remove_region(state_name) {
  //alert("remove_region: " + state_name);
  //sleep(50); 
  var region = dgList[state_name];
  region.alliance = -1;
  region.stroke_color = "#eeeeee";
  region.fill_color = "#ffffff";
  region.opacity = 0.0;
	
  removeSoldiers(region);
  region.refresh();
  
  region.polygon.hide();
}

function paint_region( state_name, alliance, soldiers) {
  //alert("paint_region");
  if(alliance == -1) {
    //alert("withdrawal: " + state_name);
    var region = dgList[state_name];
    region.alliance = -1;
    region.stroke_color = "#eeeeee";
    region.fill_color = "#ffffff";
    region.opacity = 0.0;

    removeSoldiers(region);
    region.refresh();
    region.polygon.hide();
  }
  else {
    var region = dgList[state_name];
    //region.polygon.hide();
    region.alliance = alliance;
    region.stroke_color = strokeColor[alliance];
    region.fill_color = fillColor[alliance];
    region.opacity = 0.2;
    
    map.removeOverlay(region.polygon); 
    region.polygon = new GPolygon(stateBorders[region.name], region.stroke_color, 3, 1, region.fill_color, region.opacity);
    GEvent.addListener(region.polygon, "click", function(point) {   attack_region(region.name);  });
	map.addOverlay(region.polygon);
	
    drawSoldiers(region, alliance, soldiers);
  }
}
