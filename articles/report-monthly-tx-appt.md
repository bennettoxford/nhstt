# Monthly treatment appointment measures

``` js
// Configuration constants
CONFIG = ({
  maxSelections: 3,
  minSearchLength: 3,
  selectionColors: ["#E69F00", "#56B4E9", "#009E73"], // Orange, Sky Blue, Green
  chipOpacity: 0.2,
  plotMargins: {
    top: 35,
    right: 20,
    bottom: 30,
    left: 40
  }
})
```

``` js
// Convert R data to JavaScript format with proper date handling
// Handles: simple value, paired pct_value/count_value (outcomes), paired mean_value/count_value (appointments)
function convertPlotData(data) {
  return data.map(d => ({
    ...d,
    start_date: new Date(d.start_date),
    end_date: new Date(d.end_date),
    value: d.value === null ? NaN : d.value,
    pct_value: d.pct_value === null ? NaN : d.pct_value,
    mean_value: d.mean_value === null ? NaN : d.mean_value,
    count_value: d.count_value === null ? NaN : d.count_value
  }));
}
```

``` js
urlOrgsParam = {
  const params = new URLSearchParams(window.location.search);
  return params.get('orgs') || '';
}

// Parse URL parameter into array of codes
urlOrgCodes = {
  if (!urlOrgsParam) return [];

  const codes = urlOrgsParam.split(',');
  const trimmed = [];

  for (let i = 0; i < codes.length && i < CONFIG.maxSelections; i++) {
    const code = codes[i].trim();
    if (code.length > 0) {
      trimmed.push(code);
    }
  }

  return trimmed;
}

// Validate codes and convert to org objects
initialSelectedOrgs = {
  const resolved = [];

  for (let i = 0; i < urlOrgCodes.length; i++) {
    const code = urlOrgCodes[i];

    // Find org with this code
    let found = null;
    for (let j = 0; j < organisations.length; j++) {
      if (organisations[j].org_code2 === code) {
        found = organisations[j];
        break;
      }
    }

    // Add if valid and not duplicate
    if (found) {
      let isDuplicate = false;
      for (let k = 0; k < resolved.length; k++) {
        if (resolved[k].org_code2 === code) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) {
        resolved.push(found);
      }
    }
  }

  return resolved;
}

// Sync URL when selected orgs change
urlSyncEffect = {
  const params = new URLSearchParams(window.location.search);

  if (selectedOrgs.length === 0) {
    params.delete('orgs');
  } else {
    const codes = [];
    for (let i = 0; i < selectedOrgs.length; i++) {
      codes.push(selectedOrgs[i].org_code2);
    }
    params.set('orgs', codes.join(','));
  }

  const newUrl = params.toString()
    ? window.location.pathname + '?' + params.toString()
    : window.location.pathname;

  window.history.replaceState({}, '', newUrl);

  return null;
}
```

