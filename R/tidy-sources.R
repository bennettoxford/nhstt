#' Load tidy data sources configuration
#'
#' Every version entry in tidy_data_sources.yml must have an explicit `url`
#' pointing at the GitHub Release parquet asset.
#'
#' @return List of dataset configurations keyed by dataset name. Each entry
#'   has `version` (latest), `versions` (all known), and `url` (latest).
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
    cfg <- sources[[dataset]]

    if (is.null(cfg$versions) || length(cfg$versions) == 0) {
      cli_abort(
        "Dataset {.val {dataset}} in tidy_data_sources.yml has no versions"
      )
    }

    # Each entry must be a list with version and url fields
    for (i in seq_along(cfg$versions)) {
      entry <- cfg$versions[[i]]
      if (!is.list(entry) || is.null(entry$version)) {
        cli_abort(
          "Dataset {.val {dataset}} version entry {i} must have a 'version' field"
        )
      }
      if (is.null(entry$url)) {
        cli_abort(c(
          "Dataset {.val {dataset}} version {.val {entry$version}} has no 'url' field",
          "i" = "Copy the parquet asset url from the GitHub Release page into tidy_data_sources.yml"
        ))
      }
    }

    latest <- cfg$versions[[1]]
    sources[[dataset]]$version <- latest$version
    sources[[dataset]]$url <- latest$url
    sources[[dataset]]$versions <- sapply(cfg$versions, `[[`, "version")
    version_urls <- setNames(
      sapply(cfg$versions, `[[`, "url"),
      sapply(cfg$versions, `[[`, "version")
    )
    sources[[dataset]]$version_urls <- version_urls
  }

  sources
}

#' Get tidy source configuration for a dataset
#'
#' @param dataset Character, dataset name (e.g., "measures_monthly")
#' @param version Character, specific version to use, or NULL for the latest
#'
#' @return List with fields: version, versions, url
#'
#' @importFrom cli cli_abort
#'
#' @keywords internal
get_tidy_source_config <- function(dataset, version = NULL) {
  sources <- load_tidy_sources_config()

  if (!dataset %in% names(sources)) {
    available <- names(sources)
    cli_abort(c(
      "Dataset {.val {dataset}} not found in tidy_data_sources.yml",
      "i" = "Available datasets: {.val {available}}"
    ))
  }

  cfg <- sources[[dataset]]

  if (!is.null(version)) {
    known <- cfg$versions
    if (!version %in% known) {
      cli_abort(c(
        "Version {.val {version}} is not available for {.val {dataset}}",
        "i" = "Available versions: {.val {known}}"
      ))
    }
    cfg$version <- version
    cfg$url <- cfg$version_urls[[version]]
  }

  cfg
}

#' List available versions for a dataset
#'
#' Returns all data versions that can be pinned with the `version` argument of
#' the corresponding `get_*()` function. Versions are listed newest first.
#'
#' @param dataset Character, dataset name as listed in `tidy_data_sources.yml`
#'   (e.g., `"measures_annual"`, `"measures_monthly"`)
#'
#' @return Character vector of available versions, newest first
#'
#' @export
#'
#' @examples
#' \dontrun{
#' available_versions("measures_annual")
#' available_versions("measures_monthly")
#' }
available_versions <- function(dataset) {
  sources <- load_tidy_sources_config()

  if (!dataset %in% names(sources)) {
    available <- names(sources)
    cli_abort(c(
      "Dataset {.val {dataset}} not found in tidy_data_sources.yml",
      "i" = "Available datasets: {.val {available}}"
    ))
  }

  unlist(sources[[dataset]]$versions)
}

#' Get path to pre-built tidy parquet in cache
#'
#' @param dataset Character, dataset name
#' @param version Character, dataset version
#'
#' @return Character path
#'
#' @keywords internal
get_tidy_source_cache_path <- function(dataset, version) {
  tidy_dir <- file.path(get_cache_dir(), "tidy")
  if (!dir.exists(tidy_dir)) {
    dir.create(tidy_dir, recursive = TRUE)
  }
  file.path(tidy_dir, paste0(dataset, "_", version, ".parquet"))
}

#' Get path to tidy source version sidecar JSON
#'
#' @param dataset Character, dataset name
#' @param version Character, dataset version
#'
#' @return Character path
#'
#' @keywords internal
get_tidy_source_sidecar_path <- function(dataset, version) {
  tidy_dir <- file.path(get_cache_dir(), "tidy")
  if (!dir.exists(tidy_dir)) {
    dir.create(tidy_dir, recursive = TRUE)
  }
  file.path(tidy_dir, paste0(dataset, "_", version, ".json"))
}

#' Check whether a versioned tidy source is cached
#'
#' Returns TRUE if the parquet for this exact dataset+version exists on disk.
#' Because the version is part of the filename, no sidecar comparison is needed.
#'
#' @param dataset Character, dataset name
#' @param version Character, expected version
#'
#' @return Logical
#'
#' @keywords internal
tidy_source_cache_is_current <- function(dataset, version) {
  file.exists(get_tidy_source_cache_path(dataset, version))
}

#' Download pre-built tidy parquet and store in cache
#'
#' @param dataset Character, dataset name
#' @param url Character, download URL
#' @param version Character, dataset version (included in cached filename)
#'
#' @return Invisible path to cached parquet
#'
#' @importFrom jsonlite write_json
#' @importFrom cli cli_process_start cli_process_done cli_abort
#'
#' @keywords internal
download_tidy_source <- function(dataset, url, version) {
  cache_path <- get_tidy_source_cache_path(dataset, version)
  sidecar_path <- get_tidy_source_sidecar_path(dataset, version)

  cli_process_start("Downloading {dataset} (v{version})")

  temp_path <- paste0(cache_path, ".tmp")

  tryCatch(
    {
      download_with_retry(url, temp_path)
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
#' @param version Character, dataset version
#'
#' @return Tibble
#'
#' @importFrom arrow read_parquet
#' @importFrom cli cli_abort
#'
#' @keywords internal
load_tidy_source <- function(dataset, version) {
  cache_path <- get_tidy_source_cache_path(dataset, version)

  if (!file.exists(cache_path)) {
    cli_abort("Tidy source cache not found for {.val {dataset}} (v{version})")
  }

  read_parquet(cache_path)
}
