// Note: This example requires that you consent to location sharing when
// prompted by your browser. If you see the error "The Geolocation service
// failed.", it means you probably did not give permission for the browser to
// locate you.
var polies = [];
var id = 1;
var drawingMode;
var map;
var drawingManager;
var place;
var candidate;

function initMap() {
    var london = {lat: 51.5055, lng: 0.0754};
    map = new google.maps.Map(document.getElementById('map'), {
        center: london,
        zoom: 17
    });

    function reqListener(){
        var obj = JSON.parse(this.responseText);
        console.log(obj);
        var i = 0;
        //console.log(obj[0].places[0]);
        while(obj[i] != null){
            var id = obj[i].places[0].id;
            console.log(id);
            var topLeft = {lat: obj[i].places[0].top_left[0], lng: obj[i].places[0].top_left[1]};
            var topRight = {lat: obj[i].places[0].top_right[0], lng: obj[i].places[0].top_right[1]};
            var bottomLeft = {lat: obj[i].places[0].bottom_left[0], lng: obj[i].places[0].bottom_left[1]};
            var bottomRight = {lat: obj[i].places[0].bottom_right[0], lng: obj[i].places[0].bottom_right[1]};

            var polyCoord = [topLeft, topRight, bottomRight, bottomLeft, topLeft];

            var polyCoords = [
                {lat: -1.51611, lng:51.3512},
                {lat: -1.7358, lng: 50.999},
                {lat: -0.9008, lng: 51.117},
                {lat: -1.5161, lng: 51.3512}
            ];
            var poly = new google.maps.Polygon({
                paths: polyCoord,
                strokeColor: '#FF0000',
                strokeOpacity: 0.8,
                strokeWeight: 2,
                fillColor: '#FF0000',
                fillOpacity: 0.35,
                clickable: true,
                zIndex: id
            });
            console.log("index");
            //console.log(poly.zIndex);

            polies.push(poly);
            //console.log(polies.length);
            poly.setMap(map);
            console.log("here");
            i = i + 1;
        }
    }

    var req = new XMLHttpRequest();
    req.addEventListener("load", reqListener);
    var user = localStorage.getItem('user');
    req.open('GET', "https://tracks-api.herokuapp.com/songs");
    req.setRequestHeader('Authorization', user);
    req.setRequestHeader('Content-Type', 'application/json');

    req.send(null);


    //map.data.loadGeoJson('http://geojson.io/#data=data:application/json,{"type":"LineString","coordinates":[[0,0],[10,10]]}&id=gist:anonymous/a02bf5787ac29f44afbe82fec615ade7&map=14/51.5239/-0.1086');

    var triangleCoords = [
        {lat: 25.774, lng: -80.190},
        {lat: 18.466, lng: -66.118},
        {lat: 32.321, lng: -64.757},
        {lat: 25.774, lng: -80.190}
    ];

    var bermudaTriangle = new google.maps.Polygon({
        paths: triangleCoords,
        strokeColor: '#FF0000',
        strokeOpacity: 0.8,
        strokeWeight: 2,
        fillColor: '#FF0000',
        fillOpacity: 0.35
    });
    // bermudaTriangle.setMap(map);

    drawingManager = new google.maps.drawing.DrawingManager({
        drawingMode: google.maps.drawing.OverlayType.NULL,
        drawingControl: false,
        drawingControlOptions: {
            position: google.maps.ControlPosition.TOP_CENTER,
            drawingModes: ['polygon']
        },

        polygonOptions: {
            //fillColor: '#888800',
            strokeColor: '#888800',
            strokeOpacity: 1.0,
            fillOpacity: 0.5,
            strokeWeight: 3,
            clickable: true
        }
    });
    drawingManager.setMap(map);


    google.maps.event.addListener(drawingManager, 'polygoncomplete', function(polygon) {
        google.maps.event.addListener(polygon, 'click', function(event) {
            console.log("clicked");
        });
        if (submitted == false) {
            if (candidate != null) {
                candidate.setMap(null);
            }
        }

        console.log("polygon complete");
        var paths = polygon.getPaths();
        var topLeft;
        var topRight;
        var bottomLeft;
        var bottomRight;
        //console.log(paths.getAt(0).lat());
        if(paths.getAt(0).length !=4){
            alert("The area must consist of four corners");
            polygon.setMap(null);
        }else{
            id = id + 1;
            console.log(id);
            for(var i = 0; i < 4; i++){
                //console.log(paths.getAt(0).length);
                //console.log(paths.getAt(0).getAt(i).lat());
                if(i == 0){
                    topLeft = {lat: paths.getAt(0).getAt(i).lat(), lng: paths.getAt(0).getAt(i).lng()};
                }else if(i == 1){
                    topRight = {lat: paths.getAt(0).getAt(i).lat(), lng: paths.getAt(0).getAt(i).lng()};
                }else if(i == 2){
                    bottomRight = {lat: paths.getAt(0).getAt(i).lat(), lng: paths.getAt(0).getAt(i).lng()};
                }else{
                    bottomLeft = {lat: paths.getAt(0).getAt(i).lat(), lng: paths.getAt(0).getAt(i).lng()};
                }
            }
            //console.log(topLeft.lat);
            candidate = polygon;

            place = {
                "top_left": [topLeft.lat, topLeft.lng],
                    "top_right": [topRight.lat, topRight.lng],
                    "bottom_right": [bottomRight.lat, bottomRight.lng],
                    "bottom_left": [bottomLeft.lat, bottomLeft.lng]
            }
        }

    });


    // Try HTML5 geolocation.
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(function(position) {
            var pos = {
                lat: position.coords.latitude,
                lng: position.coords.longitude
            };

            var marker = new google.maps.Marker({
                position: pos,
                map: map
            });

            map.setCenter(pos);
        }, function() {
            handleLocationError(true, infoWindow, map.getCenter());
        });
    } else {
        // Browser doesn't support Geolocation
        handleLocationError(false, infoWindow, map.getCenter());
    }
}

function changeMode(mode) {
    if (mode === "point") {
        drawingMode = google.maps.drawing.OverlayType.NULL;

    } else {
        drawingMode = google.maps.drawing.OverlayType.POLYGON;
    }
    drawingManager.setOptions({
        drawingMode: drawingMode
    });
}

function handleLocationError(browserHasGeolocation, infoWindow, pos) {
    infoWindow.setPosition(pos);
    infoWindow.setContent(browserHasGeolocation ?
        'Error: The Geolocation service failed.' :
        'Error: Your browser doesn\'t support geolocation.');
}