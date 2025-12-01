# Report: Treatment appointments

## Select NHS Talking Therapies provider

``` js
// Convert R data to JavaScript array of objects
organisations = transpose(org_list_ojs)
```

``` js
// Step 1: Just read URL parameter
urlOrgsParam = {
  const params = new URLSearchParams(window.location.search);
  return params.get('orgs') || '';
}
```

``` js
// Step 2: Parse URL parameter into array of codes
urlOrgCodes = {
  if (!urlOrgsParam) return [];

  const codes = urlOrgsParam.split(',');
  const trimmed = [];

  for (let i = 0; i < codes.length && i < 3; i++) {
    const code = codes[i].trim();
    if (code.length > 0) {
      trimmed.push(code);
    }
  }

  return trimmed;
}
```

``` js
// Step 3: Validate codes and convert to org objects
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
```

``` js
// Professional UI styling
styles = html`<style>
  .nhstt-container {
    max-width: 800px;
    margin: 0 auto;
    padding: 0 4px;
  }

  .nhstt-input-group {
    margin-bottom: 20px;
  }

  .nhstt-label {
    display: block;
    font-weight: 600;
    font-size: 14px;
    margin-bottom: 6px;
    color: #212529;
  }

  .nhstt-input {
    width: 100%;
    padding: 10px 12px;
    font-size: 14px;
    border: 1px solid #dee2e6;
    border-radius: 0.375rem;
    box-sizing: border-box;
  }

  .nhstt-input:focus {
    outline: none;
    border-color: #86b7fe;
    box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.25);
  }

  .nhstt-select {
    width: 100%;
    padding: 10px 12px;
    font-size: 14px;
    border: 1px solid #dee2e6;
    border-radius: 0.375rem;
    box-sizing: border-box;
    background-color: white;
  }

  .nhstt-select:disabled {
    background-color: #e9ecef;
    color: #6c757d;
    cursor: not-allowed;
  }

  .nhstt-helper-text {
    font-size: 12px;
    color: #6c757d;
    margin-top: 4px;
    font-style: italic;
  }

  .nhstt-result-box {
    margin-top: 20px;
    padding: 16px;
    border: 1px solid #dee2e6;
    border-radius: 0.375rem;
    background: white;
    min-height: 120px;
  }

  .nhstt-result-title {
    font-weight: 600;
    font-size: 14px;
    margin: 0 0 12px 0;
    color: #495057;
  }

  .nhstt-result-content {
    margin: 0;
    font-size: 14px;
    color: #212529;
  }

  .nhstt-result-empty {
    margin: 0;
    font-size: 14px;
    color: #6c757d;
  }

  .nhstt-chip-container {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    min-height: 28px;
  }

  .nhstt-chip {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 4px 10px;
    background: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 0.25rem;
    font-size: 13px;
    color: #212529;
  }

  .nhstt-chip-remove {
    background: none;
    border: none;
    color: #adb5bd;
    font-size: 18px;
    line-height: 1;
    cursor: pointer;
    padding: 0;
    margin-left: 4px;
    width: 16px;
    height: 16px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: color 0.15s;
  }

  .nhstt-chip-remove:hover {
    color: #6c757d;
  }

  .nhstt-selection-info {
    font-size: 12px;
    color: #6c757d;
    margin-top: 8px;
    font-weight: 600;
  }
</style>`
```

``` js
viewof searchQuery = {
  const container = html`<div class="nhstt-container">
    <div class="nhstt-input-group">
      <label class="nhstt-label">Search NHS Talking Therapies provider</label>
      <input
        type="text"
        class="nhstt-input"
        placeholder="Enter at least 3 characters to search..."
        value=""
      />
      <div class="nhstt-helper-text">Search by organisation name or code</div>
    </div>
  </div>`;

  const input = container.querySelector('input');
  container.value = "";

  input.addEventListener('input', (e) => {
    container.value = e.target.value;
    container.dispatchEvent(new Event('input'));
  });

  return container;
}
```

