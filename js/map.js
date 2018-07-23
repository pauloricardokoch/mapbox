mapboxgl.accessToken = 'pk.eyJ1IjoicGF1bG9yaWNhcmRva29jaCIsImEiOiJjampyaWdnZ3QwMDBhM2tvMGdvOGhlNmg4In0.RoTIYl025qE3exFMMxJX5g';

var map;
window.addEventListener(
    'DOMContentLoaded',
    function () {
        map = new mapboxgl.Map({
            container: 'map',
            style: 'mapbox://styles/mapbox/light-v9',
            zoom: 6,
            center: [-52.406672, -28.26278],
            pitch: 45,
            maxZoom: 9,
            minZoom: 5
        });

        map.on('load', function () {
            // add data
            map.addSource('trees', {
                type: 'geojson',
                data: 'json/tp2m/2017082200.geojson?f=' + Math.random(),
                buffer: 0
            });


            // add heatmap layer here
            map.addLayer({
                id: 'trees-heat',
                type: 'heatmap',
                source: 'trees',
                maxzoom: 20,
                paint: {
                    // increase weight as diameter breast height increases
                    'heatmap-weight': {
                        property: 'dbh',
                        type: 'exponential',
                        stops: [
                            [{ zoom: 0, value: 0 }, 0],
                            [{ zoom: 0, value: 10 }, 0.25],
                            [{ zoom: 0, value: 15 }, 0.75],
                            [{ zoom: 0, value: 25 }, 0.85],
                            [{ zoom: 0, value: 30 }, 1]
                        ]
                    },
                    // increase intensity as zoom level increases
                    'heatmap-intensity': {
                        stops: [
                            [5, 0.45],
                            [6, 0.45],
                            [7, 0.8],
                            [8, 0.8],
                            [9, 0.8]
                        ]
                    },
                    // assign color values be applied to points depending on their density
                    'heatmap-color': [
                        'interpolate',
                        ['linear'],
                        ['heatmap-density'],
                        0, 'rgb(255, 255, 255)',
                        0.01, 'rgb(51, 153, 255)',
                        0.1, 'rgb(153, 204, 255)',
                        0.5, 'rgb(255, 255, 204)',
                        0.8, 'rgb(255, 153, 102)',
                        1, 'rgb(255, 51, 0)'
                    ],
                    // increase radius as zoom increases
                    'heatmap-radius': {
                        stops: [
                            [5, 15],
                            [7, 50],
                            [8, 95],
                            [9, 200]
                        ]
                    },
                    // decrease opacity to transition into the circle layer
                    'heatmap-opacity': {
                        // default: 1,
                        stops: [
                            [5, 0.9],
                            [9, 0.2]
                        ]
                    },
                }
            }, 'waterway-label');


            // add circle layer here
            map.addLayer({
                id: 'trees-point',
                type: 'circle',
                source: 'trees',
                minzoom: 8,
                paint: {
                    // increase the radius of the circle as the zoom level and dbh value increases
                    'circle-radius': {
                        property: 'dbh',
                        type: 'exponential',
                        stops: [
                            [{ zoom: 8, value: 0 }, 20],
                            [{ zoom: 9, value: 0 }, 40]
                        ]
                    },
                    'circle-color': {
                        property: 'dbh',
                        type: 'exponential',
                        stops: [
                            [0, 'rgba(236,222,239,0)'],
                            [10, 'rgb(236,222,239)'],
                            [20, 'rgb(208,209,230)'],
                            [30, 'rgb(166,189,219)'],
                            [40, 'rgb(103,169,207)'],
                            [50, 'rgb(28,144,153)'],
                            [60, 'rgb(1,108,89)']
                        ]
                    },
                    'circle-stroke-color': 'rgb(89, 89, 89)',
                    'circle-stroke-width': 0.4,
                    'circle-opacity': {
                        stops: [
                            [0, 0.01]
                        ]
                    },
                    'circle-stroke-opacity': {
                        stops: [
                            [0, 0.2]
                        ]
                    }
                }
            }, 'waterway-label');

            map.on('click', 'trees-point', function(e) {
                new mapboxgl.Popup()
                    .setLngLat(e.features[0].geometry.coordinates)
                    .setHTML('<b>TP2M:</b> ' + e.features[0].properties.dbh)
                    .addTo(map);
            });
        });
    },
    true
);

// lngLat (array) The centerpoint to set.
function setCenter(lngLat) {
    map.setCenter(lngLat);
}

// zoom (number) The zoom level to set (0-20).
function setZoom(zoom) {
    map.setZoom(zoom);
    map.setCenter(map.getCenter());
}

// style (string) A JSON object conforming to the schema described in the Mapbox Style Specification , or a URL to such JSON.
function setStyle(style) {
    map.setStyle('mapbox://styles/mapbox/' + style + '-v9');
}

// pitch (number) The pitch to set, measured in degrees away from the plane of the screen (0-60).
function setPitch(pitch) {
    map.setPitch(pitch);
}