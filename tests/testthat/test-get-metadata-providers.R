test_that("get_metadata_providers returns expected structure", {
  # Mock get_ods_data to avoid real API calls
  mock_ods_data <- tibble::tibble(
    org_code = c("RXT", "AA5"),
    org_name = c(
      "NOTTINGHAMSHIRE HEALTHCARE NHS FOUNDATION TRUST",
      "TRENT PTS"
    ),
    status = c("Active", "Active"),
    start_date = c("2003-04-01", "2002-04-01"),
    end_date = c(NA_character_, NA_character_),
    postcode = c("NG3 6AA", "NG90 6PA"),
    town = c("NOTTINGHAM", "BEESTON"),
    icb_code = c("15M", "02Q"),
    region_code = c("Y60", "Y60"),
    primary_role = c("RO197", "RO198"),
    icb_name = c(
      "NHS NOTTINGHAM AND NOTTINGHAMSHIRE INTEGRATED CARE BOARD",
      "NHS DERBY AND DERBYSHIRE INTEGRATED CARE BOARD"
    ),
    region_name = c(
      "NHS ENGLAND MIDLANDS COMMISSIONING REGION",
      "NHS ENGLAND MIDLANDS COMMISSIONING REGION"
    )
  )

  with_mocked_bindings(
    get_ods_data = function(codes, add_names = TRUE) mock_ods_data,
    {
      result <- get_metadata_providers(use_cache = FALSE)

      expect_s3_class(result, "tbl_df")
      expect_gt(nrow(result), 0)

      expected_cols <- c(
        "org_code",
        "org_name",
        "status",
        "start_date",
        "end_date",
        "postcode",
        "town",
        "icb_code",
        "icb_name",
        "region_code",
        "region_name"
      )

      expect_true(all(expected_cols %in% names(result)))
    }
  )
})

test_that("get_metadata_providers cleans org names", {
  mock_ods_data <- tibble::tibble(
    org_code = "TEST",
    org_name = "SOME NHS TRUST",
    status = "Active",
    start_date = "2020-01-01",
    end_date = NA_character_,
    postcode = "TE1 1ST",
    town = "test town",
    icb_code = "ICB01",
    region_code = "REG01",
    primary_role = "RO197",
    icb_name = "TEST INTEGRATED CARE BOARD",
    region_name = "TEST COMMISSIONING REGION"
  )

  with_mocked_bindings(
    get_ods_data = function(codes, add_names = TRUE) mock_ods_data,
    {
      result <- get_metadata_providers(use_cache = FALSE)

      expect_equal(result$org_name, "Some NHS Trust")
      expect_equal(result$town, "Test Town")
      expect_equal(result$icb_name, "Test")
      expect_equal(result$region_name, "Test")
    }
  )
})

test_that("get_metadata_providers uses cache when requested", {
  # Create a mock cache file
  cache_dir <- withr::local_tempdir()
  withr::local_envvar(NHSTT_TEST_CACHE_DIR = cache_dir)

  mock_data <- tibble::tibble(
    org_code = "TEST",
    org_name = "Test Provider",
    status = "Active",
    start_date = "2020-01-01",
    end_date = NA_character_,
    postcode = "TE1 1ST",
    town = "Test Town",
    icb_code = "TEST_ICB",
    icb_name = "Test ICB",
    region_code = "TEST_REG",
    region_name = "Test Region"
  )

  cache_path <- file.path(cache_dir, "metadata_providers.parquet")
  arrow::write_parquet(mock_data, cache_path)

  result <- get_metadata_providers(use_cache = TRUE)

  expect_equal(result, mock_data)
})
