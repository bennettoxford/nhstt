# Display cache information

Shows information about the nhstt cache, including:

- Cache directory location

- Size and count of raw annual and monthly downloads

- Size of tidy annual and monthly data

- Total cache size

## Usage

``` r
cache_info(max_size_mb = 1000)
```

## Arguments

- max_size_mb:

  Numeric, specifying maximum recommended cache size in MB. Default 1000

## Value

Invisibly returns a list with cache information

## Details

Raw data is stored in parquet format for efficient compression.

Warns if cache exceeds recommended size limit (default 1000 MB).

## Examples

``` r
if (FALSE) { # \dontrun{
# Display cache information
cache_info()

# Check with different size limit
cache_info(max_size_mb = 500)
} # }
```
