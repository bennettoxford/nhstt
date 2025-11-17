#' Registry of tidy configuration functions
#'
#' @return Named list of tidy configuration functions
#'
#' @keywords internal
tidy_config_registry <- function() {
  list(
    key_measures = tidy_config_key_measures,
    activity_performance = tidy_config_activity_performance
  )
}

#' Load all tidy configurations
#'
#' @return List containing all tidy configurations
#'
#' @keywords internal
load_tidy_config <- function() {
  configs <- lapply(tidy_config_registry(), function(fn) fn())
  validate_tidy_config(configs)
  configs
}

#' Validate tidy configuration structure
#'
#' @param config List, specifying parsed tidy configuration
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @importFrom cli cli_abort cli_warn
#'
#' @keywords internal
validate_tidy_config <- function(config) {
  if (length(config) == 0) {
    cli_abort("Tidy configuration must define at least one dataset")
  }

  # Validate each dataset
  for (dataset_name in names(config)) {
    dataset <- config[[dataset_name]]

    # Check for frequency sections
    valid_frequencies <- c("annual", "monthly")
    freq_names <- names(dataset)

    if (length(freq_names) == 0) {
      cli_abort("Dataset {.val {dataset_name}} must have at least one frequency (annual/monthly)")
    }

    invalid_freqs <- setdiff(freq_names, valid_frequencies)
    if (length(invalid_freqs) > 0) {
      cli_abort(c(
        "Dataset {.val {dataset_name}} has invalid frequency: {.val {invalid_freqs}}",
        "i" = "Valid frequencies: {.val {valid_frequencies}}"
      ))
    }

    # Validate each frequency section
    for (freq in freq_names) {
      freq_config <- dataset[[freq]]

      # If pivot_longer exists (wide-to-long), validate structure
      has_pivot <- !is.null(freq_config$pivot_longer) && length(freq_config$pivot_longer) > 0
      if (has_pivot) {
        pivot_config <- freq_config$pivot_longer

        # Must have required fields
        if (is.null(pivot_config$measure_cols) || length(pivot_config$measure_cols) == 0) {
          cli_abort("Dataset {.val {dataset_name}} ({freq}) pivot_longer missing measure_cols")
        }
        if (is.null(pivot_config$sep)) {
          cli_abort("Dataset {.val {dataset_name}} ({freq}) pivot_longer missing sep pattern")
        }
        if (is.null(pivot_config$into) || length(pivot_config$into) == 0) {
          cli_abort("Dataset {.val {dataset_name}} ({freq}) pivot_longer missing into columns")
        }
      }

      # Validate select section if present
      if (!is.null(freq_config$select) && length(freq_config$select) == 0) {
        cli_warn("Dataset {.val {dataset_name}} ({freq}) select is empty - no columns will be selected")
      }
    }
  }

  invisible(TRUE)
}

#' Retrieve tidy configuration for a dataset/frequency combination
#'
#' @param dataset Character, dataset name (e.g., "key_measures")
#' @param frequency Character, "annual" or "monthly"
#'
#' @return Named list of configuration values
#'
#' @importFrom cli cli_abort
#'
#' @keywords internal
get_tidy_config <- function(dataset, frequency) {
  validate_dataset(dataset)
  validate_frequency(frequency)

  tidy_config <- load_tidy_config()

  dataset_config <- tidy_config[[dataset]][[frequency]]

  if (is.null(dataset_config)) {
    cli_abort(c(
      "Tidy configuration not found for {.val {dataset}} ({frequency})",
      "i" = "Check tidy_config_{dataset}.R"
    ))
  }

  # Set defaults for all config sections
  dataset_config$clean_column_names <- dataset_config$clean_column_names %||% FALSE
  dataset_config$rename <- dataset_config$rename %||% character()
  dataset_config$filter <- dataset_config$filter %||% list()
  dataset_config$type_convert <- dataset_config$type_convert %||% character()
  dataset_config$separate <- dataset_config$separate %||% list()
  dataset_config$mutate <- dataset_config$mutate %||% list()
  dataset_config$pivot_longer <- dataset_config$pivot_longer %||% list()
  dataset_config$clean_values <- dataset_config$clean_values %||% character()
  dataset_config$select <- dataset_config$select %||% character()

  dataset_config
}

