var map, mgr;
var bounds,southWest,northEast,lngSpan, latSpan, center,pointSW,pointNE;
var soldiers = new Array();
var geocoder;
var strokeColor = ["#f33f00", "#006600", "#3f00f3"];
var fillColor = ["#ff0000", "#008800", "#0000ff"];
var colorIndex = 0;
var tempStateName = "";

function setupMap() {
  if (GBrowserIsCompatible()) {
    var pointCenter = new GLatLng(40, -95);
    map = new GMap2(document.getElementById("map"));
    map.addControl(new GLargeMapControl());
    //map.addControl(new GSmallMapControl());
    map.addControl(new GMapTypeControl());
    map.setCenter(pointCenter, 4);

    geocoder = new GClientGeocoder();

    // Layers ..
    //        var myLayer = new GLayer("org.wikipedia.en");
    //        map.addOverlay(myLayer);

    bounds = map.getBounds();
    southWest = bounds.getSouthWest();
    northEast = bounds.getNorthEast();
    lngSpan = northEast.lng() - southWest.lng();
    latSpan = northEast.lat() - southWest.lat();
    center = map.getCenter();

    pointSW = new GLatLng(24.257041, -127.089844);
    pointNE = new GLatLng(50.34351, -65.390625);

    //window.setTimeout(setupSoldierMarkers, 0);


  }
}

// Creates a marker
function createSoldier(point, index, type) {
  var soldierIcon = new GIcon(G_DEFAULT_ICON);
  var aspiraIcon = new GIcon(G_DEFAULT_ICON);
  var eliteIcon = new GIcon(G_DEFAULT_ICON);
  var gasIcon = new GIcon(G_DEFAULT_ICON);

  soldierIcon.image = "/images/SniperSoldier.png";
  aspiraIcon.image = "/images/AspiraSoldier.png";
  eliteIcon.image = "/images/Elite.png";
  gasIcon.image = "/images/GasSoldier.png";

  markerOptions = { icon:soldierIcon, draggable: true };
  if (type == 0)
    markerOptions = { icon:soldierIcon, draggable: true };
  else if (type == 1)
    markerOptions = { icon:aspiraIcon, draggable: true };
  else if (type == 2)
        markerOptions = { icon:gasIcon, draggable: true };
  else if (type == 3)
      markerOptions = { icon:eliteIcon, draggable: true };



  var marker = new GMarker(point, markerOptions);

  GEvent.addListener(marker, "click", function() {
    marker.openInfoWindowHtml("Marker <b> Click </b>");
    self.setTimeout('map.closeInfoWindow()', 3000);
  });

  GEvent.addListener(marker, "dragstart", function() {
    map.closeInfoWindow();
  });

  GEvent.addListener(marker, "dragend", function() {
    var tmplatlng = marker.getLatLng();
    var tmpHtml = "<br>Just bouncing here <br>Latitude:" + tmplatlng.lat() + "<br>Longitude:" + tmplatlng.lng();
    marker.openInfoWindowHtml(tmpHtml);
    setTimeout("map.closeInfoWindow();", 3000);
  });

  return marker;
}

function createPolygon(stateCode, icolor) {
  var polygon = new GPolygon(stateBorders[stateCode], strokeColor[icolor], 3, 1, fillColor[icolor], 0.2);

  //      polygon.enableEditing({onEvent: "mouseover"});
  //      polygon.disableEditing({onEvent: "mouseout"});

  GEvent.addListener(polygon, "click", function(point) {
    //polygon.setFillStyle({opacity:(polygon.unsavedStyle.fillOpacity || polygon.savedStyle.fillOpacity) + 0.3});
    map.openInfoWindowHtml(point, '<b>latlng:</b>' + point.lat() + "," + point.lng() + '<br>');
  });

  //  GEvent.addListener(polygon, "mouseover", function() {
  //    //alert("mouseover");
  //    //polygon.setFillStyle({opacity:(polygon.unsavedStyle.fillOpacity || polygon.savedStyle.fillOpacity) + 0.3});
  //    this.setFillStyle({  color: color,  weight: 3, opacity: 0.0  });
  //  });
  //
  //  GEvent.addListener(polygon, "mouseout", function() {
  //    this.setFillStyle({  color: color,  weight: 3, opacity: 0.2  });
  //    //polygon.setFillStyle({opacity:(polygon.unsavedStyle.fillOpacity || polygon.savedStyle.fillOpacity)});
  //  });

  return polygon;
}

// ToDo.. Get XML file from the server and put to array
function getSoldierMarkers(n) {
  var batch = [];
  for (var i = 0; i < n; ++i) {
    var point = new GLatLng(southWest.lat() + latSpan / 4 + latSpan / 2 * Math.random(),
        southWest.lng() + lngSpan / 4 + lngSpan / 2 * Math.random());
    var type = i % 4;
    soldiers.push(point);
    batch.push(createSoldier(point, i, type));
  }
  return batch;
}