``` js
styles = html`<style>
  .nhstt-container {
    max-width: 800px;
    margin: 0 auto;
    padding: 0 4px;
  }

  .nhstt-input-group-wrapper {
    margin-top: 8px;
    margin-bottom: 12px;
  }

  .nhstt-label {
    display: block;
    font-weight: 600;
    font-size: 14px;
    margin-bottom: 6px;
    color: #212529;
  }

  .nhstt-input-group {
    display: flex;
    width: 100%;
    gap: 0;
    overflow: visible;
  }

  .nhstt-input {
    flex: 0 0 75%;
    width: 75%;
    padding: 10px 12px;
    font-size: 14px;
    border: 1px solid #dee2e6;
    border-radius: 0.375rem 0 0 0.375rem;
    border-right: none;
    box-sizing: border-box;
  }

  .nhstt-input:focus {
    outline: none;
    border-color: #86b7fe;
    border-right: 1px solid #86b7fe;
    box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.25);
    z-index: 2;
    position: relative;
  }

  .nhstt-select {
    flex: 0 0 25%;
    width: 25%;
    padding: 10px 12px;
    font-size: 14px;
    border: 1px solid #dee2e6;
    border-radius: 0 0.375rem 0.375rem 0;
    box-sizing: border-box;
    background-color: white;
    position: relative;
  }

  .nhstt-select:focus {
    outline: none;
    border-color: #86b7fe;
    box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.25);
    z-index: 2;
    position: relative;
  }

  .nhstt-select:disabled {
    background-color: #e9ecef;
    color: #6c757d;
    cursor: not-allowed;
  }

  .nhstt-result-box {
    padding: 12px 16px;
    border: 1px solid #dee2e6;
    border-radius: 0.375rem;
    background: white;
    height: 48px;
    display: flex;
    align-items: center;
    transition: background-color 0.2s ease;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  }

  .nhstt-result-box.at-max {
    background: #f8f9fa;
  }

  .nhstt-result-empty {
    margin: 0;
    font-size: 13px;
    color: #6c757d;
  }

  .nhstt-chip-container {
    display: flex;
    flex-wrap: nowrap;
    gap: 6px;
    width: 100%;
    overflow: hidden;
  }

  .nhstt-chip {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 3px 8px;
    background: #f8f9fa;
    border: 1.5px solid #6c757d;
    border-radius: 0.25rem;
    font-size: 11px;
    color: #212529;
    white-space: nowrap;
    min-width: 0;
  }

  .nhstt-chip.has-three {
    flex: 0 1 calc(33.333% - 4px);
  }

  .nhstt-chip.has-two {
    flex: 0 1 auto;
  }

  .nhstt-chip.has-one {
    flex: 0 1 auto;
  }

  .nhstt-chip-label {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .nhstt-chip-remove {
    background: none;
    border: none;
    color: #adb5bd;
    font-size: 16px;
    line-height: 1;
    cursor: pointer;
    padding: 0;
    margin-left: 2px;
    width: 14px;
    height: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: color 0.15s;
  }

  .nhstt-chip-remove:hover {
    color: #6c757d;
  }
</style>`
```

``` js
// Mutable state for selected organisations (max 3)
mutable selectedOrgs = initialSelectedOrgs
```

``` js
selectedOrgColorScale = d3.scaleOrdinal()
  .range(CONFIG.selectionColors)

// Get color for an organisation (selected orgs get distinct colors, others get gray)
function getSelectedOrgColor(orgCode) {
  const index = selectedOrgs.findIndex(org => org.org_code2 === orgCode);
  return index >= 0 ? selectedOrgColorScale(index) : "#ddd";
}

// Get subtle background color for an organisation chip
function getSelectedOrgBgColor(orgCode) {
  const index = selectedOrgs.findIndex(org => org.org_code2 === orgCode);
  if (index < 0) return "transparent";
  const color = selectedOrgColorScale(index);
  // Convert hex to rgba with opacity from CONFIG
  const r = parseInt(color.slice(1, 3), 16);
  const g = parseInt(color.slice(3, 5), 16);
  const b = parseInt(color.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${CONFIG.chipOpacity})`;
}

