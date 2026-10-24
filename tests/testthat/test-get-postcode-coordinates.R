mock_postcodes_io <- function(req) {
  if (grepl("terminated_postcodes/OLD1AA$", req$url)) {
    return(httr2::response_json(
      body = list(result = list(latitude = 51.5, longitude = -0.1))
    ))
  }
  if (grepl("terminated_postcodes", req$url)) {
    return(httr2::response(status_code = 404))
  }

  httr2::response_json(
    body = list(
      result = list(
        list(
          query = "NG3 6AA",
          result = list(latitude = 52.97, longitude = -1.13)
        ),
        list(query = "OLD 1AA", result = NULL),
        list(query = "GONE 1AA", result = NULL)
      )
    )
  )
}

test_that("get_postcode_coordinates returns coordinates for current postcodes", {
  httr2::local_mocked_responses(mock_postcodes_io)

  result <- suppressWarnings(
    get_postcode_coordinates(c("NG3 6AA", "OLD 1AA", "GONE 1AA"))
  )

  expect_named(result, c("postcode", "latitude", "longitude"))
  expect_equal(result$latitude[result$postcode == "NG3 6AA"], 52.97)
})

test_that("get_postcode_coordinates falls back to terminated postcodes", {
  httr2::local_mocked_responses(mock_postcodes_io)

  result <- suppressWarnings(
    get_postcode_coordinates(c("NG3 6AA", "OLD 1AA", "GONE 1AA"))
  )

  expect_equal(result$latitude[result$postcode == "OLD 1AA"], 51.5)
})

test_that("get_postcode_coordinates warns about postcodes without coordinates", {
  httr2::local_mocked_responses(mock_postcodes_io)

  expect_warning(
    result <- get_postcode_coordinates(c("NG3 6AA", "OLD 1AA", "GONE 1AA")),
    "1 postcode"
  )
  expect_true(is.na(result$latitude[result$postcode == "GONE 1AA"]))
})
