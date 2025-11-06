#' Tidy annual dataset
#'
#' Generic tidying function for annual report datasets. Applies the standard
#' tidying pipeline using configuration provided in the dataset config.
#'
#' @param raw_data Named list of raw data by period
#' @param config Dataset configuration list
#' @return Tidied tibble
#' @keywords internal
tidy_annual_dataset <- function(raw_data, config) {
  if (missing(config)) {
    cli::cli_abort("Dataset configuration must be supplied to tidy_annual_dataset()")
  }

  # Clean table and column names first
  raw_data <- clean_raw_data_names(raw_data)

  selected_data <- select_tables_by_pattern(raw_data, config$pattern)

  # Apply variable mapping if provided
  if (!is.null(config$var_mapping)) {
    selected_data <- standardise_variables(selected_data, config$var_mapping)
  }

  flattened_data <- flatten_one_level(selected_data, dataset_name = config$name)
  filtered_data <- apply_config_filters(flattened_data, config$filters)

  # Select columns: combine id_cols and measure_cols
  all_cols <- c(config$id_cols, config$measure_cols)
  selected_vars <- select_dataset_columns(filtered_data, all_cols)
  tidied_data <- tidy_dataset_values(selected_vars, config$measure_cols)

  # Pivot measure columns to long format
  df_tidy <- pivot_measure_columns(
    tidied_data,
    frequency = config$frequency,
    measure_cols = config$measure_cols,
    extract_regex = config$extract_regex
  )

  # Apply measure prefix stripping if configured
  if (!is.null(config$measure_strip_prefix)) {
    df_tidy <- strip_measure_prefix(df_tidy, config$measure_strip_prefix)
  }

  validate_dataset(df_tidy, config$name)
  df_tidy
}
