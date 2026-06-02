# Config loading tests ---------------------------------------------------------

test_that("load_tidy_sources_config returns a named list", {
  cfg <- load_tidy_sources_config()

  expect_type(cfg, "list")
  expect_true(length(cfg) > 0)
  expect_true(!is.null(names(cfg)))
})

test_that("load_tidy_sources_config includes all four main datasets", {
  cfg <- load_tidy_sources_config()

  expect_true("activity_performance_monthly" %in% names(cfg))
  expect_true("key_measures_annual" %in% names(cfg))
  expect_true("proms_annual" %in% names(cfg))
  expect_true("therapy_position_annual" %in% names(cfg))
})

test_that("each dataset config has version and url fields", {
  cfg <- load_tidy_sources_config()

  for (dataset in names(cfg)) {
    expect_true(
      "version" %in% names(cfg[[dataset]]),
      label = paste(dataset, "has version")
    )
    expect_true(
      "url" %in% names(cfg[[dataset]]),
      label = paste(dataset, "has url")
    )
  }
})

test_that("dataset versions are in semantic versioning format", {
  cfg <- load_tidy_sources_config()

  for (dataset in names(cfg)) {
    expect_match(
      cfg[[dataset]]$version,
      "^\\d+\\.\\d+\\.\\d+$",
      label = paste(dataset, "version format")
    )
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
  cfg <- get_tidy_source_config("activity_performance_monthly")

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

# Cache path tests -------------------------------------------------------------

test_that("get_tidy_source_cache_path returns parquet path for dataset", {
  path <- get_tidy_source_cache_path("activity_performance_monthly")

  expect_type(path, "character")
  expect_match(path, "activity_performance_monthly\\.parquet$")
})

test_that("get_tidy_source_sidecar_path returns json path for dataset", {
  path <- get_tidy_source_sidecar_path("activity_performance_monthly")

  expect_type(path, "character")
  expect_match(path, "activity_performance_monthly\\.json$")
})

test_that("cache paths are inside the cache directory", {
  cache_dir <- get_cache_dir()
  parquet_path <- get_tidy_source_cache_path("key_measures_annual")
  sidecar_path <- get_tidy_source_sidecar_path("key_measures_annual")

  expect_true(startsWith(parquet_path, cache_dir))
  expect_true(startsWith(sidecar_path, cache_dir))
})

# tidy_source_cache_is_current tests ------------------------------------------

test_that("tidy_source_cache_is_current returns FALSE when no files exist", {
  result <- tidy_source_cache_is_current("key_measures_annual", "0.2.0")

  expect_false(result)
})

test_that("tidy_source_cache_is_current returns FALSE when only parquet exists", {
  dataset <- "key_measures_annual"
  parquet_path <- get_tidy_source_cache_path(dataset)

  file.create(parquet_path)
  on.exit(unlink(parquet_path))

  result <- tidy_source_cache_is_current(dataset, "0.2.0")
  expect_false(result)
})

test_that("tidy_source_cache_is_current returns TRUE when version matches", {
  dataset <- "key_measures_annual"
  parquet_path <- get_tidy_source_cache_path(dataset)
  sidecar_path <- get_tidy_source_sidecar_path(dataset)

  file.create(parquet_path)
  jsonlite::write_json(
    list(dataset = dataset, version = "0.2.0"),
    sidecar_path,
    auto_unbox = TRUE
  )
  on.exit({
    unlink(parquet_path)
    unlink(sidecar_path)
  })

  result <- tidy_source_cache_is_current(dataset, "0.2.0")
  expect_true(result)
})

test_that("tidy_source_cache_is_current returns FALSE when version differs", {
  dataset <- "key_measures_annual"
  parquet_path <- get_tidy_source_cache_path(dataset)
  sidecar_path <- get_tidy_source_sidecar_path(dataset)

  file.create(parquet_path)
  jsonlite::write_json(
    list(dataset = dataset, version = "0.1.0"),
    sidecar_path,
    auto_unbox = TRUE
  )
  on.exit({
    unlink(parquet_path)
    unlink(sidecar_path)
  })

  result <- tidy_source_cache_is_current(dataset, "0.2.0")
  expect_false(result)
})

# invalidate_tidy_source_cache tests ------------------------------------------

test_that("invalidate_tidy_source_cache removes parquet and sidecar", {
  dataset <- "key_measures_annual"
  parquet_path <- get_tidy_source_cache_path(dataset)
  sidecar_path <- get_tidy_source_sidecar_path(dataset)

  file.create(parquet_path)
  file.create(sidecar_path)

  invalidate_tidy_source_cache(dataset)

  expect_false(file.exists(parquet_path))
  expect_false(file.exists(sidecar_path))
})

test_that("invalidate_tidy_source_cache is safe when files do not exist", {
  expect_invisible(invalidate_tidy_source_cache("key_measures_annual"))
})

# download_tidy_source tests ---------------------------------------------------

test_that("download_tidy_source writes parquet and sidecar with correct fields", {
  dataset <- "key_measures_annual"
  version <- "0.2.0"
  url <- "https://example.com/test.parquet"

  tmp_parquet <- withr::local_tempfile(fileext = ".parquet")
  arrow::write_parquet(tibble::tibble(x = 1L), tmp_parquet)

  local_mocked_bindings(
    download_with_retry = function(url, dest) file.copy(tmp_parquet, dest),
    .package = "nhstt"
  )

  download_tidy_source(dataset, url, version)

  cache_path <- get_tidy_source_cache_path(dataset)
  sidecar_path <- get_tidy_source_sidecar_path(dataset)
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
  dataset <- "key_measures_annual"
  cache_path <- get_tidy_source_cache_path(dataset)

  local_mocked_bindings(
    download_with_retry = function(url, dest) stop("network error"),
    .package = "nhstt"
  )

  expect_error(
    download_tidy_source(dataset, "https://example.com/test.parquet", "0.2.0"),
    "Failed to download"
  )

  expect_false(file.exists(paste0(cache_path, ".tmp")))
})

test_that("download_tidy_source preserves existing cache when download fails", {
  dataset <- "key_measures_annual"
  cache_path <- get_tidy_source_cache_path(dataset)
  sidecar_path <- get_tidy_source_sidecar_path(dataset)

  arrow::write_parquet(tibble::tibble(x = 1L), cache_path)
  jsonlite::write_json(
    list(dataset = dataset, version = "0.1.0"),
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
    download_tidy_source(dataset, "https://example.com/test.parquet", "0.2.0"),
    "Failed to download"
  )

  expect_true(file.exists(cache_path))
  expect_true(file.exists(sidecar_path))
  expect_equal(jsonlite::read_json(sidecar_path)$version, "0.1.0")
})

# load_tidy_source tests -------------------------------------------------------

test_that("load_tidy_source errors when cache file does not exist", {
  expect_error(
    load_tidy_source("key_measures_annual"),
    "Tidy source cache not found"
  )
})

test_that("load_tidy_source reads a valid parquet file", {
  dataset <- "key_measures_annual"
  cache_path <- get_tidy_source_cache_path(dataset)

  test_data <- tibble::tibble(x = 1:3, y = letters[1:3])
  arrow::write_parquet(test_data, cache_path)
  on.exit(unlink(cache_path))

  result <- load_tidy_source(dataset)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_equal(names(result), c("x", "y"))
})
