#' Get cache directory path
#'
#' @return Character path to cache directory
#'
#' @importFrom tools R_user_dir
#'
#' @keywords internal
get_cache_dir <- function() {
  test_cache <- Sys.getenv("NHSTT_TEST_CACHE_DIR", unset = "")
  if (nzchar(test_cache)) {
    cache_dir <- test_cache
  } else {
    cache_dir <- R_user_dir("nhstt", "cache")
  }

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  cache_dir
}

#' Get raw data cache directory
#'
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Character path to raw data directory
#'
#' @keywords internal
get_raw_cache_dir <- function(frequency) {
  validate_frequency(frequency)

  raw_dir <- file.path(get_cache_dir(), "raw", frequency)

  if (!dir.exists(raw_dir)) {
    dir.create(raw_dir, recursive = TRUE)
  }

  raw_dir
}

#' Get tidy data cache directory for a dataset
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Character path to tidy cache directory
#'
#' @keywords internal
get_tidy_cache_dir <- function(dataset, frequency) {
  validate_dataset(dataset)
  validate_frequency(frequency)

  tidy_dir <- file.path(get_cache_dir(), "tidy", frequency, dataset)

  if (!dir.exists(tidy_dir)) {
    dir.create(tidy_dir, recursive = TRUE)
  }

  tidy_dir
}

#' Get raw data cache path
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Character path to raw data file
#'
#' @keywords internal
get_raw_cache_path <- function(dataset, period, frequency) {
  validate_dataset(dataset)
  validate_frequency(frequency)
  validate_period(period, dataset, frequency)

  filename <- paste0(period, "_", dataset, ".parquet")
  file.path(get_raw_cache_dir(frequency), filename)
}

#' Get versioned tidy cache path
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#' @param dataset_version Character, specifying dataset version (e.g., "1.0.0"). Default NULL
#'
#' @return Character path to cached Parquet file
#'
#' @keywords internal
get_tidy_cache_path <- function(
  dataset,
  period,
  frequency,
  dataset_version = NULL
) {
  if (is.null(dataset_version)) {
    dataset_version <- get_dataset_version(dataset, frequency)
  }
  filename <- paste0(
    period,
    "_v",
    dataset_version,
    ".parquet"
  )
  file.path(get_tidy_cache_dir(dataset, frequency), filename)
}

#' Get package data path
#'
#' Returns path to tidy data shipped with the package.
#' Used as fallback when network downloads fail in GitHub Actions.
#'
#' @details
#' This is a temporary workaround for metadata files hosted on `digital.nhs.uk`,
#' which are blocked in CI environments. This function will likely be removed
#' once data is archived on Zenodo, where we expect no download issues.
#'
#' @param dataset Character, specifying dataset name (e.g., "metadata")
#' @param period Character, specifying reporting period (e.g., "2025-07")
#' @param frequency Character, specifying report frequency ("monthly" or "annual")
#' @param dataset_version Character, specifying dataset version (e.g., "0.1.0"). Default NULL
#'
#' @return Character path to parquet file, or NULL if not available
#'
#' @keywords internal
get_package_data_path <- function(
  dataset,
  period,
  frequency,
  dataset_version = NULL
) {
  if (is.null(dataset_version)) {
    dataset_version <- get_dataset_version(dataset, frequency)
  }

  filename <- paste0(period, "_v", dataset_version, ".parquet")
  path <- system.file(
    "extdata",
    "tidy",
    frequency,
    dataset,
    filename,
    package = "nhstt",
    mustWork = FALSE
  )

  if (file.exists(path)) {
    return(path)
  }

  NULL
}

#' Get dataset version metadata file path
#'
#' Returns the path to the JSON file that stores version metadata for a dataset
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Character path to .versions.json file
#'
#' @keywords internal
get_tidy_versions_json_path <- function(dataset, frequency) {
  file.path(get_tidy_cache_dir(dataset, frequency), ".versions.json")
}

