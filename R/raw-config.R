#' Load raw data configuration from YAML
#'
#' @return List containing parsed raw data configuration
#'
#' @importFrom yaml read_yaml
#' @importFrom cli cli_abort
#'
#' @keywords internal
load_raw_config <- function() {
  config_path <- system.file("config", "raw_config.yml", package = "nhstt")

  if (config_path == "") {
    cli_abort("raw_config.yml not found in package installation")
  }

  config <- read_yaml(config_path)
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
    cli_abort("raw_config.yml must have 'datasets' section at top level")
  }

  datasets <- config$datasets

  if (length(datasets) == 0) {
    cli_abort("raw_config.yml must define at least one dataset")
  }

  # Validate archives section if present
  if ("archives" %in% names(config)) {
    validate_archives(config$archives)
  }

  # Validate each dataset
  for (dataset_name in names(datasets)) {
    validate_dataset_config(dataset_name, datasets[[dataset_name]], config)
  }

  invisible(TRUE)
}

#' Validate archives section
#'
#' @param archives List, specifying archives configuration
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @keywords internal
validate_archives <- function(archives) {
  if (length(archives) == 0) {
    cli_abort("Archives section must define at least one archive")
  }

  for (archive_name in names(archives)) {
    archive_sources <- archives[[archive_name]]

    if (length(archive_sources) == 0) {
      cli_abort("Archive {.val {archive_name}} must have at least one source")
    }

    for (i in seq_along(archive_sources)) {
      source <- archive_sources[[i]]

      # Required fields
      required <- c("period", "url", "format")
      missing <- setdiff(required, names(source))

      if (length(missing) > 0) {
        cli_abort(c(
          "Archive {.val {archive_name}} source {i} missing required fields: {.val {missing}}",
          "i" = "Required fields: {.val {required}}"
        ))
      }

      # Validate format
      valid_formats <- c("zip", "rar", "xlsx")
      if (!source$format %in% valid_formats) {
        cli_abort(c(
          "Archive {.val {archive_name}} source {i} has invalid format: {.val {source$format}}",
          "i" = "Valid formats: {.val {valid_formats}}"
        ))
      }
    }
  }

  invisible(TRUE)
}

#' Validate format-specific source fields
#'
#' @param source List, source configuration
#' @param source_format Character, format type
#' @param dataset_name Character, dataset name for error messages
#' @param source_index Integer, source index for error messages
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @keywords internal
validate_source_format_fields <- function(
  source,
  source_format,
  dataset_name,
  source_index
) {
  # zip/rar archives need csv_file
  if (source_format %in% c("zip", "rar") && !"csv_file" %in% names(source)) {
    cli_abort(
      "Dataset {.val {dataset_name}} source {source_index} must specify csv_file for {.val {source_format}}"
    )
  }

  # xlsx files need sheet and range
  if (source_format == "xlsx") {
    if (!"sheet" %in% names(source)) {
      cli_abort(
        "Dataset {.val {dataset_name}} source {source_index} must specify sheet"
      )
    }
    if (!"range" %in% names(source)) {
      cli_abort(
        "Dataset {.val {dataset_name}} source {source_index} must specify range"
      )
    }
  }

  invisible(TRUE)
}

#' Validate dataset metadata fields
#'
#' @param dataset_name Character, dataset name
#' @param dataset List, dataset configuration
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @keywords internal
validate_dataset_metadata <- function(dataset_name, dataset) {
  # Check required fields
  required_fields <- c(
    "title",
    "version",
    "get_function",
    "frequency",
    "sources"
  )
  missing_fields <- setdiff(required_fields, names(dataset))

  if (length(missing_fields) > 0) {
    cli_abort(c(
      "Dataset {.val {dataset_name}} missing required fields: {.val {missing_fields}}",
      "i" = "Required fields: {.val {required_fields}}"
    ))
  }

  # Validate version format
  if (!grepl("^\\d+\\.\\d+\\.\\d+$", dataset$version)) {
    cli_warn(
      "Dataset {.val {dataset_name}} version {.val {dataset$version}} is not in semantic versioning format (x.y.z)"
    )
  }

  # Validate frequency
  valid_frequencies <- c("annual", "monthly", "live")
  if (!dataset$frequency %in% valid_frequencies) {
    cli_abort(c(
      "Dataset {.val {dataset_name}} has invalid frequency: {.val {dataset$frequency}}",
      "i" = "Valid frequencies: {.val {valid_frequencies}}"
    ))
  }

  invisible(TRUE)
}

