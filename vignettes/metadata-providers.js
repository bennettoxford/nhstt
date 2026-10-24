// Map interactions for metadata-providers.qmd, passed to htmlwidgets::onRender().
// Every filter is a crosstalk filter on the "providers" group, so the map, the
// table, and the table footer count always agree.
function(el, x, data) {
  var map = this;
  var regions = JSON.parse(data.regions_geojson);
  map.attributionControl.addAttribution(regions.attribution);

  var positions = {};
  data.key.forEach(function(key, i) {
    positions[key] = [data.lat[i], data.lng[i]];
  });

  function keysWhere(test) {
    return data.key.filter(function(key, i) {
      return test(i);
    });
  }

  // Ticked providers get a border on a separate layer, so they stay visible in
  // dense areas such as London
  var selectionBorders = L.layerGroup().addTo(map);
  var selection = new crosstalk.SelectionHandle('providers');
  selection.on('change', function(e) {
    selectionBorders.clearLayers();
    (e.value || []).forEach(function(key) {
      L.circleMarker(positions[key], {
        radius: 6.5,
        color: '#383f43',
        weight: 2,
        fill: false,
        interactive: false
      }).addTo(selectionBorders);
    });
  });

  // Clickable ODS status legend, starting with active providers only
  var shownStatuses = { Active: true, Inactive: false };
  var statusFilter = new crosstalk.FilterHandle('providers');

  var legend = L.control({ position: 'topright' });
  legend.onAdd = function() {
    var div = L.DomUtil.create('div', 'status-legend');
    div.innerHTML = '<strong>ODS status</strong>';
    data.status_levels.forEach(function(status, i) {
      var item = L.DomUtil.create('div', 'status-item', div);
      item.dataset.status = status;
      item.innerHTML =
        '<i style="background:' + data.status_colours[i] + '"></i>' + status;
      item.onclick = function() {
        shownStatuses[status] = !shownStatuses[status];
        updateStatus();
      };
    });
    L.DomEvent.disableClickPropagation(div);
    return div;
  };
  legend.addTo(map);

  function updateStatus() {
    statusFilter.set(keysWhere(function(i) {
      return shownStatuses[data.status[i]];
    }));
    legend.getContainer().querySelectorAll('.status-item').forEach(function(item) {
      item.classList.toggle('off', !shownStatuses[item.dataset.status]);
    });
  }

  // Clickable regions, drawn in their own pane below the markers
  map.createPane('regions');
  map.getPane('regions').style.zIndex = 350;

  var regionStyle = { color: '#505a5f', weight: 1, fillColor: '#f3f2f1', fillOpacity: 1 };
  var chosenRegionStyle = { fillColor: '#d2e2f1' };
  var chosenRegions = {};
  var regionFilter = new crosstalk.FilterHandle('providers');

  L.geoJSON(regions, {
    pane: 'regions',
    style: regionStyle,
    onEachFeature: function(feature, layer) {
      var region = feature.properties.region_name;
      layer.bindTooltip(region, { sticky: true });
      layer.on('click', function() {
        chosenRegions[region] = !chosenRegions[region];
        layer.setStyle(chosenRegions[region] ? chosenRegionStyle : regionStyle);
        updateRegion();
      });
    }
  }).addTo(map);

  function updateRegion() {
    var anyChosen = Object.keys(chosenRegions).some(function(region) {
      return chosenRegions[region];
    });
    if (!anyChosen) {
      regionFilter.clear();
      return;
    }
    // Providers without a region, mostly inactive ones, always stay in
    regionFilter.set(keysWhere(function(i) {
      return data.region[i] === data.no_region || chosenRegions[data.region[i]];
    }));
  }

  // Buttons above the map show providers in the latest data for one frequency
  var reportingFilter = new crosstalk.FilterHandle('providers');
  var reportingButtons = document.querySelectorAll('.reporting-button');
  reportingButtons.forEach(function(button) {
    button.addEventListener('click', function() {
      reportingButtons.forEach(function(other) {
        other.classList.toggle('active', other === button);
      });
      var reported = data.reported[button.dataset.reporting];
      if (!reported) {
        reportingFilter.clear();
        return;
      }
      reportingFilter.set(keysWhere(function(i) {
        return reported[i];
      }));
    });
  });

  // reactable search only filters the table, so pass it on to the map too
  var searchFilter = new crosstalk.FilterHandle('providers');
  var lastSearch = '';
  function updateSearch(state) {
    var search = (state.searchValue || '').trim().toLowerCase();
    if (search === lastSearch) {
      return;
    }
    lastSearch = search;
    if (search === '') {
      searchFilter.clear();
      return;
    }
    searchFilter.set(keysWhere(function(i) {
      return data.search_text[i].indexOf(search) !== -1;
    }));
  }

  // Wait until the table has loaded so it picks up the starting filter
  function start() {
    updateStatus();
    Reactable.onStateChange('provider-table', updateSearch);
  }
  if (document.readyState === 'complete') {
    setTimeout(start, 10);
  } else {
    window.addEventListener('load', function() {
      setTimeout(start, 10);
    });
  }
}
