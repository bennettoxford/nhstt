test_that("tests use temporary cache directory", {
  cache_dir <- get_cache_dir()
  test_cache_env <- Sys.getenv("NHSTT_TEST_CACHE_DIR")

  # Verify we're using test cache, not real cache
  expect_true(nzchar(test_cache_env))
  expect_equal(cache_dir, test_cache_env)
  expect_match(cache_dir, "nhstt_test_cache")
})

test_that("cache directory is created", {
  cache_dir <- get_cache_dir()

  expect_type(cache_dir, "character")
  expect_true(dir.exists(cache_dir))
})

test_that("raw data directory is created", {
  raw_dir <- get_raw_cache_dir("annual")

  expect_type(raw_dir, "character")
  expect_true(dir.exists(raw_dir))
  expect_match(raw_dir, "raw/annual")
})

test_that("tidy cache directory is created", {
  tidy_dir <- get_tidy_cache_dir("key_measures", "annual")

  expect_type(tidy_dir, "character")
  expect_true(dir.exists(tidy_dir))
  expect_match(tidy_dir, "tidy/annual/key_measures")
})

test_that("raw_path is constructed correctly", {
  # Archives are extracted and stored as parquet
  zip_path <- get_raw_cache_path("key_measures", "2023-24", "annual")
  rar_path <- get_raw_cache_path("key_measures", "2018-19", "annual")
  csv_path <- get_raw_cache_path("activity_performance", "2025-09", "monthly")

  # All should be stored using the current default (parquet)
  expect_match(zip_path, "2023-24_key_measures\\.parquet$")
  expect_match(rar_path, "2018-19_key_measures\\.parquet$")
  expect_match(csv_path, "2025-09_activity_performance\\.parquet$")
})

test_that("tidy_cache_path includes period and version", {
  cache_path <- get_tidy_cache_path("key_measures", "2023-24", "annual")

  expect_match(cache_path, "2023-24_v.*\\.parquet$")
  expect_match(cache_path, "key_measures")
})

test_that("get_raw_cache_path validates dataset", {
  expect_error(
    get_raw_cache_path("invalid_dataset", "2023-24", "annual"),
    "Invalid dataset"
  )
})

test_that("get_raw_cache_path validates frequency", {
  expect_error(
    get_raw_cache_path("key_measures", "2023-24", "invalid"),
    "Invalid frequency"
  )
})

# Cache existence tests --------------------------------------------------------

test_that("raw_cache_exists returns FALSE for non-existent file", {
  # Use valid period that hasn't been downloaded
  # Test cache is empty by default, so file won't exist
  exists <- raw_cache_exists("key_measures", "2017-18", "annual")

  expect_false(exists)
})

test_that("tidy_cache_exists returns FALSE for non-existent file", {
  # Use valid period that hasn't been tidied
  # Test cache is empty by default, so file won't exist
  exists <- tidy_cache_exists("key_measures", "2017-18", "annual")

  expect_false(exists)
})

# cache_info tests -------------------------------------------------------------

test_that("cache_info returns invisibly", {
  result <- cache_info()

  expect_type(result, "list")
  expect_true("cache_dir" %in% names(result))
  expect_true("total_size" %in% names(result))
})

test_that("cache_info shows cache directory", {
  result <- cache_info()

  expect_true(dir.exists(result$cache_dir))
})

# clear_cache tests ------------------------------------------------------------

test_that("clear_cache validates type parameter", {
  expect_error(
    clear_cache(type = "invalid"),
    "Invalid type"
  )
})

test_that("clear_cache accepts valid types", {
  expect_invisible(clear_cache(type = "raw"))
  expect_invisible(clear_cache(type = "tidy"))
  expect_invisible(clear_cache(type = "all"))
})

test_that("clear_cache removes initialization marker when type is all", {
  cache_dir <- get_cache_dir()
  marker_file <- file.path(cache_dir, ".nhstt_initialized")

  # Create marker if it doesn't exist
  if (!file.exists(marker_file)) {
    file.create(marker_file)
  }

  # Clear all cache
  clear_cache(type = "all")

  # Marker should be removed
  expect_false(file.exists(marker_file))
})

test_that("clear_cache keeps initialization marker when type is raw", {
  cache_dir <- get_cache_dir()
  marker_file <- file.path(cache_dir, ".nhstt_initialized")

  # Create marker
  file.create(marker_file)

  # Clear only raw
  clear_cache(type = "raw")

  # Marker should still exist
  expect_true(file.exists(marker_file))
})