#' Generic tidy pipeline for all datasets
#'
#' Applies configuration-driven transformations to convert raw data to tidy format.
#' Supports both wide-to-long pivoting (key_measures) and long-format data (activity_performance).
#'
#' @param raw_data_list Named list, specifying raw tibbles (e.g., list("2023-24" = df))
#' @param dataset Character, specifying dataset name (e.g., "key_measures")
#' @param frequency Character, specifying frequency ("annual" or "monthly")
#'
#' @return Tibble in tidy long format
#'
#' @importFrom purrr imap list_rbind
#' @importFrom janitor make_clean_names
#' @importFrom dplyr select rename mutate if_else
#' @importFrom rlang .data
#' @importFrom tidyselect any_of
#'
#' @keywords internal
tidy_dataset <- function(raw_data_list, dataset, frequency) {
  config <- get_tidy_config(dataset, frequency)

  # === BEFORE PIVOTING / BEFORE COMBINING DATA ===
  # Process each period individually
  tidy_list <- imap(raw_data_list, \(df, period) {
    # Clean column names to snake_case
    if (isTRUE(config$clean_column_names)) {
      names(df) <- make_clean_names(names(df))
    }

    # Rename columns (standardize raw input)
    if (!is.null(config$rename) && length(config$rename) > 0) {
      df <- rename_columns(df, config$rename)
    }

    # Parse dates if start_date/end_date columns exist
    if ("start_date" %in% names(df)) {
      df <- mutate(df, start_date = parse_reporting_date(start_date))
    }
    if ("end_date" %in% names(df)) {
      df <- mutate(df, end_date = parse_reporting_date(end_date))
    }

    # Filter rows
    if (length(config$filter) > 0) {
      df <- filter_rows(df, filter_config = config$filter)
    }

    # Convert columns to numeric
    if (length(config$type_convert) > 0) {
      df <- convert_to_numeric(df, config$type_convert)
    }

    # Separate columns (split one column into multiple)
    if (!is.null(config$separate) && length(config$separate) > 0) {
      df <- apply_separate(df, config$separate)
    }

    # Mutate columns (create new columns from existing)
    if (!is.null(config$mutate) && length(config$mutate) > 0) {
      df <- apply_mutate(df, config$mutate)
    }

    df
  })

  # === PIVOT TO LONG FORMAT / COMBINE PERIODS ===
  # For wide-to-long datasets (key_measures), pivot before combining
  if (!is.null(config$pivot_longer) && length(config$pivot_longer) > 0) {
    combined <- tidy_list |>
      pivot_longer_measures(
        pivot_config = config$pivot_longer
      ) |>
      add_period_columns()
  } else {
    # For long-format data (activity_performance), just combine periods
    combined <- list_rbind(tidy_list)
  }

  # === AFTER PIVOTING / AFTER COMBINING DATA ===

  # Clean values in specified columns
  if (length(config$clean_values) > 0) {
    combined <- clean_column_values(combined, column_names = config$clean_values)
  }

  # Select and order final columns
  if (length(config$select) > 0) {
    combined <- select(combined, any_of(config$select))
  }

  combined
}

#' Apply column separation from configuration
#'
#' Splits columns into multiple columns based on regex patterns (like tidyr::separate)
#'
#' @param df Tibble, specifying data to transform
#' @param separate_config List, specifying column separation rules
#'
#' @return Tibble with separated columns added
#'
#' @importFrom dplyr mutate if_else
#' @importFrom rlang .data
#'
#' @keywords internal
apply_separate <- function(df, separate_config) {
  for (col_name in names(separate_config)) {
    col_config <- separate_config[[col_name]]

    if (col_name %in% names(df)) {
      into <- col_config$into
      sep_pattern <- col_config$sep
      remove <- col_config$remove %||% TRUE

      # Backup original column if remove = FALSE
      if (!remove) {
        # Rename original to measure_source (convention)
        df <- mutate(df, measure_source = .data[[col_name]])
      }

      # Extract first part (before separator)
      if (length(into) >= 1) {
        df <- mutate(
          df,
          !!into[1] := sub(sep_pattern, "\\1", .data[[col_name]])
        )
      }

      # Extract second part (after separator)
      if (length(into) >= 2) {
        df <- mutate(
          df,
          !!into[2] := if_else(
            grepl("_", .data[[col_name]]),
            sub(sep_pattern, "\\2", .data[[col_name]]),
            .data[[col_name]]
          )
        )
      }

      # Remove original column if remove = TRUE
      if (remove && col_name %in% names(df)) {
        df[[col_name]] <- NULL
      }
    }
  }

  df
}

#' Apply column mutations from configuration
#'
#' Creates new columns from existing data (like dplyr::mutate)
#'
#' @param df Tibble, specifying data to transform
#' @param mutate_config List, specifying column creation rules
#'
#' @return Tibble with new columns added
#'
#' @importFrom dplyr mutate
#' @importFrom rlang .data
#'
#' @keywords internal
apply_mutate <- function(df, mutate_config) {
  for (new_col in names(mutate_config)) {
    col_config <- mutate_config[[new_col]]

    # Handle date formatting
    if (!is.null(col_config$fn) && col_config$fn == "format") {
      from_col <- col_config$from
      if (from_col %in% names(df)) {
        df <- mutate(
          df,
          !!new_col := format(.data[[from_col]], format = col_config$format)
        )
      }
    }
  }

  df
}

#' Prepare tidy data for any dataset (generic internal function)
#'
#' Orchestrates the complete tidy pipeline: read raw → tidy → cache.
#' This replaces all dataset-specific fetch_and_tidy_* functions.
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying frequency ("annual" or "monthly")
#'
#' @return Tibble with tidy data
#'
#' @importFrom cli cli_process_start cli_process_done
#'
#' @keywords internal
prepare_tidy_data <- function(dataset, period, frequency) {
  raw_df <- read_raw(dataset, period, frequency, use_cache = TRUE)

  raw_data_hash <- calculate_data_hash(raw_df)
  source_info <- get_source_config(dataset, period, frequency)

  raw_data_list <- list(raw_df)
  names(raw_data_list) <- period

  cli_process_start("Tidying {dataset} ({frequency}) for {period}")
  tidy_df <- tidy_dataset(raw_data_list, dataset, frequency)

  write_tidy_cache(
    data = tidy_df,
    dataset = dataset,
    period = period,
    frequency = frequency,
    raw_data_hash = raw_data_hash,
    raw_data_url = source_info$url
  )

  cli_process_done()

  tidy_df
}