// refresh marker..
function setupSoldierMarkers() {
  mgr = new MarkerManager(map);
  mgr.addMarkers(getSoldierMarkers(20), 3);
  mgr.addMarkers(getSoldierMarkers(100), 6);
  mgr.addMarkers(getSoldierMarkers(500), 8);
  mgr.refresh();
}

function getAddress(overlay, latlng) {
  if (latlng != null) {
    address = latlng;
    geocoder.getLocations(latlng, showReverseAddress);
  }
}

function getStateName(response) {
  if (!response || response.Status.code != 200) {
    alert("Status Code:" + response.Status.code);
    tempStateName ="";
  } else {
    place = response.Placemark[0];
    var stateCode = place.AddressDetails.Country.AdministrativeArea.AdministrativeAreaName;
    stateCode = stateCode.toUpperCase();
    tempStateName = stateCode;
  }
}

function drawState(response) {
  if (!response || response.Status.code != 200) {
    alert("Status Code:" + response.Status.code);
  } else {
    place = response.Placemark[0];
    var stateCode = place.AddressDetails.Country.AdministrativeArea.AdministrativeAreaName;
    stateCode = stateCode.toUpperCase();

    point = new GLatLng(place.Point.coordinates[1], place.Point.coordinates[0]);
    map.openInfoWindowHtml(point,
        '<b>latlng:</b>' + place.Point.coordinates[1] + "," + place.Point.coordinates[0] + '<br>' +
        '<b>Address:</b>' + place.address + '<br>' +
        '<b>State:</b>' + stateCode + '<br>' +
        '<b>Country code:</b> ' + place.AddressDetails.Country.CountryNameCode);
    setTimeout("map.closeInfoWindow();", 3000);

    var icolor = colorIndex++ % 2;
    //var polygon = new GPolygon(stateBorders[stateCode],strokeColor[0], 3, 1, fillColor[0], 0.2);
    var polygon = createPolygon(stateCode, icolor);
    map.addOverlay(polygon);
  }
}

function showReverseAddress(response) {
  //map.clearOverlays();
  if (!response || response.Status.code != 200) {
    alert("Status Code:" + response.Status.code);
  } else {
    place = response.Placemark[0];
    var stateCode = place.AddressDetails.Country.AdministrativeArea.AdministrativeAreaName;
    stateCode = stateCode.toUpperCase();

    point = new GLatLng(place.Point.coordinates[1], place.Point.coordinates[0]);
    //var marker = new GMarker(point);
    //var marker = new createSoldier(point,0,0);
    //map.addOverlay(marker);

    //marker.openInfoWindowHtml(
    map.openInfoWindowHtml(point,
      //'<b>orig latlng:</b>' + response.name + '<br/>' +
        '<b>latlng:</b>' + place.Point.coordinates[1] + "," + place.Point.coordinates[0] + '<br>' +
          //'<b>Status Code:</b>' + response.Status.code + '<br>' +
          //'<b>Status Request:</b>' + response.Status.request + '<br>' +
        '<b>Address:</b>' + place.address + '<br>' +
        '<b>State:</b>' + stateCode + '<br>' +
          //'<b>Accuracy:</b>' + place.AddressDetails.Accuracy + '<br>' +
        '<b>Country code:</b> ' + place.AddressDetails.Country.CountryNameCode);
    setTimeout("map.closeInfoWindow();", 3000);

    // draw .. Polygon..
    //var polygon = new GPolygon(stateBorders[stateCode], strokeColor[2], 3, 1, fillColor[2], 0.2);
    var polygon = createPolygon(stateCode, 2);
    map.addOverlay(polygon);
  }
}

function showAddress(address) {
  if (geocoder) {
    geocoder.getLatLng(address,
        function(point) {
          if (!point) {
            alert(address + " not found");
          } else {
            map.setCenter(point, 13);
            var marker = new createSoldier(point, 0, 0);
            //var marker = new GMarker(point);
            map.addOverlay(marker);
            marker.openInfoWindowHtml(address);
          }
        });
  }
}

function ClearOverlay() {
  map.clearOverlays();
}