// Helper function to darken a color (for hover state)
function darkenColor(color) {
  // Convert hex to RGB
  const r = parseInt(color.slice(1, 3), 16);
  const g = parseInt(color.slice(3, 5), 16);
  const b = parseInt(color.slice(5, 7), 16);
  // Darken by 30%
  const darkenFactor = 0.7;
  const newR = Math.round(r * darkenFactor);
  const newG = Math.round(g * darkenFactor);
  const newB = Math.round(b * darkenFactor);
  // Convert back to hex
  return `#${newR.toString(16).padStart(2, '0')}${newG.toString(16).padStart(2, '0')}${newB.toString(16).padStart(2, '0')}`;
}
```

``` js
// Create interactive time series plot with hover tooltips and highlighting
// Parameters:
//   data: array of data points with start_date, end_date, value, org_name_code, org_code2
//   yAxisLabel: label for y-axis
//   yDomain: optional [min, max] for y-axis (e.g., [0, 100] for percentages). If not provided, auto-scales.
function createTimeSeriesPlot(data, yAxisLabel, yDomain = null) {
  // Plot dimensions and margins from CONFIG
  const width = 928;
  const height = 400;
  const marginTop = CONFIG.plotMargins.top;
  const marginRight = CONFIG.plotMargins.right;
  const marginBottom = CONFIG.plotMargins.bottom;
  const marginLeft = CONFIG.plotMargins.left;

  // Helper to get the value from data (handles pct_value, mean_value, or value)
  const getValue = d => !isNaN(d.pct_value) ? d.pct_value : (!isNaN(d.mean_value) ? d.mean_value : d.value);

  // Create scales
  const x = d3.scaleUtc()
    .domain(d3.extent(data, d => d.start_date))
    .range([marginLeft, width - marginRight]);

  const y = d3.scaleLinear()
    .domain(yDomain || [0, d3.max(data, d => getValue(d))])
    .nice()
    .range([height - marginBottom, marginTop]);

  // Create SVG container
  const svg = d3.create("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("viewBox", [0, 0, width, height])
      .attr("style", "max-width: 100%; height: auto; overflow: visible; font: 14px sans-serif;");

  // Add axes
  svg.append("g")
      .attr("transform", `translate(0,${height - marginBottom})`)
      .call(d3.axisBottom(x).ticks(width / 80).tickSizeOuter(0))
      .style("font-size", "14px");

  svg.append("g")
      .attr("transform", `translate(${marginLeft},0)`)
      .call(d3.axisLeft(y))
      .call(g => g.select(".domain").remove())
      .call(g => g.append("text")
          .attr("transform", "rotate(-90)")
          .attr("x", -(height - marginBottom - marginTop) / 2 - marginTop)
          .attr("y", -marginLeft + 12)
          .attr("fill", "currentColor")
          .attr("text-anchor", "middle")
          .style("font-size", "14px")
          .text(yAxisLabel))
      .style("font-size", "14px");

  // Prepare points and groups
  const points = data.filter(d => !isNaN(getValue(d))).map((d) =>
    [x(d.start_date), y(getValue(d)), d.org_name_code, d]
  );
  const groups = d3.rollup(points, v => Object.assign(v, {z: v[0][2]}), d => d[2]);
  const selectedOrgCodes = selectedOrgs.map(org => org.org_code2);

  // Draw lines
  const line = d3.line();
  const path = svg.append("g")
      .attr("fill", "none")
      .attr("stroke-linejoin", "round")
      .attr("stroke-linecap", "round")
    .selectAll("path")
    .data(groups.values())
    .join("path")
      .style("mix-blend-mode", selectedOrgCodes.length > 0 ? null : "multiply")
      .attr("d", line)
      .attr("stroke", d => {
        const orgCode = data.find(item => item.org_name_code === d.z)?.org_code2;
        return getSelectedOrgColor(orgCode);
      })
      .attr("stroke-width", d => {
        const orgCode = data.find(item => item.org_name_code === d.z)?.org_code2;
        return selectedOrgCodes.includes(orgCode) ? 2.5 : 1.5;
      });

  // Raise selected organization paths to the top
  path.each(function(d) {
    const orgCode = data.find(item => item.org_name_code === d.z)?.org_code2;
    if (selectedOrgCodes.includes(orgCode)) {
      d3.select(this).raise();
    }
  });

  // Create tooltip
  const dot = svg.append("g").attr("display", "none");
  dot.append("circle").attr("r", 2.5);
  dot.append("rect")
      .attr("class", "tooltip-box")
      .attr("fill", "white")
      .attr("stroke", "#333")
      .attr("stroke-width", 1)
      .attr("rx", 4)
      .attr("ry", 4)
      .attr("x", 8)
      .attr("y", -56)
      .attr("width", 200)
      .attr("height", 55);

  dot.append("text").attr("class", "tooltip-provider").attr("x", 13).attr("y", -43)
      .attr("font-weight", "bold").attr("font-size", "13px").attr("fill", "black");
  dot.append("text").attr("class", "tooltip-date").attr("x", 13).attr("y", -30)
      .attr("font-size", "12px").attr("fill", "black");
  dot.append("text").attr("class", "tooltip-value").attr("x", 13).attr("y", -17)
      .attr("font-size", "12px").attr("fill", "black");
  dot.append("text").attr("class", "tooltip-count").attr("x", 13).attr("y", -4)
      .attr("font-size", "12px").attr("fill", "black");

  // Interaction handlers
  function pointermoved(event) {
    const [xm, ym] = d3.pointer(event);
    const i = d3.leastIndex(points, ([x, y]) => Math.hypot(x - xm, y - ym));
    const [x, y, k, dataPoint] = points[i];

    path.style("stroke", ({z}) => {
      const orgCode = data.find(item => item.org_name_code === z)?.org_code2;
      const baseColor = getSelectedOrgColor(orgCode);
      if (z === k) {
        return baseColor === "#ddd" ? "steelblue" : darkenColor(baseColor);
      }
      return baseColor;
    }).filter(({z}) => z === k).raise();

    // Re-raise selected organizations
    path.each(function(d) {
      const orgCode = data.find(item => item.org_name_code === d.z)?.org_code2;
      if (selectedOrgCodes.includes(orgCode)) {
        d3.select(this).raise();
      }
    });

    // Update tooltip content
    const dateFormatter = d3.timeFormat("%B %Y");
    if (dataPoint) {
      dot.select(".tooltip-provider").text(dataPoint.org_name_code);
      dot.select(".tooltip-date").text(`Month: ${dateFormatter(dataPoint.start_date)}`);

      // Check data type and show appropriate tooltip
      const isPctData = !isNaN(dataPoint.pct_value);
      const isMeanData = !isNaN(dataPoint.mean_value);

      if (isPctData) {
        // For outcomes: Percentage (M186): 67% \n Count (M185): 430
        dot.select(".tooltip-value").text(`Percentage (${dataPoint.pct_measure_id}): ${dataPoint.pct_value.toLocaleString()}%`);
        dot.select(".tooltip-count").text(`Count (${dataPoint.count_measure_id}): ${dataPoint.count_value.toLocaleString()}`);
      } else if (isMeanData) {
        // For appointments: Mean (M120): 5.2 \n Count (M082): 140
        dot.select(".tooltip-value").text(`Mean (${dataPoint.mean_measure_id}): ${dataPoint.mean_value.toLocaleString()}`);
        dot.select(".tooltip-count").text(`Count (${dataPoint.count_measure_id}): ${dataPoint.count_value.toLocaleString()}`);
      } else {
        // Fallback for simple value data
        dot.select(".tooltip-value").text(`Value: ${dataPoint.value.toLocaleString()}`);
        dot.select(".tooltip-count").text("");
      }

      // Calculate tooltip width
      const providerWidth = dot.select(".tooltip-provider").node().getComputedTextLength();
      const dateWidth = dot.select(".tooltip-date").node().getComputedTextLength();
      const valueWidth = dot.select(".tooltip-value").node().getComputedTextLength();
      const countWidth = dot.select(".tooltip-count").node().getComputedTextLength();
      const maxWidth = Math.max(providerWidth, dateWidth, valueWidth, countWidth);
      const padding = 10;
      const tooltipWidth = maxWidth + (padding * 2);

      // Position tooltip to keep within bounds
      let tooltipX = 8;
      let tooltipY = -56;
      if (x + tooltipX + tooltipWidth > width - marginRight) {
        tooltipX = -(tooltipWidth + 8);
      }
      if (y + tooltipY < marginTop) {
        tooltipY = 10;
      }

      // Update tooltip positions
      dot.select(".tooltip-box").attr("width", tooltipWidth).attr("x", tooltipX).attr("y", tooltipY);
      const textOffsetX = tooltipX + 5;
      const textOffsetY = tooltipY + 13;
      dot.select(".tooltip-provider").attr("x", textOffsetX).attr("y", textOffsetY);
      dot.select(".tooltip-date").attr("x", textOffsetX).attr("y", textOffsetY + 13);
      dot.select(".tooltip-value").attr("x", textOffsetX).attr("y", textOffsetY + 26);
      dot.select(".tooltip-count").attr("x", textOffsetX).attr("y", textOffsetY + 39);
    }

    dot.attr("transform", `translate(${x},${y})`);
    svg.property("value", data[i]).dispatch("input", {bubbles: true});
  }

  function pointerentered() {
    path.style("mix-blend-mode", null);
    dot.attr("display", null);
  }

  function pointerleft() {
    path.style("mix-blend-mode", selectedOrgCodes.length > 0 ? null : "multiply")
        .style("stroke", d => {
      const orgCode = data.find(item => item.org_name_code === d.z)?.org_code2;
      return getSelectedOrgColor(orgCode);
    });

    path.each(function(d) {
      const orgCode = data.find(item => item.org_name_code === d.z)?.org_code2;
      if (selectedOrgCodes.includes(orgCode)) {
        d3.select(this).raise();
      }
    });

    dot.attr("display", "none");
    svg.node().value = null;
    svg.dispatch("input", {bubbles: true});
  }

  svg.on("pointerenter", pointerentered)
     .on("pointermove", pointermoved)
     .on("pointerleave", pointerleft)
     .on("touchstart", event => event.preventDefault());

  return svg.node();
}
```

> **Note:** This report is in active development and designed for
> feedback on the user interface and visualisation methods. We have not
> done data assurance, results need to be interpreted carefully.

``` js
plotDataM120 = convertPlotData(transpose(plot_data_m120_ojs))
plotDataM112 = convertPlotData(transpose(plot_data_m112_ojs))
organisations = transpose(org_list_ojs)
```

### Select NHS TT providers

``` js
viewof searchAndSelect = {
  const maxReached = selectedOrgs.length >= CONFIG.maxSelections;

  const container = html`<div class="nhstt-container">
    <div class="nhstt-input-group-wrapper">
      <div class="nhstt-input-group">
        <input
          type="text"
          class="nhstt-input"
          placeholder="Search by name or code (min ${CONFIG.minSearchLength} characters) and select provider ..."
          value=""
        />
        <select class="nhstt-select" ${maxReached ? 'disabled' : ''}>
          <option value="">${maxReached ? `Max ${CONFIG.maxSelections} selected` : 'Select provider'}</option>
        </select>
      </div>
    </div>
  </div>`;

  const input = container.querySelector('input');
  const select = container.querySelector('select');
  container.value = { searchQuery: "", orgToAdd: null };

  function updateDropdownOptions(searchQuery) {
    if (!searchQuery || searchQuery.length < CONFIG.minSearchLength) {
      select.innerHTML = `<option value="">Enter at least ${CONFIG.minSearchLength} characters</option>`;
      select.disabled = true;
      return;
    }

    if (maxReached) {
      select.innerHTML = `<option value="">Max ${CONFIG.maxSelections} selected</option>`;
      select.disabled = true;
      return;
    }

    const lowerQuery = searchQuery.toLowerCase();
    const filteredOrgs = organisations.filter(org =>
      org.org_name_code.toLowerCase().includes(lowerQuery)
    );

    if (filteredOrgs.length === 0) {
      select.innerHTML = '<option value="">No results</option>';
      select.disabled = true;
      return;
    }

    const availableOrgs = filteredOrgs.filter(org =>
      !selectedOrgs.some(selected => selected.org_code2 === org.org_code2)
    );

    select.disabled = false;
    select.innerHTML = `<option value="">Select (${availableOrgs.length} found)</option>`;

    availableOrgs.forEach((org, i) => {
      const option = document.createElement('option');
      option.value = i;
      option.textContent = org.org_name_code;
      select.appendChild(option);
    });

    select._availableOrgs = availableOrgs;
  }

  input.addEventListener('input', (e) => {
    const searchQuery = e.target.value;
    container.value = { ...container.value, searchQuery };
    updateDropdownOptions(searchQuery);
    container.dispatchEvent(new Event('input'));
  });

  select.addEventListener('change', (e) => {
    const index = parseInt(e.target.value);
    if (isNaN(index) || !select._availableOrgs) return;

    const selectedOrg = select._availableOrgs[index];
    container.value = { ...container.value, orgToAdd: selectedOrg };
    container.dispatchEvent(new Event('input'));
    e.target.value = "";
  });

  return container;
}

// Extract values from search/select component
searchQuery = searchAndSelect.searchQuery
orgToAdd = searchAndSelect.orgToAdd

// Add organisation to selected list when dropdown changes
addOrgEffect = {
  if (orgToAdd && selectedOrgs.length < CONFIG.maxSelections) {
    const alreadySelected = selectedOrgs.some(org => org.org_code2 === orgToAdd.org_code2);
    if (!alreadySelected) {
      mutable selectedOrgs = [...selectedOrgs, orgToAdd];
    }
  }
  return null;
}
```

``` js
selectedOrgDisplay = {
  const container = html`<div class="nhstt-container" style="margin-bottom: 12px;"></div>`;
  const resultBox = document.createElement('div');

  if (selectedOrgs.length === CONFIG.maxSelections) {
    resultBox.className = 'nhstt-result-box at-max';
  } else {
    resultBox.className = 'nhstt-result-box';
  }

  if (selectedOrgs.length === 0) {
    const emptyMsg = document.createElement('span');
    emptyMsg.className = 'nhstt-result-empty';
    emptyMsg.textContent = 'No provider selected';
    resultBox.appendChild(emptyMsg);
  } else {
    const chipContainer = document.createElement('div');
    chipContainer.className = 'nhstt-chip-container';

    const sizeClass = selectedOrgs.length === CONFIG.maxSelections ? 'has-three'
                    : selectedOrgs.length === 2 ? 'has-two'
                    : 'has-one';

    selectedOrgs.forEach(org => {
      const chip = document.createElement('div');
      chip.className = `nhstt-chip ${sizeClass}`;
      chip.style.backgroundColor = getSelectedOrgBgColor(org.org_code2);

      const label = document.createElement('span');
      label.className = 'nhstt-chip-label';
      label.textContent = org.org_name_code;
      label.title = org.org_name_code;
      chip.appendChild(label);

      const removeBtn = document.createElement('button');
      removeBtn.className = 'nhstt-chip-remove';
      removeBtn.innerHTML = '×';
      removeBtn.title = 'Remove';
      removeBtn.onclick = () => {
        mutable selectedOrgs = selectedOrgs.filter(o => o.org_code2 !== org.org_code2);
      };
      chip.appendChild(removeBtn);

      chipContainer.appendChild(chip);
    });

    resultBox.appendChild(chipContainer);
  }

  container.appendChild(resultBox);
  return container;
}
```

### Treatment appointment measures

#### Mean HI appointments (M112)

``` js
plotM112 = createTimeSeriesPlot(plotDataM112, "Mean HI appointments")
```

#### Mean LI appointments (M120)

``` js
plotM120 = createTimeSeriesPlot(plotDataM120, "Mean LI appointments")
```

### Measure descriptions
