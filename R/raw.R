#' Download data from URL with retry logic
#'
#' @param url Character, specifying URL to download from
#' @param file Character, specifying destination file path
#'
#' @importFrom curl curl_download new_handle handle_setheaders handle_setopt
#' @importFrom utils download.file
#' @importFrom cli cli_alert_warning cli_abort
#'
#' @keywords internal
download_with_retry <- function(url, file) {
  max_attempts <- 3
  for (attempt in seq_len(max_attempts)) {
    result <- tryCatch(
      {
        handle <- curl::new_handle()
        curl::handle_setheaders(
          handle,
          "User-Agent" = "Mozilla/5.0",
          "Accept" = "*/*"
        )
        curl::handle_setopt(handle, http_version = 1L, followlocation = TRUE)

        curl::curl_download(url, file, handle = handle, mode = "wb")
        TRUE
      },
      error = function(e) {
        if (attempt < max_attempts) {
          cli_alert_warning(
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

  cli_abort(c(
    "Failed to download after {max_attempts} attempts",
    "x" = "{.url {url}}"
  ))
}

#' Check if cache file exists
#'
#' @param file_path Character, path to cache file
#' @param use_cache Logical, whether to use cached data if present
#'
#' @return Character path if cache exists and should be used, NULL otherwise
#'
#' @keywords internal
resolve_cache_file <- function(file_path, use_cache) {
  if (!use_cache) {
    return(NULL)
  }

  if (file.exists(file_path)) {
    return(file_path)
  }

  NULL
}

#' Download, parse, and store raw data
#'
#' @param dataset Character, dataset name
#' @param period Character, reporting period
#' @param frequency Character, "annual" or "monthly"
#' @param url Character, source URL
#' @param source_format Character, source format ("csv", "zip", "rar", "xlsx")
#' @param file_path Character, destination path
#' @param csv_pattern Character, regex to locate CSV inside archive (optional)
#' @param sheet Character, sheet name or index for Excel sources (required for Excel sources)
#' @param range Character, Excel cell range (e.g., "A5:H427") for Excel sources (optional)
#'
#' @return Character path to cached file
#'
#' @importFrom cli cli_process_start cli_process_done
#' @importFrom vroom vroom
#' @importFrom arrow write_parquet
#' @importFrom readxl read_excel
#'
#' @keywords internal
download_and_store <- function(
  dataset,
  period,
  frequency,
  url,
  source_format,
  file_path,
  csv_pattern = NULL,
  sheet = NULL,
  range = NULL
) {
  cli_process_start("Downloading {dataset} ({frequency}) for {period}")

  temp_ext <- if (source_format %in% c("zip", "rar")) {
    paste0(".", source_format)
  } else if (source_format == "xlsx") {
    ".xlsx"
  } else {
    ".csv"
  }
  temp_file <- tempfile(fileext = temp_ext)
  on.exit(
    {
      if (file.exists(temp_file)) {
        unlink(temp_file)
      }
    },
    add = TRUE
  )

  download_with_retry(url, temp_file)

  if (identical(source_format, "xlsx") && is.null(sheet)) {
    cli_abort("Excel sources must specify a sheet name or index")
  }

  raw_data <- switch(
    source_format,
    zip = extract_csv_from_archive(temp_file, csv_pattern),
    rar = extract_csv_from_archive(temp_file, csv_pattern),
    csv = vroom(temp_file, show_col_types = FALSE),
    xlsx = read_excel(
      temp_file,
      sheet = sheet,
      range = range,
      col_names = TRUE
    ),
    cli_abort("Unsupported format: {.val {source_format}}")
  )

  write_parquet(raw_data, file_path, compression = "zstd")

  write_raw_downloads_json(
    dataset = dataset,
    period = period,
    frequency = frequency,
    url = url,
    source_format = source_format,
    storage_format = "parquet",
    raw_data_hash = calculate_data_hash(raw_data),
    file_size = file.info(file_path)$size
  )

  cli_process_done()

  file_path
}

#' Download and cache raw data
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures_annual", "activity_performance_monthly")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#' @param use_cache Logical, specifying whether to use cached data if available. Default TRUE
#'
#' @return Character path to cached file
#'
#' @importFrom cli cli_inform cli_process_start cli_process_done
#' @importFrom arrow write_parquet read_parquet
#' @importFrom vroom vroom
#'
#' @keywords internal
download_raw <- function(dataset, period, frequency, use_cache = TRUE) {
  validate_dataset(dataset)
  validate_frequency(frequency)
  validate_period(period, dataset, frequency)

  source_info <- get_source_config(dataset, period, frequency)
  source_format <- source_info$format
  url <- source_info$url

  file_path <- get_raw_cache_path(dataset, period, frequency)

  cached_file <- resolve_cache_file(file_path, use_cache)
  if (!is.null(cached_file)) {
    return(cached_file)
  }

  download_and_store(
    dataset = dataset,
    period = period,
    frequency = frequency,
    url = url,
    source_format = source_format,
    file_path = file_path,
    csv_pattern = source_info$csv_file,
    sheet = source_info$sheet,
    range = source_info$range
  )
}

#' Read raw dataset from cache
#'
#' Downloads (if needed) and reads a single raw dataset file into memory.
#' All data is stored as parquet files (archives are extracted during download).
#'
#' @param dataset Character, specifying dataset name (e.g., "key_measures_annual", "activity_performance_monthly")
#' @param period Character, specifying reporting period (e.g., "2023-24" for annual, "2025-09" for monthly)
#' @param frequency Character, specifying report frequency ("annual" or "monthly")
#' @param use_cache Logical, specifying whether to use cached data if available. Default TRUE
#'
#' @return Tibble with raw data
#'
#' @keywords internal
read_raw <- function(dataset, period, frequency, use_cache = TRUE) {
  file_path <- download_raw(dataset, period, frequency, use_cache)
  read_parquet(file_path)
}

#' Extract CSV from archive using pattern matching
#'
#' @param archive_path Character, specifying path to zip/rar archive
#' @param csv_pattern Character, specifying regex pattern to match CSV filename
#'
#' @return Tibble with raw data
#'
#' @importFrom tools file_ext
#' @importFrom utils unzip
#' @importFrom archive archive_extract
#' @importFrom purrr keep
#'
#' @keywords internal
extract_csv_from_archive <- function(archive_path, csv_pattern) {
  file_ext <- tolower(file_ext(archive_path))
  temp_dir <- tempfile()
  dir.create(temp_dir)
  tryCatch(
    {
      if (file_ext == "zip") {
        unzip(archive_path, exdir = temp_dir)
      } else if (file_ext == "rar") {
        archive_extract(archive_path, dir = temp_dir)
      } else {
        cli_abort(
          "Unsupported file type: {.val {file_ext}}. Only .zip and .rar supported."
        )
      }

      csv_files <- list.files(
        temp_dir,
        pattern = "\\.csv$",
        full.names = TRUE,
        recursive = TRUE,
        ignore.case = TRUE
      )

      if (length(csv_files) == 0) {
        cli_abort("No CSV files found in raw data file")
      }

      matching_file <- keep(
        csv_files,
        \(f) grepl(csv_pattern, basename(f), ignore.case = TRUE)
      )

      if (length(matching_file) == 0) {
        cli_abort(c(
          "No file matching pattern {.val {csv_pattern}} found in raw data file",
          "i" = "Available files: {.file {basename(csv_files)}}"
        ))
      }

      if (length(matching_file) > 1) {
        cli_warn(c(
          "Multiple files match pattern {.val {csv_pattern}}",
          "i" = "Using first match: {.file {basename(matching_file[1])}}"
        ))
      }

      vroom(matching_file[1], show_col_types = FALSE)
    },
    finally = {
      unlink(temp_dir, recursive = TRUE)
    }
  )
}

#' Calculate SHA256 hash of data
#'
#' @param data Data frame or tibble, containing data to hash
#'
#' @return Character hash
#'
#' @importFrom digest digest
#'
#' @keywords internal
calculate_data_hash <- function(data) {
  digest(data, algo = "sha256")
}
