#' Setup R package and download NHS TT reports
#'
#' Downloads and tidies NHS Talking Therapies data for all available periods.
#' Run once to initialise the package data. After setup, datasets can be accessed
#' directly by name (e.g., `key_measures`).
#'
#' @param datasets Character vector, specifying which datasets to process.
#'   Available datasets can be listed with [nhstt_info()].
#'   Default includes all four main datasets.
#' @param force Logical, specifying whether to re-download even if data exists.
#'   Default is FALSE.
#'
#' @return Invisible character, the path to cache directory
#' @export
#'
#' @examples
#' \donttest{
#' # Download all default datasets (recommended)
#' # nhstt_setup()
#'
#' # Download specific datasets only
#' nhstt_setup(datasets = c("key_measures"))
#'
#' # After setup, access datasets directly
#' key_measures
#' 
#' }
nhstt_setup <- function(datasets = c(
                          "key_measures",
                          "medication_status",
                          "therapy_type",
                          "effect_size"
                        ),
                        force = FALSE) {
  cache_dir <- get_cache_dir()

  # Validate datasets
  available_datasets <- names(get_dataset_configs())
  invalid_datasets <- setdiff(datasets, available_datasets)
  if (length(invalid_datasets) > 0) {
    cli::cli_abort(c(
      "Invalid datasets: {.val {invalid_datasets}}",
      "i" = "Available datasets: {.val {available_datasets}}",
      "i" = "Run {.code nhstt_info()} to see options"
    ))
  }

  # Get configs for requested datasets
  configs <- get_dataset_configs()[datasets]

  # Check which datasets are missing or need updating
  datasets_to_update <- character()

  for (dataset in datasets) {
    config <- configs[[dataset]]
    file_path <- file.path(cache_dir, config$output_filename)

    needs_update <- FALSE

    if (!file.exists(file_path)) {
      needs_update <- TRUE
    } else if (!force) {
      # Check if version has changed
      cache_index <- get_cache_index()
      if (!is.null(cache_index) && !is.null(cache_index$datasets[[dataset]])) {
        cached_version <- cache_index$datasets[[dataset]]$version
        if (cached_version != config$version) {
          needs_update <- TRUE
        }
      }
    } else {
      needs_update <- TRUE
    }

    if (needs_update) {
      datasets_to_update <- c(datasets_to_update, dataset)
    }
  }

  # Always show title first
  cli::cli_h1("NHS Talking Therapies data setup")

  # Check if any work needs to be done
  if (!force && length(datasets_to_update) == 0) {
    fully_cached <- datasets
    cli::cli_alert_success("All requested dataset{?s} already downloaded: {.val {fully_cached}}")
    cli::cli_alert_info("Access data with {.code {datasets[1]}}")
    return(invisible(cache_dir))
  }

  # Show what will be done
  fully_cached <- setdiff(datasets, datasets_to_update)
  if (length(fully_cached) > 0) {
    cli::cli_alert_success("Already downloaded: {.val {fully_cached}}")
  }
  if (length(datasets_to_update) > 0) {
    cli::cli_alert_info("Downloading: {.val {datasets_to_update}}")
  }

  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  # Group datasets by source type
  configs_to_update <- configs[datasets_to_update]
  by_source <- split(configs_to_update, purrr::map_chr(configs_to_update, "source_type"))

  # Download data for each source type
  all_raw_data <- list()

  for (source_type in names(by_source)) {
    source_configs <- by_source[[source_type]]

    # Get ALL available periods for this source
    all_periods <- get_available_periods(source_type)

    # Download data
    cli::cli_progress_step(
      "Downloading and extracting {length(all_periods)} archive{?s}",
      msg_done = "Downloaded and extracted {length(all_periods)} archive{?s}"
    )

    source_links <- get_source_links(source_type)

    raw_data <- purrr::map(names(source_links), function(period) {
      url <- source_links[[period]]
      config <- source_configs[[1]]
      download_data_by_type(url, source_type, config)
    }, .progress = list(
      type = "iterator",
      format = "  {cli::pb_bar} {cli::pb_current}/{cli::pb_total} | {cli::pb_eta}",
      clear = FALSE
    ))

    names(raw_data) <- names(source_links)
    all_raw_data[[source_type]] <- raw_data
    cli::cli_progress_done()
  }

  # Process each dataset
  for (dataset in datasets_to_update) {
    cli::cli_progress_step(
      "Tidying {.field {dataset}} dataset",
      msg_done = "Tidied {.field {dataset}} dataset"
    )

    config <- configs[[dataset]]
    source_type <- config$source_type

    # Get raw data for this source type
    raw_data <- all_raw_data[[source_type]]

    # Tidy the dataset
    df_tidy <- config$tidy_fn(raw_data, config)

    # Save as RDS with compression
    saveRDS(
      df_tidy,
      file.path(cache_dir, config$output_filename),
      compress = "xz"
    )
    cli::cli_progress_done()
  }

  # Update metadata with per-dataset information
  update_cache_index(cache_dir, configs, datasets_to_update)

  # Show completion message with usage info
  files <- list.files(cache_dir, full.names = TRUE, pattern = "\\.rds$")
  files <- files[!grepl("cache_index\\.json$", files)]
  total_size <- sum(file.info(files)$size, na.rm = TRUE)

  cli::cli_alert_success(
    "Setup complete! Access data with {.code {datasets_to_update[1]}}"
  )
  cli::cli_alert_info("Data cached in {.path {cache_dir}} ({format(total_size / 1024^2, digits = 1)} MB)")

  invisible(cache_dir)
}

#' Clear downloaded data
#'
#' @param confirm Logical, specifying whether to require confirmation before deletion.
#'   Default is TRUE.
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \donttest{
#' nhstt_clear_download_cache(confirm = FALSE)
#' }
nhstt_clear_download_cache <- function(confirm = TRUE) {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    cli::cli_alert_info("No downloaded data found on disk")
    return(invisible(NULL))
  }

  if (confirm) {
    cli::cli_alert_warning("This will delete all downloaded data from disk:")
    cli::cli_alert_warning("{.path {cache_dir}}")
    response <- readline("Delete all downloaded data? (yes/no): ")
    if (tolower(response) != "yes") {
      cli::cli_alert_info("Cancelled")
      return(invisible(NULL))
    }
  }

  unlink(cache_dir, recursive = TRUE)
  cli::cli_alert_success("Downloaded data cleared from disk")
  invisible(NULL)
}
