#' Load raw data configuration from TOML
#'
#' @return List containing parsed raw data configuration
#'
#' @importFrom RcppTOML parseTOML
#' @importFrom cli cli_abort
#'
#' @keywords internal
load_raw_config <- function() {
  config_path <- system.file("nhstt_data", "raw_config.toml", package = "nhstt")

  if (config_path == "") {
    cli_abort("raw_config.toml not found in package installation")
  }

  config <- parseTOML(config_path)
  validate_raw_config(config)
  config
}

#' Validate raw configuration structure
#'
#' @param config List, specifying parsed raw configuration
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @importFrom cli cli_abort cli_warn
#'
#' @keywords internal
validate_raw_config <- function(config) {
  # Check top-level structure
  if (!"datasets" %in% names(config)) {
    cli_abort("raw_config.toml must have a 'datasets' section")
  }

  datasets <- config$datasets
  if (length(datasets) == 0) {
    cli_abort("raw_config.toml must define at least one dataset")
  }

  # Validate each dataset
  for (dataset_name in names(datasets)) {
    dataset <- datasets[[dataset_name]]

    # Check for frequency sections
    valid_frequencies <- c("annual", "monthly")
    freq_names <- names(dataset)

    if (length(freq_names) == 0) {
      cli_abort(
        "Dataset {.val {dataset_name}} must have at least one frequency (annual/monthly)"
      )
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

      # Required fields
      required_fields <- c("title", "version", "get_function", "sources")
      missing_fields <- setdiff(required_fields, names(freq_config))

      if (length(missing_fields) > 0) {
        cli_abort(c(
          "Dataset {.val {dataset_name}} ({freq}) missing required fields: {.val {missing_fields}}",
          "i" = "Required fields: {.val {required_fields}}"
        ))
      }

      # Validate version format
      if (!grepl("^\\d+\\.\\d+\\.\\d+$", freq_config$version)) {
        cli_warn(
          "Dataset {.val {dataset_name}} ({freq}) version {.val {freq_config$version}} is not in semantic versioning format (x.y.z)"
        )
      }

      # Validate sources
      sources <- freq_config$sources
      if (length(sources) == 0) {
        cli_abort(
          "Dataset {.val {dataset_name}} ({freq}) must have at least one source"
        )
      }

      for (i in seq_along(sources)) {
        source <- sources[[i]]

        # Required source fields
        source_required <- c("period", "url", "format")
        source_missing <- setdiff(source_required, names(source))

        if (length(source_missing) > 0) {
          cli_abort(c(
            "Dataset {.val {dataset_name}} ({freq}) source {i} missing: {.val {source_missing}}",
            "i" = "Required fields: {.val {source_required}}"
          ))
        }

        # Validate format
        valid_formats <- c("csv", "zip", "rar")
        if (!source$format %in% valid_formats) {
          cli_abort(c(
            "Dataset {.val {dataset_name}} ({freq}) source {i} has invalid format: {.val {source$format}}",
            "i" = "Valid formats: {.val {valid_formats}}"
          ))
        }

        # If archived, check for csv_pattern
        if (source$format %in% c("zip", "rar")) {
          if (!"csv_pattern" %in% names(source)) {
            cli_abort(
              "Dataset {.val {dataset_name}} ({freq}) source {i} with format {.val {source$format}} must have csv_pattern"
            )
          }
        }

        # Validate period format
        if (freq == "annual" && !grepl("^\\d{4}-\\d{2}$", source$period)) {
          cli_warn(
            "Dataset {.val {dataset_name}} ({freq}) source {i} period {.val {source$period}} does not match annual format (YYYY-YY)"
          )
        }

        if (freq == "monthly" && !grepl("^\\d{4}-\\d{2}$", source$period)) {
          cli_warn(
            "Dataset {.val {dataset_name}} ({freq}) source {i} period {.val {source$period}} does not match monthly format (YYYY-MM)"
          )
        }
      }
    }
  }

  invisible(TRUE)
}

#' Validate dataset name
#'
#' @param dataset Character, specifying dataset name to validate (e.g., "key_measures", "activity_performance")
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @keywords internal
validate_dataset <- function(dataset) {
  raw_config <- load_raw_config()
  available_datasets <- names(raw_config$datasets)

  if (!dataset %in% available_datasets) {
    cli_abort(c(
      "Invalid dataset: {.val {dataset}}",
      "i" = "Available datasets: {.val {available_datasets}}"
    ))
  }

  invisible(TRUE)
}

#' Validate frequency
#'
#' @param frequency Character, specifying report frequency to validate ("annual" or "monthly")
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @keywords internal
validate_frequency <- function(frequency) {
  valid_frequencies <- c("annual", "monthly")

  if (!frequency %in% valid_frequencies) {
    cli_abort(c(
      "Invalid frequency: {.val {frequency}}",
      "i" = "Must be one of: {.val {valid_frequencies}}"
    ))
  }

  invisible(TRUE)
}

