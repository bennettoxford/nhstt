#' Cache index path
#'
#' @param cache_dir Cache directory
#' @return Character path to cache index file
#' @keywords internal
get_cache_index_path <- function(cache_dir = get_cache_dir()) {
  file.path(cache_dir, "cache_index.json")
}

#' Retrieve cache index information
#'
#' @return List containing cache metadata or NULL if missing
#' @keywords internal
get_cache_index <- function() {
  cache_path <- get_cache_index_path()

  if (!file.exists(cache_path)) {
    return(NULL)
  }

  index <- jsonlite::read_json(cache_path, simplifyVector = FALSE)

  index$created <- parse_iso_datetime(index$created)
  index$updated <- parse_iso_datetime(index$updated)

  index$datasets <- purrr::imap(index$datasets, function(entry, dataset_name) {
    entry$date_start <- as.Date(entry$date_start)
    entry$date_end <- as.Date(entry$date_end)
    entry$cached_date <- parse_iso_datetime(entry$cached_date)
    entry
  })

  index
}

#' Update cache index after setup
#'
#' @param cache_dir Cache directory path
#' @param configs Dataset configuration list
#' @param datasets_updated Character vector of dataset names updated
#' @return Invisible NULL
#' @keywords internal
update_cache_index <- function(cache_dir, configs, datasets_updated) {
  timestamp <- format_iso_datetime(Sys.time())
  index <- get_cache_index()

  if (is.null(index)) {
    index <- list(
      package_version = get_package_version(),
      created = timestamp,
      updated = timestamp,
      datasets = list()
    )
  } else {
    index$package_version <- get_package_version()
    index$updated <- timestamp
  }

  for (dataset in datasets_updated) {
    config <- configs[[dataset]]
    file_path <- file.path(cache_dir, config$output_filename)
    df <- readRDS(file_path)

    periods <- df$period |>
      unique() |>
      sort()
    start_dates <- df$start_date |>
      unique() |>
      sort()
    end_dates <- df$end_date |>
      unique() |>
      sort()

    index$datasets[[dataset]] <- list(
      version = config$version,
      periods_start = periods[1],
      periods_end = periods[length(periods)],
      periods_count = length(periods),
      date_start = format(as.Date(start_dates[1]), "%Y-%m-%d"),
      date_end = format(as.Date(end_dates[length(end_dates)]), "%Y-%m-%d"),
      cached_date = timestamp
    )
  }

  write_cache_index(index, cache_dir)

  invisible(NULL)
}

#' Write cache index to disk
#'
#' @param index Cache index list
#' @param cache_dir Cache directory
#' @keywords internal
write_cache_index <- function(index, cache_dir = get_cache_dir()) {
  cache_path <- get_cache_index_path(cache_dir)

  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  index_to_write <- index
  index_to_write$created <- format_iso_datetime(index_to_write$created)
  index_to_write$updated <- format_iso_datetime(index_to_write$updated)

  index_to_write$datasets <- purrr::imap(index_to_write$datasets, function(entry, dataset_name) {
    entry$date_start <- format(as.Date(entry$date_start), "%Y-%m-%d")
    entry$date_end <- format(as.Date(entry$date_end), "%Y-%m-%d")
    entry$cached_date <- format_iso_datetime(entry$cached_date)
    entry
  })

  jsonlite::write_json(
    index_to_write,
    cache_path,
    auto_unbox = TRUE,
    pretty = TRUE
  )
}

#' Check for dataset version updates
#'
#' @return Character vector of dataset names with updates available
#' @keywords internal
check_dataset_versions <- function() {
  index <- get_cache_index()
  if (is.null(index)) {
    return(character())
  }

  configs <- get_dataset_configs()
  outdated <- character()

  for (dataset_name in names(index$datasets)) {
    if (dataset_name %in% names(configs)) {
      cached_version <- index$datasets[[dataset_name]]$version
      current_version <- configs[[dataset_name]]$version

      if (!identical(cached_version, current_version)) {
        outdated <- c(outdated, dataset_name)
      }
    }
  }

  outdated
}

#' Format date range for display
#'
#' @param start_date Date or character start date
#' @param end_date Date or character end date
#' @return Character formatted date range
#' @keywords internal
format_date_range <- function(start_date, end_date) {
  start <- as.Date(start_date)
  end <- as.Date(end_date)
  start_str <- format(start, "%b %Y")
  end_str <- format(end, "%b %Y")
  paste(start_str, "-", end_str)
}

#' Format POSIXct as ISO-8601 string
#'
#' @param x POSIXct time
#' @return Character string in UTC
#' @keywords internal
format_iso_datetime <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }

  if (inherits(x, "POSIXt")) {
    return(format(x, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  }

  if (is.character(x)) {
    parsed <- as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    if (!is.na(parsed)) {
      return(format(parsed, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
    }
  }

  format(as.POSIXct(x, tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

#' Parse ISO-8601 string into POSIXct
#'
#' @param x Character string
#' @return POSIXct time in UTC
#' @keywords internal
parse_iso_datetime <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }

  as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}
