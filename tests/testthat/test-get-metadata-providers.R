mock_measures_annual <- tibble::tibble(
  reporting_period = c("2023-24", "2024-25", "2024-25", "2024-25"),
  org_type = c("Provider", "Provider", "Provider", "England"),
  org_code = c("RXT", "AA5", "RXT", "ENG")
)

mock_measures_quarterly <- tibble::tibble(
  reporting_period = c("2025-26-q3", "2025-26-q4", "2025-26-q4"),
  org_type = c("Provider", "SubICB-Provider", "England"),
  provider_code = c("RXT", "RXT", NA)
)

mock_measures_monthly <- tibble::tibble(
  reporting_period = c("2026-05", "2026-06", "2026-07"),
  group_type = c("Provider", "SubICB/Provider", "England"),
  org_code2 = c("AA5", "AA5", "all")
)

mock_ods_data <- tibble::tibble(
  org_code = c("RXT", "AA5"),
  org_name = c(
    "NOTTINGHAMSHIRE HEALTHCARE NHS FOUNDATION TRUST",
    "TRENT PTS"
  ),
  status = c("Active", "Inactive"),
  start_date = c("2003-04-01", "2002-04-01"),
  end_date = c(NA_character_, "2020-03-31"),
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

local_mock_build_sources <- function(env = parent.frame()) {
  requested_codes <- NULL

  local_mocked_bindings(
    get_measures_annual = function(...) mock_measures_annual,
    get_measures_quarterly = function(...) mock_measures_quarterly,
    get_measures_monthly = function(...) mock_measures_monthly,
    get_ods_data = function(codes, add_names = TRUE) {
      requested_codes <<- codes
      mock_ods_data
    },
    get_postcode_coordinates = function(postcodes) {
      tibble::tibble(postcode = postcodes, latitude = 52.9, longitude = -1.1)
    },
    .env = env
  )

  function() requested_codes
}

test_that("build_metadata_providers looks up each provider in the annual data once", {
  requested_codes <- local_mock_build_sources()

  build_metadata_providers()

  expect_equal(requested_codes(), c("RXT", "AA5"))
})

test_that("build_metadata_providers returns expected columns", {
  local_mock_build_sources()

  result <- build_metadata_providers()

  expect_named(
    result,
    c(
      "org_code",
      "org_name",
      "status",
      "start_date",
      "end_date",
      "postcode",
      "latitude",
      "longitude",
      "town",
      "icb_code",
      "icb_name",
      "region_code",
      "region_name",
      "retrieved_date",
      "annual_last_reported",
      "quarterly_last_reported",
      "monthly_last_reported",
      "annual_latest_period",
      "quarterly_latest_period",
      "monthly_latest_period"
    )
  )
  expect_equal(result$latitude, c(52.9, 52.9))
  expect_equal(unique(result$retrieved_date), Sys.Date())
})

test_that("build_metadata_providers cleans org names", {
  local_mock_build_sources()

  result <- build_metadata_providers()

  expect_equal(
    result$org_name[1],
    "Nottinghamshire Healthcare NHS Foundation Trust"
  )
  expect_equal(result$town[1], "Nottingham")
  expect_equal(result$icb_name[1], "NHS Nottingham and Nottinghamshire")
  expect_equal(result$region_name[1], "NHS England Midlands")
})

test_that("add_provider_reporting adds last and latest periods", {
  result <- add_provider_reporting(
    tibble::tibble(org_code = c("RXT", "AA5", "NEW")),
    mock_measures_annual,
    mock_measures_quarterly,
    mock_measures_monthly
  )

  expect_equal(result$annual_last_reported, c("2024-25", "2024-25", NA))
  expect_equal(result$quarterly_last_reported, c("2025-26-q4", NA, NA))
  expect_equal(result$monthly_last_reported, c(NA, "2026-06", NA))
  expect_equal(unique(result$annual_latest_period), "2024-25")
  expect_equal(unique(result$quarterly_latest_period), "2025-26-q4")
  expect_equal(unique(result$monthly_latest_period), "2026-07")
})

test_that("get_metadata_providers reads the published dataset", {
  version <- get_tidy_source_config("metadata_providers")$version
  cache_path <- get_tidy_source_cache_path("metadata_providers", version)
  sidecar_path <- get_tidy_source_sidecar_path("metadata_providers", version)
  on.exit(unlink(c(cache_path, sidecar_path)))

  mock_data <- tibble::tibble(org_code = "RXT", status = "Active")
  arrow::write_parquet(mock_data, cache_path)
  jsonlite::write_json(
    list(dataset = "metadata_providers", version = version),
    sidecar_path,
    auto_unbox = TRUE
  )

  local_mocked_bindings(
    download_tidy_source = function(...) stop("download should not be called")
  )

  expect_equal(get_metadata_providers(), mock_data)
})
