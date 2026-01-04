# Tests for developer utilities

# list_archives_periods() ----

test_that("list_archives_periods returns a named list", {
  archives <- list_archives_periods()

  expect_type(archives, "list")
  expect_true(length(archives) > 0)
  expect_true(!is.null(names(archives)))
})

test_that("list_archives_periods includes expected archives", {
  archives <- list_archives_periods()

  expect_true("annual_main" %in% names(archives))
  expect_true("annual_metadata" %in% names(archives))
})

test_that("list_archives_periods returns periods as character vectors", {
  archives <- list_archives_periods()

  # Check annual_main has periods
  expect_type(archives$annual_main, "character")
  expect_true(length(archives$annual_main) > 0)
  expect_true(all(grepl("^\\d{4}-\\d{2}$", archives$annual_main)))
})

test_that("list_archives_periods periods are sorted descending", {
  archives <- list_archives_periods()

  for (archive_name in names(archives)) {
    periods <- archives[[archive_name]]
    expect_equal(periods, sort(periods, decreasing = TRUE))
  }
})

# list_archive_files() ----

test_that("list_archive_files requires archive_name parameter", {
  # This should error because archive_name is required
  expect_error(
    list_archive_files(),
    "missing"
  )
})

test_that("list_archive_files errors for invalid archive", {
  expect_error(
    list_archive_files("invalid_archive"),
    "not found"
  )
})

test_that("list_archive_files error message lists available archives", {
  expect_error(
    list_archive_files("invalid_archive"),
    "Available archives"
  )
})

test_that("list_archive_files errors for invalid period", {
  expect_error(
    list_archive_files("annual_main", periods = "1999-00"),
    "not found"
  )
})

test_that("list_archive_files error message shows available periods", {
  expect_error(
    list_archive_files("annual_main", periods = "1999-00"),
    "Available periods"
  )
})

# read_archive_file() ----

test_that("read_archive_file requires all parameters", {
  # Should error because parameters are required
  expect_error(
    read_archive_file(),
    "missing"
  )
})

test_that("read_archive_file errors for invalid archive", {
  expect_error(
    read_archive_file("invalid_archive", "2024-25", "main"),
    "not found"
  )
})

test_that("read_archive_file errors for invalid period", {
  expect_error(
    read_archive_file("annual_main", "1999-00", "main"),
    "not found"
  )
})

# extract_archive_schemas() ----

test_that("extract_archive_schemas requires archive_name parameter", {
  expect_error(
    extract_archive_schemas(),
    "missing"
  )
})

test_that("extract_archive_schemas errors for invalid archive", {
  expect_error(
    extract_archive_schemas("invalid_archive"),
    "not found"
  )
})

test_that("extract_archive_schemas error message lists available archives", {
  expect_error(
    extract_archive_schemas("invalid_archive"),
    "Available archives"
  )
})

# compare_schemas() ----

test_that("compare_schemas errors if schema file doesn't exist", {
  expect_error(
    compare_schemas("main", schema_file = "nonexistent.csv"),
    "not found"
  )
})

test_that("compare_schemas with custom schema_file doesn't suggest update-schemas", {
  # Custom schema file errors shouldn't suggest update-schemas
  # (that's only for the default package schema)
  expect_error(
    compare_schemas("main", schema_file = "nonexistent.csv"),
    "Schema file not found"
  )
  expect_error(
    compare_schemas("main", schema_file = "nonexistent.csv"),
    "nonexistent.csv"
  )
})
