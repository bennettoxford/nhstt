#' Get information about NHS Talking Therapies datasets
#'
#' Shows all available datasets in the package, including their version, description,
#' download status, and whether updates are available.
#'
#' @return Invisible list containing metadata information
#' @export
#'
#' @examples
#' nhstt_info()
nhstt_info <- function() {
  configs <- get_dataset_configs()
  cache_dir <- get_cache_dir()

  # Check if setup has been run
  if (!is_setup()) {
    cli::cli_alert_warning("Data not set up")
    cli::cli_alert_info("Run {.code nhstt_setup()} to download and process data")
    cli::cli_rule()

    # Show available datasets even if not downloaded
    cli::cli_h3("Available datasets")
    for (dataset_name in names(configs)) {
      config <- configs[[dataset_name]]
      cli::cli_alert_info("{.field {dataset_name}} v{config$version}: {config$description}")
    }

    return(invisible(NULL))
  }

  cache_index <- get_cache_index()
  outdated <- check_dataset_versions()

  # Get all RDS files (excluding metadata)
  files <- list.files(cache_dir, recursive = TRUE, full.names = TRUE, pattern = "\\.rds$")
  files <- files[!grepl("cache_index\\.json$", files)]
  total_size <- sum(file.info(files)$size, na.rm = TRUE)

  cli::cli_h3("R package info")
  cli::cli_dl(c(
    "Downloaded data location" = "{.path {cache_dir}}",
    "Package version" = "{.val {cache_index$package_version}}",
    "Total size on disk" = "{format(total_size / 1024^2, digits = 1)} MB"
  ))

  cli::cli_h3("Available datasets")

  # Show info for each dataset
  for (dataset_name in names(configs)) {
    config <- configs[[dataset_name]]

    # Check if dataset is cached
    file_path <- file.path(cache_dir, config$output_filename)

    if (file.exists(file_path) && !is.null(cache_index)) {
      dataset_meta <- cache_index$datasets[[dataset_name]]

      if (!is.null(dataset_meta)) {
        # Check if update available
        if (dataset_name %in% outdated) {
          cli::cli_alert_warning(
            "{.field {dataset_name}} v{dataset_meta$version} \u2192 v{config$version}: {config$description} {.emph [update available]}"
          )
        } else {
          cli::cli_alert_success(
            "{.field {dataset_name}} v{dataset_meta$version}: {config$description} {.emph [downloaded]}"
          )
        }
      } else {
        cli::cli_alert_success(
          "{.field {dataset_name}} v{config$version}: {config$description} {.emph [downloaded]}"
        )
      }
    } else {
      cli::cli_alert_info("{.field {dataset_name}} v{config$version}: {config$description}")
    }
  }

  # Show update suggestion if any datasets are outdated
  if (length(outdated) > 0) {
    cli::cli_rule()
    if (length(outdated) == 1) {
      cli::cli_alert_info("Run {.code nhstt_setup(datasets = '{outdated}')} to download the update")
    } else {
      datasets_str <- paste0('c("', paste(outdated, collapse = '", "'), '")')
      cli::cli_alert_info("Run {.code nhstt_setup(datasets = {datasets_str})} to download updates")
    }
  }

  invisible(cache_index)
}

