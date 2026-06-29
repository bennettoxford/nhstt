# Config loading tests ---------------------------------------------------------

test_that("load_tidy_sources_config returns a named list", {
  cfg <- load_tidy_sources_config()

  expect_type(cfg, "list")
  expect_true(length(cfg) > 0)
  expect_true(!is.null(names(cfg)))
})

test_that("load_tidy_sources_config includes all four main datasets", {
  cfg <- load_tidy_sources_config()

  expect_true("measures_monthly" %in% names(cfg))
  expect_true("measures_annual" %in% names(cfg))
  expect_true("proms_annual" %in% names(cfg))
  expect_true("therapy_position_annual" %in% names(cfg))
})

test_that("each dataset config has version, versions, and url fields", {
  cfg <- load_tidy_sources_config()

  for (dataset in names(cfg)) {
    expect_true(
      "version" %in% names(cfg[[dataset]]),
      label = paste(dataset, "has version")
    )
    expect_true(
      "versions" %in% names(cfg[[dataset]]),
      label = paste(dataset, "has versions")
    )
    expect_true(
      "url" %in% names(cfg[[dataset]]),
      label = paste(dataset, "has url")
    )
  }
})

test_that("version is the first entry in versions list", {
  cfg <- load_tidy_sources_config()

  for (dataset in names(cfg)) {
    expect_equal(
      cfg[[dataset]]$version,
      cfg[[dataset]]$versions[[1]],
      label = paste(dataset, "version equals first versions entry")
    )
  }
})

test_that("dataset versions are in semantic versioning format", {
  cfg <- load_tidy_sources_config()

  for (dataset in names(cfg)) {
    for (v in cfg[[dataset]]$versions) {
      expect_match(
        v,
        "^\\d+\\.\\d+\\.\\d+$",
        label = paste(dataset, "version format")
      )
    }
  }
})

test_that("dataset urls point to GitHub Release parquet assets", {
  cfg <- load_tidy_sources_config()

  for (dataset in names(cfg)) {
    expect_match(
      cfg[[dataset]]$url,
      "^https://github\\.com/.*releases/download/",
      label = paste(dataset, "url points to GitHub Release")
    )
    expect_match(
      cfg[[dataset]]$url,
      "\\.parquet$",
      label = paste(dataset, "url ends with .parquet")
    )
  }
})

# get_tidy_source_config tests -------------------------------------------------

test_that("get_tidy_source_config returns config for valid dataset", {
  cfg <- get_tidy_source_config("measures_monthly")

  expect_type(cfg, "list")
  expect_true("version" %in% names(cfg))
  expect_true("url" %in% names(cfg))
})

test_that("get_tidy_source_config errors for unknown dataset", {
  expect_error(
    get_tidy_source_config("not_a_real_dataset"),
    "not found in tidy_data_sources.yml"
  )
})

test_that("get_tidy_source_config returns pinned version config", {
  cfg <- get_tidy_source_config("measures_monthly", version = "0.3.0")

  expect_equal(cfg$version, "0.3.0")
  expect_match(
    cfg$url,
    "activity-performance-monthly-v0\\.3\\.0/activity_performance_monthly\\.parquet"
  )
})

test_that("get_tidy_source_config errors for unknown version", {
  expect_error(
    get_tidy_source_config("measures_monthly", version = "9.9.9"),
    "not available"
  )
})

# available_versions tests -----------------------------------------------------

test_that("available_versions returns character vector", {
  versions <- available_versions("measures_annual")

  expect_type(versions, "character")
  expect_true(length(versions) >= 1)
})

test_that("available_versions newest version is first", {
  versions <- available_versions("measures_monthly")

  expect_equal(
    versions[[1]],
    get_tidy_source_config("measures_monthly")$version
  )
})

test_that("available_versions errors for unknown dataset", {
  expect_error(
    available_versions("not_a_real_dataset"),
    "not found"
  )
})

# Cache path tests -------------------------------------------------------------

test_that("get_tidy_source_cache_path returns versioned parquet path", {
  path <- get_tidy_source_cache_path("measures_monthly", "0.4.0")

  expect_type(path, "character")
  expect_match(path, "measures_monthly_0\\.4\\.0\\.parquet$")
})

test_that("get_tidy_source_sidecar_path returns versioned json path", {
  path <- get_tidy_source_sidecar_path("measures_monthly", "0.4.0")

  expect_type(path, "character")
  expect_match(path, "measures_monthly_0\\.4\\.0\\.json$")
})

test_that("cache paths are inside the cache directory", {
  cache_dir <- get_cache_dir()
  parquet_path <- get_tidy_source_cache_path("measures_annual", "0.2.0")
  sidecar_path <- get_tidy_source_sidecar_path("measures_annual", "0.2.0")

  expect_true(startsWith(parquet_path, cache_dir))
  expect_true(startsWith(sidecar_path, cache_dir))
})

test_that("different versions produce different cache paths", {
  path_v1 <- get_tidy_source_cache_path("measures_annual", "0.1.0")
  path_v2 <- get_tidy_source_cache_path("measures_annual", "0.2.0")

  expect_false(identical(path_v1, path_v2))
})

# tidy_source_cache_is_current tests ------------------------------------------

test_that("tidy_source_cache_is_current returns FALSE when no file exists", {
  result <- tidy_source_cache_is_current("measures_annual", "0.2.0")

  expect_false(result)
})

test_that("tidy_source_cache_is_current returns TRUE when parquet exists", {
  dataset <- "measures_annual"
  version <- "0.2.0"
  parquet_path <- get_tidy_source_cache_path(dataset, version)

  file.create(parquet_path)
  on.exit(unlink(parquet_path))

  expect_true(tidy_source_cache_is_current(dataset, version))
})