#' Check if tidy cache exists
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Logical
#'
#' @keywords internal
tidy_cache_exists <- function(dataset, period, frequency) {
  cache_path <- get_tidy_cache_path(dataset, period, frequency)
  file.exists(cache_path)
}

#' Check if raw data exists
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Logical
#'
#' @keywords internal
raw_cache_exists <- function(dataset, period, frequency) {
  raw_path <- get_raw_cache_path(dataset, period, frequency)
  file.exists(raw_path)
}

#' Write tidy data to Parquet cache
#'
#' @param data Tibble, containing cleaned data
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#' @param raw_data_hash Character, specifying SHA256 hash of raw data
#' @param raw_data_url Character, specifying URL of source data
#'
#' @importFrom arrow write_parquet
#'
#' @keywords internal
write_tidy_cache <- function(
  data,
  dataset,
  period,
  frequency,
  raw_data_hash,
  raw_data_url
) {
  cache_path <- get_tidy_cache_path(dataset, period, frequency)

  write_parquet(data, cache_path, compression = "zstd")

  write_tidy_versions_json(
    dataset = dataset,
    period = period,
    frequency = frequency,
    raw_data_hash = raw_data_hash,
    raw_data_url = raw_data_url
  )

  invisible(cache_path)
}

#' Load tidy data from Parquet cache
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Tibble
#'
#' @importFrom arrow read_parquet
#' @importFrom cli cli_abort
#'
#' @keywords internal
load_tidy_cache <- function(dataset, period, frequency) {
  cache_path <- get_tidy_cache_path(dataset, period, frequency)

  if (!file.exists(cache_path)) {
    cli_abort("Cache not found for {dataset} {period} ({frequency})")
  }

  read_parquet(cache_path)
}

#' Record version metadata
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#' @param raw_data_hash Character, specifying SHA256 hash
#' @param raw_data_url Character, specifying source URL
#'
#' @importFrom utils packageVersion
#' @importFrom jsonlite read_json write_json
#'
#' @keywords internal
write_tidy_versions_json <- function(
  dataset,
  period,
  frequency,
  raw_data_hash,
  raw_data_url
) {
  version_path <- get_tidy_versions_json_path(dataset, frequency)
  dataset_version <- get_dataset_version(dataset, frequency)
  pkg_version <- as.character(packageVersion("nhstt"))

  if (file.exists(version_path)) {
    versions <- read_json(version_path)
  } else {
    versions <- list(
      dataset = dataset,
      frequency = frequency,
      periods = list()
    )
  }

  if (is.null(versions$periods[[period]])) {
    versions$periods[[period]] <- list(versions = list())
  }

  versions$periods[[period]]$versions[[dataset_version]] <- list(
    created = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
    raw_data_hash = raw_data_hash,
    raw_data_url = raw_data_url,
    dataset_version = dataset_version,
    package_version = pkg_version
  )

  versions$periods[[period]]$current_version <- dataset_version
  versions$periods[[period]]$latest_available <- dataset_version

  temp_path <- paste0(version_path, ".tmp")
  write_json(
    versions,
    temp_path,
    pretty = TRUE,
    auto_unbox = TRUE
  )
  file.rename(temp_path, version_path)

  invisible(version_path)
}

#' Get raw downloads metadata file path
#'
#' Returns the path to the JSON file that stores download metadata for raw data
#'
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return Character path to .downloads.json file
#'
#' @keywords internal
get_raw_downloads_json_path <- function(frequency) {
  file.path(get_raw_cache_dir(frequency), ".downloads.json")
}

#' Read raw downloads metadata
#'
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#'
#' @return List with download metadata, or empty list if file doesn't exist
#'
#' @keywords internal
read_raw_downloads_json <- function(frequency) {
  downloads_path <- get_raw_downloads_json_path(frequency)

  if (file.exists(downloads_path)) {
    read_json(downloads_path)
  } else {
    list()
  }
}

