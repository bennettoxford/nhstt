#' Get NHS TT data
#'
#' Load tidied NHS Talking Therapies data from cache. After running
#' [nhstt_setup()], datasets can also be accessed directly by name
#' (e.g., `key_measures`) instead of using this function.
#'
#' @param dataset Character, specifying which dataset to load.
#'   Use [nhstt_info()] to see options.
#'   Default is "key_measures".
#'
#' @return A tibble containing the requested dataset
#' @keywords internal
nhstt_data <- function(dataset = "key_measures") {
  if (!is_setup()) {
    cli::cli_abort(c(
      "Data not found",
      "i" = "Run {.code nhstt_setup()} to download and process the data",
      "i" = "This will take several minutes depending on your connection"
    ))
  }

  cache_dir <- get_cache_dir()
  configs <- get_dataset_configs()

  if (!dataset %in% names(configs)) {
    cli::cli_abort(c(
      "Unknown dataset: {.val {dataset}}",
      "i" = "Available datasets: {.val {names(configs)}}",
      "i" = "Run {.code nhstt_info()} to see all options"
    ))
  }

  config <- configs[[dataset]]
  file_path <- file.path(cache_dir, config$output_filename)

  if (!file.exists(file_path)) {
    cli::cli_abort(c(
      "Dataset {.field {dataset}} not found",
      "i" = "Run {.code nhstt_setup(datasets = '{dataset}')} to download it"
    ))
  }

  cli::cli_alert_info("Loading {.field {dataset}} dataset from cache")
  df <- readRDS(file_path)

  # Ensure it's a tibble
  tibble::as_tibble(df)
}

#' Check if package data is set up
#'
#' @return Logical, returns TRUE if NHS TT data is set up, FALSE otherwise
#' @keywords internal
is_setup <- function() {
  cache_dir <- get_cache_dir()
  file.exists(get_cache_index_path(cache_dir))
}

#' Get package cache directory
#'
#' @return Character, the path to the cache directory
#' @keywords internal
get_cache_dir <- function() {
  tools::R_user_dir("nhstt", which = "cache")
}
