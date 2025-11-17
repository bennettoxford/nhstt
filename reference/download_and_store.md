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
  csv_pattern = NULL
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

  Character, source format ("csv", "zip", "rar")

- file_path:

  Character, destination path

- csv_pattern:

  Character, regex to locate CSV inside archive (optional)

## Value

Character path to cached file
