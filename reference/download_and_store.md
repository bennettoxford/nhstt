# Download, parse, and store raw data

Download, parse, and store raw data

## Usage

``` r
download_and_store(
  dataset,
  period,
  frequency,
  url,
  source_format,
  file_path,
  csv_pattern = NULL,
  sheet = NULL,
  range = NULL
)
```

## Arguments

- dataset:

  Character, dataset name

- period:

  Character, reporting period

- frequency:

  Character, "annual" or "monthly"

- url:

  Character, source URL

- source_format:

  Character, source format ("csv", "zip", "rar", "xlsx")

- file_path:

  Character, destination path

- csv_pattern:

  Character, regex to locate CSV inside archive (optional)

- sheet:

  Character, sheet name or index for Excel sources (required for Excel
  sources)

- range:

  Character, Excel cell range (e.g., "A5:H427") for Excel sources
  (optional)

## Value

Character path to cached file
