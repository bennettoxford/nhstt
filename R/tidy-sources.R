#' Load tidy data sources configuration
#'
#' @return List of dataset configurations keyed by dataset name
#'
#' @importFrom yaml read_yaml
#' @importFrom cli cli_abort
#'
#' @keywords internal
load_tidy_sources_config <- function() {
  config_path <- system.file(
    "config",
    "tidy_data_sources.yml",
    package = "nhstt"
  )

  if (config_path == "") {
    cli_abort("tidy_data_sources.yml not found in package installation")
  }

  config <- read_yaml(config_path)

  if (!"datasets" %in% names(config)) {
    cli_abort("tidy_data_sources.yml must have a 'datasets' section")
  }

  sources <- config$datasets
  for (dataset in names(sources)) {
    if (is.null(sources[[dataset]]$url)) {
      sources[[dataset]]$url <- derive_tidy_source_url(
        dataset,
        sources[[dataset]]$version
      )
    }
  }

  sources
}

#' Derive the GitHub Release URL for a tidy source
#'
#' @param dataset Character, dataset name
#' @param version Character, dataset version
#'
#' @return Character URL
#'
#' @keywords internal
derive_tidy_source_url <- function(dataset, version) {
  release_tag <- paste0(gsub("_", "-", dataset), "-v", version)
  paste0(
    "https://github.com/bennettoxford/nhstt/releases/download/",
    release_tag,
    "/",
    dataset,
    ".parquet"
  )
}

#' Get tidy source configuration for a dataset
#'
#' The download URL is derived from the dataset name and version using the
#' GitHub Release tag convention (`{dataset-with-dashes}-v{version}`), which
#' is what `just release` creates. An explicit `url` field in
#' tidy_data_sources.yml overrides the derived URL.
#'
#' @param dataset Character, dataset name (e.g., "activity_performance_monthly")
#'
#' @return List with fields: version, url
#'
#' @importFrom cli cli_abort
#'
#' @keywords internal
get_tidy_source_config <- function(dataset) {
  sources <- load_tidy_sources_config()

  if (!dataset %in% names(sources)) {
    available <- names(sources)
    cli_abort(c(
      "Dataset {.val {dataset}} not found in tidy_data_sources.yml",
      "i" = "Available datasets: {.val {available}}"
    ))
  }

  cfg <- sources[[dataset]]

  if (is.null(cfg$version) || !nzchar(cfg$version)) {
    cli_abort(
      "Dataset {.val {dataset}} in tidy_data_sources.yml has no version"
    )
  }

  cfg
}

#' Get path to pre-built tidy parquet in cache
#'
#' @param dataset Character, dataset name
#'
#' @return Character path
#'
#' @keywords internal
get_tidy_source_cache_path <- function(dataset) {
  tidy_dir <- file.path(get_cache_dir(), "tidy")
  if (!dir.exists(tidy_dir)) {
    dir.create(tidy_dir, recursive = TRUE)
  }
  file.path(tidy_dir, paste0(dataset, ".parquet"))
}

#' Get path to tidy source version sidecar JSON
#'
#' @param dataset Character, dataset name
#'
#' @return Character path
#'
#' @keywords internal
get_tidy_source_sidecar_path <- function(dataset) {
  tidy_dir <- file.path(get_cache_dir(), "tidy")
  if (!dir.exists(tidy_dir)) {
    dir.create(tidy_dir, recursive = TRUE)
  }
  file.path(tidy_dir, paste0(dataset, ".json"))
}

#' Check whether cached tidy source matches the expected version
#'
#' Returns FALSE if the parquet or sidecar is missing, or if the cached version
#' does not match.
#'
#' @param dataset Character, dataset name
#' @param version Character, expected version from tidy_data_sources.yml
#'
#' @return Logical
#'
#' @importFrom jsonlite read_json
#'
#' @keywords internal
tidy_source_cache_is_current <- function(dataset, version) {
  parquet_path <- get_tidy_source_cache_path(dataset)
  sidecar_path <- get_tidy_source_sidecar_path(dataset)

  if (!file.exists(parquet_path) || !file.exists(sidecar_path)) {
    return(FALSE)
  }

  tryCatch(
    {
      sidecar <- read_json(sidecar_path)
      identical(sidecar$version, version)
    },
    error = function(e) FALSE
  )
}

#' Remove stale tidy source cache files
#'
#' Deletes the parquet and sidecar JSON for a dataset so they are re-downloaded
#' on the next call.
#'
#' @param dataset Character, dataset name
#'
#' @return Invisible TRUE
#'
#' @keywords internal
invalidate_tidy_source_cache <- function(dataset) {
  parquet_path <- get_tidy_source_cache_path(dataset)
  sidecar_path <- get_tidy_source_sidecar_path(dataset)

  if (file.exists(parquet_path)) {
    unlink(parquet_path)
  }
  if (file.exists(sidecar_path)) {
    unlink(sidecar_path)
  }

  invisible(TRUE)
}

#' Download pre-built tidy parquet and store in cache
#'
#' @param dataset Character, dataset name
#' @param url Character, download URL
#' @param version Character, dataset version (stored in sidecar)
#'
#' @return Invisible path to cached parquet
#'
#' @importFrom jsonlite write_json
#' @importFrom cli cli_process_start cli_process_done cli_abort
#'
#' @keywords internal
download_tidy_source <- function(dataset, url, version) {
  cache_path <- get_tidy_source_cache_path(dataset)
  sidecar_path <- get_tidy_source_sidecar_path(dataset)

  cli_process_start("Downloading {dataset} (v{version})")

  temp_path <- paste0(cache_path, ".tmp")

  tryCatch(
    {
      download_with_retry(url, temp_path)
      # file.rename() cannot replace an existing file on Windows and
      # signals failure by returning FALSE rather than erroring
      if (!suppressWarnings(file.rename(temp_path, cache_path))) {
        copied <- file.copy(temp_path, cache_path, overwrite = TRUE)
        unlink(temp_path)
        if (!copied) {
          stop("could not move downloaded file into the cache")
        }
      }
    },
    error = function(e) {
      if (file.exists(temp_path)) {
        unlink(temp_path)
      }
      cli_abort(
        c(
          "Failed to download {.val {dataset}}",
          "i" = "URL: {.url {url}}",
          "x" = conditionMessage(e)
        ),
        call = NULL
      )
    }
  )

  write_json(
    list(
      dataset = dataset,
      version = version,
      downloaded_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      url = url
    ),
    sidecar_path,
    auto_unbox = TRUE,
    pretty = TRUE
  )

  cli_process_done()
  invisible(cache_path)
}

#' Load pre-built tidy parquet from cache
#'
#' @param dataset Character, dataset name
#'
#' @return Tibble
#'
#' @importFrom arrow read_parquet
#' @importFrom cli cli_abort
#'
#' @keywords internal
load_tidy_source <- function(dataset) {
  cache_path <- get_tidy_source_cache_path(dataset)

  if (!file.exists(cache_path)) {
    cli_abort("Tidy source cache not found for {.val {dataset}}")
  }

  read_parquet(cache_path)
}
