# Rename columns

Renames columns using a mapping (for year-specific inconsistencies).
Supports both global renames (applied to all periods) and
period-specific renames.

## Usage

``` r
rename_columns(df, rename_config, period = NULL)
```

## Arguments

- df:

  Tibble, specifying data with columns to rename

- rename_config:

  List or named vector, specifying rename configuration. Can contain:

  - Simple mappings: `new_name: old_name` (applied to all periods)

  - Period-specific mappings: `"YYYY-YY": {new_name: old_name}`

- period:

  Character, specifying current period (e.g., "2023-24", "2025-09")

## Value

Tibble with renamed columns