function onLoad()
{
  setupMap();
  //setupSoldierMarkers();

  /*
   for (var i = 0; i < 5; i++) {
   var point = new GLatLng(southWest.lat() + latSpan * Math.random(), southWest.lng() + lngSpan * Math.random());
   map.addOverlay(createSoldier(point, i));
   }
   */

  // InfoWindow..
  //map.openInfoWindow(center, document.createTextNode("Hello, DGame User"));

  //var str = "";

  for (var i = 0; i < 48; i++) {
    var state = stateName[i];
    var polygon = dgList[state].polygon;
    map.addOverlay(polygon);
    //alert(state);
  }
  //alert(str);

  GEvent.addListener(map, "click", function(overlay, latlng) {
    if (latlng) {
      //getAddress(overlay, latlng);

      //address = latlng;
      //geocoder.getLocations(latlng, drawState);

      var minDistance = 1000000000;
      var minState = "";
      for (var i = 0; i < 48; i++) {
        var state = stateName[i];
        var region = dgList[state];
        var polygon = region.polygon;
        var bounds = polygon.getBounds();
        if (bounds.containsLatLng(latlng)) {
          //alert(state);
          var center = bounds.getCenter();
          var distance = center.distanceFrom(latlng);
          if(minDistance > distance) {
            minDistance = distance;
            minState = state;
          }
        }
      }
      
      //alert("MinState: " + minState);
//      var region = dgList[minState];
//      region.stroke_color = strokeColor[0];
//      region.fill_color = fillColor[0];
//      region.opacity = 0.2;
//      region.refresh();
//      region.show();


      expand(minState); 


//      geocoder.getLocations(latlng, getStateName);
//      if(tempStateName != "") {
//        var region = dgList[tempStateName];
//        region.show();
//        region.refresh();
//        //var polygon = dgList[tempStateName].polygon;
//
//      }


      //          var myHtml = "<br>The GPoint value is: " + map.fromLatLngToDivPixel(latlng) + " at zoom level " + map.getZoom();
      //          myHtml += "<br>Latitude:" + latlng.lat() + "<br>Longitude:" + latlng.lng();
      //          map.openInfoWindow(latlng, myHtml);

      //Polygons
      //          var lat = latlng.lat();
      //          var lon = latlng.lng();
      //          var latOffset = 2.0;
      //          var lonOffset = 3.0;
      //          var polygon = new GPolygon([
      //            new GLatLng(lat - latOffset, lon - lonOffset),
      //            new GLatLng(lat - latOffset, lon + lonOffset),
      //            new GLatLng(lat + latOffset, lon + lonOffset),
      //            new GLatLng(lat + latOffset, lon - lonOffset),
      //            new GLatLng(lat - latOffset, lon - lonOffset)
      //          ], "#f33f00", 5, 1, "#ff0000", 0.2);
      //          map.addOverlay(polygon);
    }
  });

  GEvent.addListener(map, 'singlerightclick', function(pixel, url, obj) {
    var latlng = map.fromContainerPixelToLatLng(pixel);

    if (latlng) {
      //getAddress(null, latlng);

      var minDistance = 1000000000;
      var minState = "";
      for (var i = 0; i < 48; i++) {
        var state = stateName[i];
        var region = dgList[state];
        var polygon = region.polygon;
        var bounds = polygon.getBounds();
        if (bounds.containsLatLng(latlng)) {
          //alert(state);
          var center = bounds.getCenter();
          var distance = center.distanceFrom(latlng);
          if(minDistance > distance) {
            minDistance = distance;
            minState = state;
          }
        }
      }

      //alert("MinState: " + minState);
      var region = dgList[minState];
      region.stroke_color = strokeColor[2];
      region.fill_color = fillColor[2];
      region.opacity = 0.2;
      region.refresh();
      region.show();

      //Converting Projection Coordinates
      //          var tileCoordinate = new GPoint();
      //          var tilePoint = new GPoint();
      //          var currentProjection = G_NORMAL_MAP.getProjection();
      //          tilePoint = currentProjection.fromLatLngToPixel(latlng, map.getZoom());
      //          tileCoordinate.x = Math.floor(tilePoint.x / 256);
      //          tileCoordinate.y = Math.floor(tilePoint.y / 256);
      //          var myHtml = "Latitude: " + latlng.lat() + "<br/>Longitude: " + latlng.lng() +
      //            "<br/>The Tile Coordinate is:<br/> x: " + tileCoordinate.x +
      //            "<br/> y: " + tileCoordinate.y + "<br/> at zoom level " + map.getZoom();
      //          map.openInfoWindow(latlng, myHtml);

      //          var boundaries = new GLatLngBounds(
      //              new GLatLng(lat - latOffset, lon - lonOffset),
      //              new GLatLng(lat + latOffset, lon + lonOffset));
      //          var oldmap = new GGroundOverlay("http://www.lib.utexas.edu/maps/historical/newark_nj_1922.jpg", boundaries);
      //          map.addOverlay(oldmap);
    }
  });


  

  GEvent.addListener(map, "middleclick", function(p) {
    alert("Middle!");
  });

  //var point1 = soldiers[1];
  //alert(soldiers[1]);
  var polyOptions = {geodesic:true};
  var polyline = new GPolyline([soldiers[3], soldiers[7]], "#ff0000", 10/*, 1, polyOptions*/);
  map.addOverlay(polyline);






  /*
   GEvent.addListener(map, "moveend", function() {
   var center = map.getCenter();
   document.getElementById("message").innerHTML = center.toString();
   });
   */

  //var groundOverlay = new GGroundOverlay("images/us_counties.png", new GLatLngBounds(pointSW, pointNE)) ;
  //map.addOverlay(groundOverlay);
}
