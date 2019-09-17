var processNarrativeLocation = {
 init: function() {
      this.bindEventHandlers();     
  },
  bindEventHandlers: function() {
    $('a[data-map]').click(function(event) {
      var e = $(this);
      event.preventDefault();
      var narrativeLocation = e.attr("label");
      var fastURI = e.attr("fastURI");
      var bbox = e.attr("bbox");
      var lat = e.attr("lat");
      var lon = e.attr("lon");
      //if old popover exists, get rid of it
      e.popover("destroy");
      var contentHtml = "<div id='narrativeLocationPopover' class='kp-content'>" + narrativeLocation + ": " + fastURI +
      "<div id='subjectNarrativeFacet' fastURI='" + fastURI + "'></div>" + 
      "<div id='dbPediaInfo'></div>" + 
      "<div id='narrativeLocationMap' style='height:200px;width:200px'></div>";
      //,trigger : 'focus'
      e.popover({
        content : contentHtml,
        html : true,
        trigger: 'click'
      }).popover('show');
      if(bbox || (lat && lon)) {
        processNarrativeLocation.generateMap(bbox, lat, lon);
      }
      processNarrativeLocation.getFASTInfo(fastURI);
    });
  },
  generateMap: function(bbox, lat, lon) {
    
    var overlay = L.layerGroup();
    var mymap = L.map("narrativeLocationMap");
    L.tileLayer(
        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{retina}.png', {
          attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://carto.com/attributions">Carto</a>',
          maxZoom: 18,
          worldCopyJump: true,
          retina: '@2x',
          detectRetina: false
        }
      ).addTo(mymap);
    mymap.addLayer(overlay);

    if(bbox) {
      var bboxBounds = L.bboxToBounds(bbox);
      mymap.fitBounds(bboxBounds);
      addBoundsOverlay(overlay, bboxBounds);
    } else {
      mymap.setView([lat,lon], 10);
      addPointOverlay(overlay, lat, lon);
    }
  },
  //Based on wikidata info returned, parse the coordinate info accordingly
  generateCoordinateInfo: function(binding) {
    var geoInfo = {};
    if("clon" in binding && "clat" in binding && "value" in binding["clon"] && "value" in binding["clat"]) {
      geoInfo["Point"] = {"lon": binding["clon"]["value"], "lat": binding["clat"]["value"]};
    }
    if("wlon" in binding && "slat" in binding && "elon" in binding && "nlat" in binding &&
        "value" in binding["wlon"] && "value" in binding["slat"] && "value" in binding["elon"] && "value" in binding["nlat"]) {
      geoInfo["bbox"] = binding["wlon"]["value"] + " " + binding["slat"]["value"] + " " + binding["elon"]["value"] + " " + binding["nlat"]["value"];
    }
    return geoInfo;
  },
  getFASTInfo: function(fastURI) {
    var lookupURL = "https://lookup.ld4l.org/authorities/show/linked_data/oclcfast_direct/" + fastURI;
    var subjectHtml = "";
    $.ajax({
      url: lookupURL,
      type:'GET',
      dataType:'json',
      success:function(data) {
        if("label" in data && data["label"].length) {
          var label = data["label"][0];
          label = label.replace(/--/g, " > ") 
          //Replace -- from FAST with > for our catalog
          subjectHtml =  "<a title='Search Library Catalog' href='/?f[fast_geo_facet][]=" + label + "'>" + label + "</a>" ;
          $("#subjectNarrativeFacet").append(subjectHtml);
        }
      }
    })
  }
  
};  

L.bboxToBounds = function(bbox) {
  bbox = bbox.split(' ');
  if (bbox.length === 4) {
    return L.latLngBounds([[bbox[1], bbox[0]], [bbox[3], bbox[2]]]);
  } else {
    throw "Invalid bounding box string";
  }
};

addBoundsOverlay = function(overlay, bounds) {
    if (bounds instanceof L.LatLngBounds) {
      overlay.addLayer(L.polygon([
        bounds.getSouthWest(),
        bounds.getSouthEast(),
        bounds.getNorthEast(),
        bounds.getNorthWest()
      ]));
    }
};

//lat and lon are strings
addPointOverlay = function(overlay, lat, lon) {
  if(lat && lon) {
    overlay.addLayer(L.marker([lat, lon]));
  }
}