#' Validate dataset archive reference
#'
#' @param dataset_name Character, dataset name
#' @param dataset List, dataset configuration
#' @param config List, full configuration for archive lookups
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @keywords internal
validate_dataset_archive <- function(dataset_name, dataset, config) {
  if (!"archive" %in% names(dataset)) {
    return(invisible(TRUE))
  }

  archive_name <- dataset$archive

  if (!"archives" %in% names(config)) {
    cli_abort(c(
      "Dataset {.val {dataset_name}} references archive {.val {archive_name}}, but no archives section exists"
    ))
  }

  if (!archive_name %in% names(config$archives)) {
    cli_abort(c(
      "Dataset {.val {dataset_name}} references unknown archive: {.val {archive_name}}",
      "i" = "Available archives: {.val {names(config$archives)}}"
    ))
  }

  invisible(TRUE)
}

#' Validate dataset sources
#'
#' @param dataset_name Character, dataset name
#' @param dataset List, dataset configuration
#' @param config List, full configuration for archive lookups
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @keywords internal
validate_dataset_sources <- function(dataset_name, dataset, config) {
  sources <- dataset$sources

  if (length(sources) == 0) {
    cli_abort("Dataset {.val {dataset_name}} must have at least one source")
  }

  uses_archive <- "archive" %in% names(dataset)

  for (i in seq_along(sources)) {
    source <- sources[[i]]

    # Period is always required
    if (!"period" %in% names(source)) {
      cli_abort("Dataset {.val {dataset_name}} source {i} must have period")
    }

    # Validate based on whether dataset uses archive
    if (uses_archive) {
      # Archive-based: verify period exists in archive
      archive_name <- dataset$archive
      archive_periods <- vapply(
        config$archives[[archive_name]],
        \(a) a$period,
        character(1)
      )

      if (!source$period %in% archive_periods) {
        cli_abort(c(
          "Dataset {.val {dataset_name}} source {i} references period {.val {source$period}} not in archive {.val {archive_name}}",
          "i" = "Available periods: {.val {archive_periods}}"
        ))
      }

      # Get format from archive
      archive_source <- config$archives[[archive_name]][[
        which(archive_periods == source$period)
      ]]
      source_format <- archive_source$format
    } else {
      # Direct download: validate required fields
      source_required <- c("period", "url", "format")
      source_missing <- setdiff(source_required, names(source))

      if (length(source_missing) > 0) {
        cli_abort(c(
          "Dataset {.val {dataset_name}} source {i} missing required fields: {.val {source_missing}}",
          "i" = "Required fields: {.val {source_required}}"
        ))
      }

      # Validate format
      valid_formats <- c("csv", "zip", "rar", "xlsx", "api")
      if (!source$format %in% valid_formats) {
        cli_abort(c(
          "Dataset {.val {dataset_name}} source {i} has invalid format: {.val {source$format}}",
          "i" = "Valid formats: {.val {valid_formats}}"
        ))
      }

      source_format <- source$format
    }

    # Validate format-specific fields (common for both archive and direct)
    validate_source_format_fields(source, source_format, dataset_name, i)

    # Validate period format
    freq <- dataset$frequency
    if (freq == "annual" && !grepl("^\\d{4}-\\d{2}$", source$period)) {
      cli_warn(
        "Dataset {.val {dataset_name}} source {i} period {.val {source$period}} does not match annual format (YYYY-YY)"
      )
    }

    if (freq == "monthly" && !grepl("^\\d{4}-\\d{2}$", source$period)) {
      cli_warn(
        "Dataset {.val {dataset_name}} source {i} period {.val {source$period}} does not match monthly format (YYYY-MM)"
      )
    }
  }

  invisible(TRUE)
}

#' Validate individual dataset configuration
#'
#' @param dataset_name Character, specifying dataset name
#' @param dataset List, specifying dataset configuration
#' @param config List, specifying full configuration (for archive lookups)
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @keywords internal
validate_dataset_config <- function(dataset_name, dataset, config) {
  validate_dataset_metadata(dataset_name, dataset)
  validate_dataset_archive(dataset_name, dataset, config)
  validate_dataset_sources(dataset_name, dataset, config)

  invisible(TRUE)
}

