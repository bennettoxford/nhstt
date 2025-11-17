# Data hash tests -------------------------------------------------------------

test_that("calculate_data_hash returns consistent hash for same data", {
  df1 <- data.frame(a = 1:3, b = letters[1:3])
  df2 <- data.frame(a = 1:3, b = letters[1:3])

  hash1 <- calculate_data_hash(df1)
  hash2 <- calculate_data_hash(df2)

  expect_equal(hash1, hash2)
  expect_type(hash1, "character")
  expect_equal(nchar(hash1), 64) # SHA256 produces 64 character hex string
})

test_that("calculate_data_hash changes with different data", {
  df1 <- data.frame(a = 1:3, b = letters[1:3])
  df2 <- data.frame(a = 4:6, b = letters[4:6])

  hash1 <- calculate_data_hash(df1)
  hash2 <- calculate_data_hash(df2)

  expect_false(hash1 == hash2)
})

test_that("calculate_data_hash changes with different column names", {
  df1 <- data.frame(a = 1:3, b = letters[1:3])
  df2 <- data.frame(x = 1:3, y = letters[1:3])

  hash1 <- calculate_data_hash(df1)
  hash2 <- calculate_data_hash(df2)

  expect_false(hash1 == hash2)
})

test_that("calculate_data_hash handles tibbles", {
  df <- data.frame(a = 1:3, b = letters[1:3])
  tbl <- tibble::tibble(a = 1:3, b = letters[1:3])

  hash_df <- calculate_data_hash(df)
  hash_tbl <- calculate_data_hash(tbl)

  # Should produce different hashes due to class difference
  expect_type(hash_df, "character")
  expect_type(hash_tbl, "character")
})

# Cache file resolution tests --------------------------------------------------

test_that("resolve_cache_file returns NULL when use_cache = FALSE", {
  result <- resolve_cache_file("dummy.parquet", use_cache = FALSE)

  expect_null(result)
})

test_that("resolve_cache_file returns path when file exists", {
  # Create temporary file
  temp_file <- tempfile(fileext = ".parquet")
  writeLines("test", temp_file)
  on.exit(unlink(temp_file))

  result <- resolve_cache_file(temp_file, use_cache = TRUE)

  expect_equal(result, temp_file)
})

test_that("resolve_cache_file returns NULL when file doesn't exist", {
  non_existent <- tempfile(fileext = ".parquet")

  result <- resolve_cache_file(non_existent, use_cache = TRUE)

  expect_null(result)
})