``` js
// Filter organisations based on search query
filteredOrganisations = {
  if (!searchQuery || searchQuery.length < 3) {
    return [];
  }

  const lowerQuery = searchQuery.toLowerCase();

  return organisations.filter(org => {
    const nameCodeMatch = org.org_name_code.toLowerCase().includes(lowerQuery);
    return nameCodeMatch;
  });
}
```

``` js
// Mutable state for selected organisations (max 3)
// Step 4: Initialize from URL
mutable selectedOrgs = initialSelectedOrgs
```

``` js
viewof orgToAdd = {
  const hasResults = filteredOrganisations.length > 0;
  const showPlaceholder = !searchQuery || searchQuery.length < 3;
  const maxReached = selectedOrgs.length >= 3;
  const isDisabled = !hasResults || maxReached;

  const container = html`<div class="nhstt-container">
    <div class="nhstt-input-group">
      <label class="nhstt-label">
        ${hasResults
          ? `${filteredOrganisations.length} result${filteredOrganisations.length !== 1 ? 's' : ''}`
          : 'Select organisation'}
      </label>
      <select class="nhstt-select" ${isDisabled ? 'disabled' : ''}>
        <option value="">
          ${maxReached
            ? '-- Maximum 3 organisations selected --'
            : showPlaceholder
              ? '-- Enter at least 3 characters to search --'
              : '-- No organisations found --'}
        </option>
      </select>
    </div>
  </div>`;

  const select = container.querySelector('select');

  if (hasResults && !maxReached) {
    // Clear placeholder and add real options
    select.innerHTML = '<option value="">-- Select an organisation --</option>';

    // Filter out already selected organisations
    const availableOrgs = filteredOrganisations.filter(org =>
      !selectedOrgs.some(selected => selected.org_code2 === org.org_code2)
    );

    availableOrgs.forEach((org, i) => {
      const option = document.createElement('option');
      option.value = i;
      option.textContent = org.org_name_code;
      select.appendChild(option);
    });

    select._availableOrgs = availableOrgs;
  }

  container.value = null;

  select.addEventListener('change', (e) => {
    const index = parseInt(e.target.value);
    if (!isNaN(index) && select._availableOrgs) {
      container.value = select._availableOrgs[index];
      container.dispatchEvent(new Event('input'));
      // Reset dropdown after selection
      select.value = "";
    }
  });

  return container;
}
```

``` js
// Add organisation to selected list when dropdown changes
addOrgEffect = {
  if (orgToAdd && selectedOrgs.length < 3) {
    // Check if not already selected
    const alreadySelected = selectedOrgs.some(org => org.org_code2 === orgToAdd.org_code2);
    if (!alreadySelected) {
      mutable selectedOrgs = [...selectedOrgs, orgToAdd];
    }
  }
  return null;
}
```

``` js
// Step 5: Update URL when selected orgs change
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
selectedOrgDisplay = {
  const container = html`<div class="nhstt-container"></div>`;

  if (selectedOrgs.length === 0) {
    container.innerHTML = `
      <div class="nhstt-result-box">
        <div class="nhstt-result-title">Selected Organisations (0 of 3)</div>
        <p class="nhstt-result-empty">No organisations selected. You can select up to 3 organisations.</p>
      </div>
    `;
  } else {
    const resultBox = document.createElement('div');
    resultBox.className = 'nhstt-result-box';

    const title = document.createElement('div');
    title.className = 'nhstt-result-title';
    title.textContent = `Selected Organisation${selectedOrgs.length !== 1 ? 's' : ''} (${selectedOrgs.length} of 3)`;
    resultBox.appendChild(title);

    const chipContainer = document.createElement('div');
    chipContainer.className = 'nhstt-chip-container';

    selectedOrgs.forEach(org => {
      const chip = document.createElement('div');
      chip.className = 'nhstt-chip';

      const label = document.createElement('span');
      label.textContent = org.org_name_code;
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
    container.appendChild(resultBox);
  }

  return container;
}
```