#' Validate dataset name
#'
#' @param dataset Character, specifying dataset name
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @keywords internal
validate_dataset <- function(dataset, frequency) {
  # Validate frequency first if provided
  if (!missing(frequency)) {
    validate_frequency(frequency)
  }

  raw_config <- load_raw_config()

  # Check if dataset exists in config
  if (!dataset %in% names(raw_config$datasets)) {
    available_keys <- names(raw_config$datasets)

    # Filter by frequency if provided
    if (!missing(frequency)) {
      available_keys <- Filter(
        \(k) raw_config$datasets[[k]]$frequency == frequency,
        available_keys
      )
    }

    cli_abort(c(
      "Invalid dataset: {.val {dataset}}",
      "i" = "Available datasets for {frequency}: {.val {available_keys}}"
    ))
  }

  # Verify frequency matches if provided
  if (!missing(frequency)) {
    dataset_frequency <- raw_config$datasets[[dataset]]$frequency
    if (dataset_frequency != frequency) {
      cli_abort(c(
        "Dataset {.val {dataset}} has frequency {.val {dataset_frequency}}, not {.val {frequency}}"
      ))
    }
  }

  invisible(TRUE)
}

#' Validate frequency
#'
#' @param frequency Character, specifying report frequency to validate ("annual", "monthly", or "live")
#'
#' @return Invisible TRUE if valid, aborts otherwise
#'
#' @keywords internal
validate_frequency <- function(frequency) {
  valid_frequencies <- c("annual", "monthly", "live")

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
#' @param dataset Character, specifying dataset name (e.g., "key_measures_annual", "activity_performance_monthly")
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
#' @param dataset Character, specifying dataset name
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly")
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return List with url, format, and format-specific fields (csv_file, sheet, range)
#'
#' @importFrom purrr keep
#'
#' @keywords internal
get_source_config <- function(dataset, period, frequency) {
  validate_dataset(dataset, frequency)
  validate_frequency(frequency)
  validate_period(period, dataset, frequency)

  raw_config <- load_raw_config()

  # Navigate to dataset
  dataset_meta <- raw_config$datasets[[dataset]]

  # Find source for this period
  source <- keep(
    dataset_meta$sources,
    \(s) s$period == period
  )[[1]]

  # If dataset uses an archive, resolve the archive URL
  if ("archive" %in% names(dataset_meta)) {
    archive_name <- dataset_meta$archive

    # Get the archive source for this period
    archive_source <- keep(
      raw_config$archives[[archive_name]],
      \(a) a$period == period
    )[[1]]

    # Merge archive info with dataset source
    # Source takes precedence for format-specific fields (csv_file, sheet, range)
    source$url <- archive_source$url
    source$format <- archive_source$format
  }

  source
}

#' List available NHS Talking Therapies reports
#'
#' Returns a tibble with information about available datasets including
#' their time period coverage and frequency
#'
#' @return Tibble with dataset and frequency information (one row per dataset)
#'
#' @importFrom tibble tibble
#' @importFrom purrr map_chr
#'
#' @export
#' @examples
#' available_nhstt_reports()
available_nhstt_reports <- function() {
  raw_config <- load_raw_config()
  all_reports <- list()

  # Iterate through all datasets
  for (dataset_key in names(raw_config$datasets)) {
    dataset_config <- raw_config$datasets[[dataset_key]]

    # Get all periods for this dataset
    periods <- map_chr(dataset_config$sources, "period")
    periods_sorted <- sort(periods)

    all_reports[[length(all_reports) + 1]] <- tibble(
      dataset = dataset_key,
      frequency = dataset_config$frequency,
      title = dataset_config$title,
      get_function = dataset_config$get_function,
      first_period = periods_sorted[1],
      last_period = periods_sorted[length(periods_sorted)],
      n_periods = length(periods),
      version = dataset_config$version
    )
  }

  do.call(rbind, all_reports)
}

#' List available periods for a dataset and frequency
#'
#' @param dataset Character, specifying dataset name
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
  validate_dataset(dataset, frequency)
  validate_frequency(frequency)

  raw_config <- load_raw_config()

  # Navigate to dataset
  dataset_meta <- raw_config$datasets[[dataset]]

  if (is.null(dataset_meta)) {
    cli_abort(c(
      "Dataset {.val {dataset}} with frequency {.val {frequency}} not found",
      "i" = "Check raw_config.yml"
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
#' @param dataset Character, specifying dataset name (e.g., "key_measures_annual", "activity_performance_monthly")
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
#' @param dataset Character, specifying dataset name
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Character version string
#'
#' @keywords internal
get_dataset_version <- function(dataset, frequency) {
  validate_dataset(dataset, frequency)
  validate_frequency(frequency)

  raw_config <- load_raw_config()

  # Navigate to dataset
  raw_config$datasets[[dataset]]$version
}