test_that("tidy_source_cache_is_current is version-specific", {
  dataset <- "measures_annual"
  parquet_path <- get_tidy_source_cache_path(dataset, "0.2.0")

  file.create(parquet_path)
  on.exit(unlink(parquet_path))

  expect_true(tidy_source_cache_is_current(dataset, "0.2.0"))
  expect_false(tidy_source_cache_is_current(dataset, "0.1.0"))
})

# invalidate_tidy_source_cache tests ------------------------------------------

test_that("invalidate_tidy_source_cache removes parquet and sidecar", {
  dataset <- "measures_annual"
  version <- "0.2.0"
  parquet_path <- get_tidy_source_cache_path(dataset, version)
  sidecar_path <- get_tidy_source_sidecar_path(dataset, version)

  file.create(parquet_path)
  file.create(sidecar_path)

  invalidate_tidy_source_cache(dataset, version)

  expect_false(file.exists(parquet_path))
  expect_false(file.exists(sidecar_path))
})

test_that("invalidate_tidy_source_cache is safe when files do not exist", {
  expect_invisible(invalidate_tidy_source_cache("measures_annual", "0.2.0"))
})

# download_tidy_source tests ---------------------------------------------------

test_that("download_tidy_source writes parquet and sidecar with correct fields", {
  dataset <- "measures_annual"
  version <- "0.2.0"
  url <- "https://example.com/test.parquet"

  tmp_parquet <- withr::local_tempfile(fileext = ".parquet")
  arrow::write_parquet(tibble::tibble(x = 1L), tmp_parquet)

  local_mocked_bindings(
    download_with_retry = function(url, dest) file.copy(tmp_parquet, dest),
    .package = "nhstt"
  )

  download_tidy_source(dataset, url, version)

  cache_path <- get_tidy_source_cache_path(dataset, version)
  sidecar_path <- get_tidy_source_sidecar_path(dataset, version)
  on.exit({
    unlink(cache_path)
    unlink(sidecar_path)
  })

  expect_true(file.exists(cache_path))
  expect_true(file.exists(sidecar_path))

  sidecar <- jsonlite::read_json(sidecar_path)
  expect_equal(sidecar$dataset, dataset)
  expect_equal(sidecar$version, version)
  expect_equal(sidecar$url, url)
  expect_false(is.null(sidecar$downloaded_at))
})

test_that("download_tidy_source cleans up temp file on failure", {
  dataset <- "measures_annual"
  version <- "0.2.0"
  cache_path <- get_tidy_source_cache_path(dataset, version)

  local_mocked_bindings(
    download_with_retry = function(url, dest) stop("network error"),
    .package = "nhstt"
  )

  expect_error(
    download_tidy_source(dataset, "https://example.com/test.parquet", version),
    "Failed to download"
  )

  expect_false(file.exists(paste0(cache_path, ".tmp")))
})

test_that("download_tidy_source preserves existing cache when download fails", {
  dataset <- "measures_annual"
  version <- "0.2.0"
  cache_path <- get_tidy_source_cache_path(dataset, version)
  sidecar_path <- get_tidy_source_sidecar_path(dataset, version)

  arrow::write_parquet(tibble::tibble(x = 1L), cache_path)
  jsonlite::write_json(
    list(dataset = dataset, version = version),
    sidecar_path,
    auto_unbox = TRUE
  )
  on.exit({
    unlink(cache_path)
    unlink(sidecar_path)
  })

  local_mocked_bindings(
    download_with_retry = function(url, dest) stop("network error"),
    .package = "nhstt"
  )

  expect_error(
    download_tidy_source(dataset, "https://example.com/test.parquet", version),
    "Failed to download"
  )

  expect_true(file.exists(cache_path))
})

# load_tidy_source tests -------------------------------------------------------

test_that("load_tidy_source errors when cache file does not exist", {
  expect_error(
    load_tidy_source("measures_annual", "0.2.0"),
    "Tidy source cache not found"
  )
})

test_that("load_tidy_source reads a valid parquet file", {
  dataset <- "measures_annual"
  version <- "0.2.0"
  cache_path <- get_tidy_source_cache_path(dataset, version)

  test_data <- tibble::tibble(x = 1:3, y = letters[1:3])
  arrow::write_parquet(test_data, cache_path)
  on.exit(unlink(cache_path))

  result <- load_tidy_source(dataset, version)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_equal(names(result), c("x", "y"))
})

# Release consistency ----------------------------------------------------------

test_that("every tidy data source version has a GitHub Release URL", {
  sources <- load_tidy_sources_config()

  for (dataset in names(sources)) {
    cfg <- sources[[dataset]]
    expect_true(nzchar(cfg$version), label = paste(dataset, "has a version"))

    for (version in cfg$versions) {
      url <- cfg$version_urls[[version]]
      expect_false(
        is.null(url),
        label = paste(dataset, version, "has a url")
      )
      expect_match(
        url,
        "^https://github\\.com/bennettoxford/nhstt/releases/download/",
        label = paste(dataset, version, "url points to GitHub Release")
      )
      expect_match(
        url,
        "\\.parquet$",
        label = paste(dataset, version, "url ends with .parquet")
      )
    }
  }
})

test_that("tidy data source versions match the raw config versions", {
  sources <- load_tidy_sources_config()
  raw_config <- load_raw_config()

  for (dataset in intersect(names(sources), names(raw_config$datasets))) {
    expect_equal(
      sources[[dataset]]$version,
      raw_config$datasets[[dataset]]$version,
      label = paste("tidy_data_sources.yml version for", dataset),
      expected.label = "raw config version"
    )
  }
})