#' Record raw download metadata
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures", "activity_performance")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#' @param url Character, specifying source URL
#' @param source_format Character, specifying original format ("zip", "rar", "csv", "xlsx")
#' @param storage_format Character, specifying how it's stored ("csv", "parquet")
#' @param raw_data_hash Character, specifying SHA256 hash of data
#' @param file_size Numeric, specifying size of stored file in bytes
#'
#' @keywords internal
write_raw_downloads_json <- function(
  dataset,
  period,
  frequency,
  url,
  source_format,
  storage_format,
  raw_data_hash,
  file_size
) {
  downloads_path <- get_raw_downloads_json_path(frequency)

  downloads <- read_raw_downloads_json(frequency)

  if (is.null(downloads[[dataset]])) {
    downloads[[dataset]] <- list()
  }

  downloads[[dataset]][[period]] <- list(
    downloaded_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
    url = url,
    source_format = source_format,
    storage_format = storage_format,
    data_hash = raw_data_hash,
    stored_size = file_size
  )

  temp_path <- paste0(downloads_path, ".tmp")
  write_json(
    downloads,
    temp_path,
    pretty = TRUE,
    auto_unbox = TRUE
  )
  file.rename(temp_path, downloads_path)

  invisible(downloads_path)
}

#' Display cache information
#'
#' Shows information about the nhstt cache, including:
#' - Cache directory location
#' - Size and count of raw annual and monthly downloads
#' - Size of tidy annual and monthly data
#' - Total cache size
#'
#' @details
#' Raw data is stored in parquet format for efficient compression.
#'
#' Warns if cache exceeds recommended size limit (default 1000 MB).
#'
#' @param max_size_mb Numeric, specifying maximum recommended cache size in MB. Default 1000
#'
#' @return Invisibly returns a list with cache information
#'
#' @importFrom cli cli_alert_info cli_dl cli_warn
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Display cache information
#' cache_info()
#'
#' # Check with different size limit
#' cache_info(max_size_mb = 500)
#' }
cache_info <- function(max_size_mb = 1000) {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    return(invisible(NULL))
  }

  all_files <- list.files(cache_dir, recursive = TRUE, full.names = TRUE)
  total_size <- sum(file.info(all_files)$size, na.rm = TRUE)

  raw_annual_dir <- file.path(cache_dir, "raw", "annual")
  raw_annual_size <- 0
  if (dir.exists(raw_annual_dir)) {
    raw_annual_size <- sum(
      file.info(list.files(raw_annual_dir, full.names = TRUE))$size,
      na.rm = TRUE
    )
  }

  raw_monthly_dir <- file.path(cache_dir, "raw", "monthly")
  raw_monthly_size <- 0
  if (dir.exists(raw_monthly_dir)) {
    raw_monthly_size <- sum(
      file.info(list.files(raw_monthly_dir, full.names = TRUE))$size,
      na.rm = TRUE
    )
  }

  tidy_annual_dir <- file.path(cache_dir, "tidy", "annual")
  tidy_annual_size <- 0
  if (dir.exists(tidy_annual_dir)) {
    tidy_annual_files <- list.files(
      tidy_annual_dir,
      recursive = TRUE,
      full.names = TRUE,
      pattern = "\\.parquet$"
    )
    tidy_annual_size <- sum(file.info(tidy_annual_files)$size, na.rm = TRUE)
  }

  tidy_monthly_dir <- file.path(cache_dir, "tidy", "monthly")
  tidy_monthly_size <- 0
  if (dir.exists(tidy_monthly_dir)) {
    tidy_monthly_files <- list.files(
      tidy_monthly_dir,
      recursive = TRUE,
      full.names = TRUE,
      pattern = "\\.parquet$"
    )
    tidy_monthly_size <- sum(file.info(tidy_monthly_files)$size, na.rm = TRUE)
  }

  # Get raw downloads metadata
  raw_annual_meta <- read_raw_downloads_json("annual")
  raw_monthly_meta <- read_raw_downloads_json("monthly")

  # Count raw downloads
  raw_annual_count <- if (length(raw_annual_meta) > 0) {
    sum(sapply(raw_annual_meta, length))
  } else {
    0
  }
  raw_monthly_count <- if (length(raw_monthly_meta) > 0) {
    sum(sapply(raw_monthly_meta, length))
  } else {
    0
  }

  cli_dl(c(
    "Cache directory" = "{.path {cache_dir}}",
    "Raw annual data" = paste0(
      format(structure(raw_annual_size, class = "object_size"), units = "auto"),
      " (",
      raw_annual_count,
      " download",
      if (raw_annual_count != 1) "s" else "",
      ")"
    ),
    "Raw monthly data" = paste0(
      format(
        structure(raw_monthly_size, class = "object_size"),
        units = "auto"
      ),
      " (",
      raw_monthly_count,
      " download",
      if (raw_monthly_count != 1) "s" else "",
      ")"
    ),
    "Tidy annual data" = format(
      structure(tidy_annual_size, class = "object_size"),
      units = "auto"
    ),
    "Tidy monthly data" = format(
      structure(tidy_monthly_size, class = "object_size"),
      units = "auto"
    ),
    "Total size" = format(
      structure(total_size, class = "object_size"),
      units = "auto"
    )
  ))

  size_mb <- total_size / (1024^2)
  if (size_mb > max_size_mb) {
    cli_warn(c(
      "Cache size ({round(size_mb)} MB) exceeds recommended limit ({max_size_mb} MB)",
      "i" = "Consider running {.code cache_clear()} to free space",
      "i" = "Or use {.code cache_clear(\"raw\")} or {.code cache_clear(\"tidy\")} for selective cleanup"
    ))
  }

  invisible(list(
    cache_dir = cache_dir,
    raw_annual_size = raw_annual_size,
    raw_annual_count = raw_annual_count,
    raw_monthly_size = raw_monthly_size,
    raw_monthly_count = raw_monthly_count,
    tidy_annual_size = tidy_annual_size,
    tidy_monthly_size = tidy_monthly_size,
    total_size = total_size,
    raw_downloads = list(
      annual = raw_annual_meta,
      monthly = raw_monthly_meta
    )
  ))
}