#' Validate period for a dataset and frequency
#'
#' @param period Character, specifying reporting period to validate (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @keywords internal
validate_period <- function(period, dataset, frequency) {
  # Include development periods for validation (allows read_raw() to work)
  available <- list_available_periods(
    dataset,
    frequency,
    include_development = TRUE
  )

  if (!period %in% available) {
    cli_abort(c(
      "Invalid period: {.val {period}}",
      "i" = "Available periods for {dataset} ({frequency}): {.val {available}}"
    ))
  }

  invisible(TRUE)
}

#' Get source configuration for a dataset period
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return List with url, format, csv_pattern
#'
#' @importFrom purrr keep
#'
#' @keywords internal
get_source_config <- function(dataset, period, frequency) {
  validate_dataset(dataset)
  validate_frequency(frequency)
  validate_period(period, dataset, frequency)

  raw_config <- load_raw_config()
  dataset_meta <- raw_config$datasets[[dataset]][[frequency]]

  source <- keep(
    dataset_meta$sources,
    \(s) s$period == period
  )

  source[[1]]
}

#' List available NHS Talking Therapies reports
#'
#' Returns a tibble with information about available datasets including
#' their time period coverage and frequency
#'
#' @return Tibble with dataset and frequency information (one row per dataset-frequency combination)
#'
#' @importFrom tibble tibble
#' @importFrom purrr map_dfr map_chr
#'
#' @export
#' @examples
#' available_nhstt_reports()
available_nhstt_reports <- function() {
  raw_config <- load_raw_config()

  map_dfr(names(raw_config$datasets), function(dataset_name) {
    dataset <- raw_config$datasets[[dataset_name]]

    map_dfr(names(dataset), function(freq) {
      freq_data <- dataset[[freq]]
      get_function <- dataset[[freq]][["get_function"]]
      periods <- map_chr(freq_data$sources, "period")

      tibble(
        dataset = dataset_name,
        frequency = freq,
        title = freq_data$title,
        get_function = get_function,
        first_period = periods[1],
        last_period = periods[length(periods)],
        n_periods = length(periods),
        version = freq_data$version
      )
    })
  })
}

#' List available periods for a dataset and frequency
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#' @param include_development Logical, specifying whether to include periods marked with development = true. Default FALSE
#'
#' @return Character vector of available periods
#'
#' @importFrom purrr map_chr keep
#'
#' @keywords internal
list_available_periods <- function(
  dataset,
  frequency,
  include_development = FALSE
) {
  validate_dataset(dataset)
  validate_frequency(frequency)

  raw_config <- load_raw_config()

  dataset_meta <- raw_config$datasets[[dataset]][[frequency]]

  if (is.null(dataset_meta)) {
    cli_abort(c(
      "Dataset {.val {dataset}} with frequency {.val {frequency}} not found",
      "i" = "Check raw_config.toml"
    ))
  }

  sources <- dataset_meta$sources

  # Filter out development periods unless explicitly requested
  if (!include_development) {
    sources <- keep(sources, \(s) !isTRUE(s$development))
  }

  map_chr(sources, "period")
}

#' Resolve periods argument
#'
#' @param periods Character vector or NULL, specifying periods (e.g., c("2023-24", "2024-25") for annual, c("2025-08", "2025-09") for monthly). Default NULL returns all periods
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Character vector of validated periods
#'
#' @importFrom cli cli_abort
#'
#' @keywords internal
resolve_periods <- function(periods, dataset, frequency) {
  if (is.null(periods)) {
    return(list_available_periods(dataset, frequency))
  }

  available <- list_available_periods(dataset, frequency)
  all_periods <- list_available_periods(
    dataset,
    frequency,
    include_development = TRUE
  )

  invalid <- periods[!periods %in% all_periods]
  development <- periods[periods %in% all_periods & !periods %in% available]

  if (length(invalid) > 0) {
    cli_abort(c(
      "Invalid period{?s}: {.val {invalid}}",
      "i" = "Available periods for {dataset} ({frequency}): {.val {available}}"
    ))
  }

  if (length(development) > 0) {
    cli_abort(c(
      "Period{?s} marked as development: {.val {development}}",
      "i" = "These periods are not yet available for use",
      "i" = "Use {.code read_raw()} via {.code devtools::load_all()} to explore development data"
    ))
  }

  periods
}

#' Get dataset version
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Character version string
#'
#' @keywords internal
get_dataset_version <- function(dataset, frequency) {
  validate_dataset(dataset)
  validate_frequency(frequency)

  raw_config <- load_raw_config()
  raw_config$datasets[[dataset]][[frequency]]$version
}
