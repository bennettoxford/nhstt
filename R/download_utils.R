#' Download file with retry logic
#'
#' @param url URL to download from
#' @param destfile Destination file path
#' @param max_attempts Maximum number of download attempts
#' @param quiet Suppress download progress?
#' @return TRUE if successful
#' @keywords internal
download_with_retry <- function(url, destfile, max_attempts = 3, quiet = TRUE) {
  for (attempt in seq_len(max_attempts)) {
    result <- tryCatch(
      {
        utils::download.file(url, destfile, mode = "wb", quiet = quiet)
        TRUE
      },
      error = function(e) {
        if (attempt < max_attempts) {
          cli::cli_alert_warning(
            "Download failed (attempt {attempt}/{max_attempts}), retrying..."
          )
          Sys.sleep(2^attempt)
        }
        FALSE
      }
    )
    if (result) {
      return(TRUE)
    }
  }

  cli::cli_abort(c(
    "Failed to download after {max_attempts} attempts",
    "x" = "{.url {url}}"
  ))
}

#' Download data based on source type
#'
#' Routes to appropriate download function based on source type.
#'
#' @param url URL to download
#' @param source_type Type of data source
#' @param config Dataset configuration (for metadata)
#' @return Downloaded data
#' @keywords internal
download_data_by_type <- function(url, source_type, config = NULL) {
  switch(source_type,
    "annual_reports" = download_annual_data(url),
    # "metadata" = download_metadata_file(url, config$sheets), # Placeholder for future implementation
    stop("Unknown source type: ", source_type)
  )
}