#' Clear cache
#'
#' Removes cached data files. By default clears all cache.
#' When clearing "all" cache, also removes the initialization marker,
#' which will trigger the welcome message on next package load.
#'
#' @param type Character, specifying cache type to clear ("all", "raw", or "tidy"). Default "all".
#'
#' @return Invisible TRUE
#'
#' @importFrom cli cli_abort cli_alert_success cli_alert_info
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Clear all cache
#' cache_clear()
#'
#' # Clear only raw data cache
#' cache_clear(type = "raw")
#'
#' # Clear only tidy data cache
#' cache_clear(type = "tidy")
#' }
cache_clear <- function(type = "all") {
  valid_types <- c("all", "raw", "tidy")
  if (!type %in% valid_types) {
    cli_abort(c(
      "Invalid type: {.val {type}}",
      "i" = "Must be one of: {.val {valid_types}}"
    ))
  }

  cache_dir <- get_cache_dir()

  if (type %in% c("raw", "all")) {
    raw_dir <- file.path(cache_dir, "raw")

    if (dir.exists(raw_dir)) {
      unlink(raw_dir, recursive = TRUE)
      cli_alert_success("Cleared raw data cache")
    } else {
      cli_alert_info("No raw data cache to clear")
    }
  }

  if (type %in% c("tidy", "all")) {
    tidy_dir <- file.path(cache_dir, "tidy")

    if (dir.exists(tidy_dir)) {
      unlink(tidy_dir, recursive = TRUE)
      cli_alert_success("Cleared tidy data cache")
    } else {
      cli_alert_info("No tidy data cache to clear")
    }
  }

  if (type == "all") {
    marker_file <- file.path(cache_dir, ".nhstt_initialized")
    if (file.exists(marker_file)) {
      unlink(marker_file)
    }
  }

  invisible(TRUE)
}
