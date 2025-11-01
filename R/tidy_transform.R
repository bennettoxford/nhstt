# Default regex pattern for identifying measure columns
# Matches columns starting with: count_, mean_, median_, percentage_, sum_
MEASURE_REGEX <- "^(count|mean|median|percentage|sum)_"

#' Simplify table names
#'
#' Extracts the core table type from verbose NHS file names by removing
#' redundant prefixes, suffixes, and standardising variations across years.
#'
#' @param names Character vector of raw table names
#' @return Simplified snake_case table names
#' @keywords internal
simplify_table_names <- function(names) {
  names |>
    # Remove .csv extension
    stringr::str_remove("\\.csv$") |>
    # Remove common prefix with year pattern
    stringr::str_remove("^psych-ther-ann-rep-csv-\\d{4}-\\d{2}-") |>
    # Remove version suffixes
    stringr::str_remove("-v\\d+$") |>
    stringr::str_remove("-\\d+$") |>
    # Standardise common variations across years
    stringr::str_replace("^emp-status$", "employment-status") |>
    stringr::str_replace("^psych-meds?$", "medication-status") |>
    stringr::str_replace("^psych-medication$", "medication-status") |>
    # Catches main-csv, main2, main-csv-v2, etc.
    stringr::str_replace("^main.*", "key-measures") |>
    # Normalise case and convert to snake_case
    stringr::str_to_lower() |>
    janitor::make_clean_names()
}

#' Simplify raw table names only
#'
#' Simplifies table names in raw data but leaves column names exactly as they
#' appear in the source files. Useful for exploring raw data structure.
#'
#' @param raw_data Nested list of data frames by period
#' @return List with simplified table names, original column names
#' @keywords internal
simplify_raw_table_names <- function(raw_data) {
  purrr::map(raw_data, function(tables) {
    names(tables) <- simplify_table_names(names(tables))
    tables
  })
}

#' Clean raw data names
#'
#' Standardises table names and column names in raw data using snake_case.
#' This is the first step in the tidy pipeline, ensuring consistent naming
#' before pattern matching and other operations.
#'
#' @param raw_data Nested list of data frames by period
#' @return List with cleaned table names and column names
#' @keywords internal
clean_raw_data_names <- function(raw_data) {
  purrr::map(raw_data, function(tables) {
    # Clean column names in each table
    cleaned_tables <- purrr::map(tables, function(df) {
      names(df) <- janitor::make_clean_names(names(df))
      df
    })
    # Simplify and clean table names
    names(cleaned_tables) <- simplify_table_names(names(cleaned_tables))
    cleaned_tables
  })
}

#' Apply filters defined in dataset configuration
#'
#' @param data List of data frames
#' @param filters Named list of filter values
#' @return List of filtered data frames
#' @keywords internal
apply_config_filters <- function(data, filters) {
  if (length(filters) == 0) {
    return(data)
  }

  purrr::map(data, function(df) {
    purrr::reduce(
      names(filters),
      .init = df,
      .f = function(acc, filter_var) {
        filter_vals <- filters[[filter_var]]
        dplyr::filter(acc, !!rlang::sym(filter_var) %in% filter_vals)
      }
    )
  })
}

#' Select configured columns from dataset
#'
#' Selects only columns that exist in each data frame. Columns that don't exist
#' are silently skipped, which allows handling of inconsistent column names
#' across years.
#'
#' @param data List of data frames
#' @param columns Character vector of columns to keep
#' @return List with columns selected
#' @keywords internal
select_dataset_columns <- function(data, columns) {
  purrr::map(data, function(df) {
    # Only select columns that actually exist
    existing_cols <- intersect(columns, names(df))
    dplyr::select(df, dplyr::all_of(existing_cols))
  })
}