test_that("clear_cache keeps initialization marker when type is tidy", {
  cache_dir <- get_cache_dir()
  marker_file <- file.path(cache_dir, ".nhstt_initialized")

  # Create marker
  file.create(marker_file)

  # Clear only tidy
  clear_cache(type = "tidy")

  # Marker should still exist
  expect_true(file.exists(marker_file))
})

# Raw downloads metadata tests ---------------------------------------------

test_that("write_raw_downloads_json creates metadata file", {
  frequency <- "annual"
  json_path <- get_raw_downloads_json_path(frequency)

  # Write metadata (archives are extracted and stored as parquet)
  write_raw_downloads_json(
    dataset = "key_measures",
    period = "2023-24",
    frequency = frequency,
    url = "https://example.com/data.zip",
    source_format = "zip",
    storage_format = "parquet",
    raw_data_hash = "abc123",
    file_size = 1024
  )

  expect_true(file.exists(json_path))
})

test_that("read_raw_downloads_json reads metadata correctly", {
  frequency <- "annual"

  # Write metadata first (archives are extracted and stored as parquet)
  write_raw_downloads_json(
    dataset = "key_measures",
    period = "2023-24",
    frequency = frequency,
    url = "https://example.com/data.zip",
    source_format = "zip",
    storage_format = "parquet",
    raw_data_hash = "abc123",
    file_size = 1024
  )

  # Read it back
  metadata <- read_raw_downloads_json(frequency)

  expect_type(metadata, "list")
  expect_true(length(metadata) > 0)
  expect_true("key_measures" %in% names(metadata))
  expect_true("2023-24" %in% names(metadata$key_measures))
  expect_equal(metadata$key_measures$`2023-24`$source_format, "zip")
  expect_equal(metadata$key_measures$`2023-24`$storage_format, "parquet")
  expect_equal(
    metadata$key_measures$`2023-24`$url,
    "https://example.com/data.zip"
  )
  expect_equal(metadata$key_measures$`2023-24`$data_hash, "abc123")
})

test_that("cache_info shows storage format", {
  # Write some metadata (archives are extracted and stored as parquet)
  write_raw_downloads_json(
    dataset = "key_measures",
    period = "2023-24",
    frequency = "annual",
    url = "https://example.com/data.zip",
    source_format = "zip",
    storage_format = "parquet",
    raw_data_hash = "abc123",
    file_size = 1024
  )

  result <- cache_info()

  expect_true("raw_downloads" %in% names(result))
  expect_type(result$raw_downloads, "list")
})

test_that("cache_info counts raw downloads", {
  # Write multiple metadata entries (archives are extracted and stored as parquet)
  write_raw_downloads_json(
    dataset = "key_measures",
    period = "2023-24",
    frequency = "annual",
    url = "https://example.com/data1.zip",
    source_format = "zip",
    storage_format = "parquet",
    raw_data_hash = "abc123",
    file_size = 1024
  )

  write_raw_downloads_json(
    dataset = "key_measures",
    period = "2022-23",
    frequency = "annual",
    url = "https://example.com/data2.zip",
    source_format = "zip",
    storage_format = "parquet",
    raw_data_hash = "def456",
    file_size = 2048
  )

  result <- cache_info()

  # Should have raw downloads information
  expect_true("raw_downloads" %in% names(result))
  annual_downloads <- result$raw_downloads$annual
  # Check we have at least one dataset
  expect_true(length(annual_downloads) >= 1)
  # Check key_measures has 2 periods
  expect_true(length(annual_downloads$key_measures) == 2)
  expect_true("2023-24" %in% names(annual_downloads$key_measures))
  expect_true("2022-23" %in% names(annual_downloads$key_measures))
})

test_that("cache_info warns when cache exceeds size limit", {
  cache_dir <- get_cache_dir()
  raw_dir <- file.path(cache_dir, "raw", "annual")
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

  temp_file <- file.path(raw_dir, "large_file.txt")
  dummy_data <- paste(rep("x", 2000000), collapse = "")
  writeLines(dummy_data, temp_file)

  expect_warning(
    cache_info(max_size_mb = 1),
    "Cache size.*exceeds recommended limit"
  )

  unlink(temp_file)
})

test_that("cache_info does not warn when cache is under size limit", {
  cache_dir <- get_cache_dir()
  raw_dir <- file.path(cache_dir, "raw", "annual")
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

  temp_file <- file.path(raw_dir, "small_file.txt")
  writeLines("small content", temp_file)

  expect_no_warning(
    cache_info(max_size_mb = 1000)
  )

  unlink(temp_file)
})
