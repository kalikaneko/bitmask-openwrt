const niceBlue = '#4166f5';
const discreteGrey = '#dcdcdc';

//onDocumentReady...
document.addEventListener('DOMContentLoaded', function () {
   window.vpnStatus = "OFF";
   let locType = document.querySelector('input[name="locationType"]:checked').value;
   if (locType === "manual") {
     document.getElementById('locations').style.visibility = "visible";
   }
   setInterval(doStatusPoll, 1000);
   populateGateways();
});

function vpnToggle() {
    toggleVisibility('vpn-spinner', 'visible');
    if (vpnStatus == 'OFF') {
        doAjaxCall("/start", function(){});
    } else if (vpnStatus == 'ON') {
        doAjaxCall("/stop", function(){});
    }
}

function toggleVisibility(selector, status) {
    // status: hidden | visible
    let e = document.getElementById(selector);
    e.style.visibility = status
}

function selectLocation(loc) {
    console.debug("selecting location: " + loc);
    doAjaxCall("/locations/set/" + loc, function(){});

    let e = document.getElementById("selGwBox");
    lName = window.byLocation[loc][0]['locationName'];
    e.textContent = lName
    document.getElementById("manualButton").checked = true;

    toggleVisibility('reconnect-toast', 'visible');
    for (var o of document.getElementById("locations").options) {
        if (o.value === loc) {
            o.selected = true;
            // exit early
            return;
        }
    }
}

function autoSelection() {
    console.debug("auto selection");
    // TODO do ajaxCall to set gw back to auto
}

function manualSelection() {
    console.debug("manual selection");
}

function addLocationToDropdown(name, value) {
        var opt = document.createElement("option");
        opt.text = name;
        opt.value = value;
        document.getElementById("locations").options.add(opt);
}

function doAjaxCall(url, callback) {
    var xobj = new XMLHttpRequest();
    xobj.open('GET', url, true);
    xobj.onreadystatechange = function () {
          if (xobj.readyState == 4 && xobj.status == "200") {
            callback(xobj.responseText);
          }
    };
    xobj.send(null);
}

function updateBubbles(active) {
    // TODO this gets undo when hover is over...
    let bubbleNodes = document.getElementsByClassName("bubbles")[0].children;
    for (const node of bubbleNodes) {
        let j = node.getAttribute('data-info');
        try {
          info = JSON.parse(j);
        } catch(err) {
          console.debug("ERROR: " + err);
        }

        // TODO get the colors from backend
        if (info.loc == active) {
            node.style.fill = "green";
        } else {
            node.style.fill = "blue";
        }
    };
}

function populateGateways() {
    doAjaxCall('/cities.json', function(response) {
        citiesJson = JSON.parse(response);
        doAjaxCall('/locations.json', function(response) {
            var bubbles = new Array();
            var byLocation = new Object();
            locationJson = JSON.parse(response);
            locationJson.forEach(function(gw, i, arr) {
                let loc = gw["location"];
                if (byLocation[loc] === undefined) {
                    byLocation[loc] = new Array();
                }
                byLocation[loc].push(gw);
            });
            locs = Object.keys(byLocation);
            locs.forEach(function(loc, i, arr) {
                let city = citiesJson[loc];
                let gws = byLocation[loc];
                let count = gws.length;
                let gw = getRandomItem(gws);
                bubbles.push({
                    "name": gw["host"],
                    "active": false,
                    "loc": loc,
                    "locationName": gw["locationName"],
                    "country": gw["cc"],
                    "radius": 8,
                    "fillKey": "GOOD",
                    "count": count,
                    "latitude": city["lat"],
                    "longitude": city["lon"]
                })
                addLocationToDropdown(gw["locationName"] + " (" + gw["cc"] + ")", loc);
            });
            window.byLocation = byLocation;
            gateways.bubbles(
                bubbles,
                {
                  popupTemplate: function(geo, data) {
                      return '<div class="hoverinfo">' + data.locationName + ' ('  + data.country + ') / ' + data.count + ' gateway(s)</div>'}
                }
            );
            d3.selectAll('.datamaps-bubble')
              .on('click', function(bubble, d) {
                    d3.selectAll('.datamaps-bubble')
                      .each(function(dd, i) {
                        d3.select(this)
                          .style('fill', niceBlue)
                          .attr('r', 8);
                    });
                    bubble.active = true;
                    selectLocation(bubble.loc);
                    d3.select(this).attr('r', bubble.active ? 15 : 8);
                    d3.select(this).style('fill', bubble.active ? 'green' : 'blue');
            });
        });
    });
}

function doLocationPoll() {
    doAjaxCall('getip', function(ipinfo) {
        wtfIp = JSON.parse(ipinfo.trim());
        let ipMark  = document.getElementById('ipBox');
        let ispMark = document.getElementById('ispBox');
        let locMark = document.getElementById('locBox');
        ipMark.textContent  = wtfIp["YourFuckingIPAddress"];
        ispMark.textContent = wtfIp["YourFuckingISP"];
        locMark.textContent = wtfIp["YourFuckingLocation"];
    });
}

function doStatusPoll() {
    let old = window.vpnStatus;
    // TODO add timeout detection, raise a toast if no connection to backend
    doAjaxCall('/status', function(st) {
        st = st.trim();
        if (st != "" && st != old) {
            doLocationPoll();
            console.debug("status change: " + st);
            let statusMark = document.getElementById('vpnStatus');
            let button = document.getElementById('vpnswitch');
            if (st == 'ON') {
                toggleVisibility('vpn-spinner', 'hidden');
                toggleVisibility('reconnect-toast', 'hidden');
                statusMark.className = 'tertiary';
                button.className = 'secondary';
                button.innerText = 'Switch OFF';
                button.value = 'stop';
                window.vpnStatus = st;
                statusMark.textContent = st;
            }
            if (st == 'OFF') {
                toggleVisibility('vpn-spinner', 'hidden');
                statusMark.className = 'secondary';
                button.className = 'tertiary';
                button.innerText = 'Switch ON';
                button.value = 'start';
                window.vpnStatus = st;
                statusMark.textContent = st;
            }
            if (st == 'CONNECTING') {
                statusMark.className = 'tertiary';
                window.vpnStatus = st;
                statusMark.textContent = st;
            }
        }
    });
}


function getRandomItem(items) {
    return items[Math.floor(Math.random() * items.length)];
}

/* prepare the map to place the gateways */

var gateways = new Datamap({
  element: document.getElementById("gateways"),
  geographyConfig: {
    popupOnHover: false,
    highlightOnHover: false
  },
  fills: {
    defaultFill: discreteGrey,
    GOOD: niceBlue,
    MID: 'orange',
    BAD: 'red'
  }
});