#' Clean numeric values
#'
#' Replaces common non-numeric placeholders with NA before converting to numeric.
#' NHS data often uses special characters for data suppression or missing values
#' (e.g., "*" for suppressed values, "-" for not applicable).
#'
#' @param x Character vector to clean
#' @return Numeric vector with placeholders converted to NA
#' @keywords internal
clean_numeric_values <- function(x) {
  # Replace common non-numeric placeholders with NA
  x <- dplyr::case_when(
    x == "*" ~ NA_character_,
    x == "-" ~ NA_character_,
    x == "" ~ NA_character_,
    x == "N/A" ~ NA_character_,
    x == "NA" ~ NA_character_,
    x == "NULL" ~ NA_character_,
    x == "Null" ~ NA_character_,
    x == "null" ~ NA_character_,
    .default = x
  )
  # Convert to numeric (should not produce warnings now)
  as.numeric(x)
}

#' Tidy dataset values
#'
#' Replace "NULL" strings with NA and coerce measure columns to numeric.
#' Handles common NHS data suppression markers (*, -, etc.) gracefully.
#'
#' @param data List of data frames
#' @param measure_cols Character vector of measure column names
#' @return List of tidied data frames
#' @keywords internal
tidy_dataset_values <- function(data, measure_cols) {
  purrr::map(data, function(df) {
    # Get measure columns that exist in this data frame
    existing_measure_cols <- intersect(measure_cols, names(df))

    df |>
      dplyr::mutate(dplyr::across(dplyr::everything(), ~ dplyr::na_if(.x, "NULL"))) |>
      dplyr::mutate(dplyr::across(dplyr::all_of(existing_measure_cols), ~ clean_numeric_values(.x)))
  })
}

#' Pivot measure columns into tidy format
#'
#' @param data List of tidied data frames
#' @param frequency Data frequency: "annual", "quarterly", or "monthly"
#' @param measure_cols Character vector of measure column names to pivot
#' @param extract_regex Regex for extracting statistic and measure. Defaults to standard pattern.
#' @return Tidied tibble
#' @keywords internal
pivot_measure_columns <- function(data,
                                  frequency = "annual",
                                  measure_cols,
                                  extract_regex = "^(count|mean|median|percentage|sum)_(.+)$") {
  data |>
    dplyr::bind_rows(.id = "period") |>
    tidyr::pivot_longer(
      cols = dplyr::any_of(measure_cols),
      values_to = "value",
      values_ptypes = numeric(),
      names_to = "measure"
    ) |>
    tidyr::extract(
      col = measure,
      into = c("statistic", "measure"),
      regex = extract_regex
    ) |>
    add_period_columns(frequency = frequency) |>
    tibble::as_tibble()
}

#' Add period date columns based on frequency
#'
#' @param df Data frame with a period column
#' @param frequency Data frequency: "annual", "quarterly", or "monthly"
#' @param period_col Name of the period column
#' @return Data frame with start_date and end_date columns
#' @keywords internal
add_period_columns <- function(df,
                               frequency = "annual",
                               period_col = "period") {
  bounds <- parse_period_bounds(df[[period_col]], frequency)

  df |>
    dplyr::mutate(
      start_date = bounds$start_date,
      end_date = bounds$end_date
    ) |>
    dplyr::relocate(start_date, end_date, .before = dplyr::everything())
}

#' Standardise variable names
#'
#' @param data Nested list of data frames
#' @param var_mapping Named vector mapping old names to new names
#' @return List with renamed variables
#' @keywords internal
standardise_variables <- function(data, var_mapping) {
  purrr::map(data, function(period_list) {
    purrr::map(period_list, function(df) {
      df |>
        dplyr::rename_with(~ purrr::map_chr(.x, function(col) {
          if (col %in% names(var_mapping)) var_mapping[[col]] else col
        }))
    })
  })
}

#' Strip prefix from measure column
#'
#' Removes a specified prefix from the measure column in a tidied dataset.
#' Useful for cleaning verbose measure names after pivoting.
#'
#' @param df Tidied data frame with a measure column
#' @param prefix Character string to remove from the start of measure values
#' @return Data frame with cleaned measure values
#' @keywords internal
strip_measure_prefix <- function(df, prefix) {
  df |>
    dplyr::mutate(
      measure = stringr::str_remove(measure, paste0("^", prefix))
    )
}
