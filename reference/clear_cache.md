# Clear cache

Removes cached data files. By default clears all cache. When clearing
"all" cache, also removes the initialization marker, which will trigger
the welcome message on next package load.

## Usage

``` r
clear_cache(type = "all")
```

## Arguments

- type:

  Character, specifying cache type to clear ("all", "raw", or "tidy").
  Default "all".

## Value

Invisible TRUE

## Examples

``` r
if (FALSE) { # \dontrun{
# Clear all cache
clear_cache()

# Clear only raw data cache
clear_cache(type = "raw")

# Clear only tidy data cache
clear_cache(type = "tidy")
} # }
```
