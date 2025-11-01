#' Download and extract annual report data
#'
#' Downloads zip/rar files containing CSV files for annual reports.
#' Each archive contains multiple datasets (main, meds, employment, etc.).
#'
#' @param url URL of zip or rar file
#' @return Named list of data frames
#' @keywords internal
download_annual_data <- function(url) {
  file_ext <- tolower(tools::file_ext(url))
  temp_archive <- tempfile(fileext = paste0(".", file_ext))
  temp_dir <- tempfile()

  dir.create(temp_dir)

  tryCatch({
    download_with_retry(url, temp_archive)

    if (file_ext == "zip") {
      utils::unzip(temp_archive, exdir = temp_dir)
    } else if (file_ext == "rar") {
      archive::archive_extract(temp_archive, dir = temp_dir)
    } else {
      cli::cli_abort(c(
        "Unsupported file type: {.val {file_ext}}",
        "i" = "Only {.val .zip} and {.val .rar} are supported"
      ))
    }

    csv_files <- list.files(temp_dir, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)

    if (length(csv_files) == 0) {
      cli::cli_abort(c(
        "No CSV files found in archive",
        "x" = "{.url {url}}"
      ))
    }

    data_list <- purrr::map(
      csv_files,
      ~ readr::read_csv(.x, show_col_types = FALSE)
    )
    names(data_list) <- basename(csv_files)

    data_list
  }, finally = {
    unlink(temp_archive)
    unlink(temp_dir, recursive = TRUE)
  })
}
