fixture_path_legacy_format <- function(filename) {
  test_path("fixtures", "annual-legacy-format", filename)
}

# Add a single fixture CSV into a temporary ZIP file and return the path.
zip_fixture_legacy_format <- function(csv_filename) {
  csv_path <- fixture_path_legacy_format(csv_filename)
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  tmp_zip <- tempfile(fileext = ".zip")

  file.copy(csv_path, file.path(tmp_dir, csv_filename))
  zip(tmp_zip, files = file.path(tmp_dir, csv_filename), flags = "-j")

  withr::defer(
    {
      unlink(tmp_dir, recursive = TRUE)
      unlink(tmp_zip)
    },
    envir = parent.frame()
  )

  tmp_zip
}

# Add multiple fixture CSVs into one temporary ZIP file and return the path.
# Used to test read_legacy_format_zip_breakdowns, which expects a multi-table archive.
zip_multi_fixture_legacy_format <- function(csv_filenames) {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  tmp_zip <- tempfile(fileext = ".zip")

  for (f in csv_filenames) {
    file.copy(fixture_path_legacy_format(f), file.path(tmp_dir, f))
  }
  zip(tmp_zip, files = file.path(tmp_dir, csv_filenames), flags = "-j")

  withr::defer(
    {
      unlink(tmp_dir, recursive = TRUE)
      unlink(tmp_zip)
    },
    envir = parent.frame()
  )

  tmp_zip
}

# ---- read_legacy_format_outcome_csv --------------------------------------------------------

test_that("read_legacy_format_outcome_csv handles 2015-16 ALL_* column naming (religion)", {
  zip <- zip_fixture_legacy_format("table-12b_2015.csv")
  result <- read_legacy_format_outcome_csv(zip, "12b")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2L)
  expect_equal(names(result)[1], "religion")

  baha <- result[grepl("Baha", result$religion), ]
  expect_equal(nrow(baha), 1L)
  expect_equal(baha$count_improvement, 278)
  expect_equal(baha$percentage_improvement, 57.2)
  expect_equal(baha$count_finished_course_treatment, 486)
  expect_equal(baha$count_at_caseness, 421)
  expect_equal(baha$count_not_at_caseness, 54)
  expect_equal(baha$count_recovery, 185)
  expect_equal(baha$count_reliable_recovery, 175)
})

test_that("read_legacy_format_outcome_csv handles 2016-17 NoRelibable typo (ltc)", {
  zip <- zip_fixture_legacy_format("table-14_2016.csv")
  result <- read_legacy_format_outcome_csv(zip, "table-14")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2L)
  expect_equal(names(result)[1], "ltc")

  ltc_row <- result[result$ltc == "LTC", ]
  expect_equal(ltc_row$count_finished_course_treatment, 132507)
  expect_equal(ltc_row$count_improvement, 83799)
  expect_equal(ltc_row$percentage_improvement, 63.2)
  expect_equal(ltc_row$count_no_reliable_change, 38152)
  expect_equal(ltc_row$percentage_no_reliable_change, 28.8)
})

test_that("read_legacy_format_outcome_csv handles 2016-17 AllImprovement column naming (ethnicity)", {
  zip <- zip_fixture_legacy_format("table-9b_2016.csv")
  result <- read_legacy_format_outcome_csv(zip, "9b")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2L)
  expect_equal(names(result)[1], "ethnicity")

  row1 <- result[grepl("Any Other Asian", result$ethnicity), ]
  expect_equal(row1$count_finished_course_treatment, 24081)
  expect_equal(row1$count_improvement, 14711)
  expect_equal(row1$percentage_improvement, 61.1)
  expect_equal(row1$count_at_caseness, 22372)
  expect_equal(row1$count_not_at_caseness, 1674)
})

# ---- read_legacy_format_age_gender_csv -----------------------------------------------------

test_that("read_legacy_format_age_gender_csv returns 5 age bands x 3 genders (2015-16 ALL_* naming)", {
  zip <- zip_fixture_legacy_format("table-8a_2015.csv")
  result <- read_legacy_format_age_gender_csv(zip, "8a")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 15L)
  expect_setequal(result$gender, c("All", "Male", "Female"))
  expect_setequal(
    result$age_group,
    c("Under 16", "16 to 17", "18 to 35", "36 to 64", "65 and over")
  )

  under16_all <- result[
    result$age_group == "Under 16" & result$gender == "All",
  ]
  expect_equal(under16_all$count_referrals_received, 495)
  expect_equal(under16_all$count_finished_course_treatment, 44)

  under16_male <- result[
    result$age_group == "Under 16" & result$gender == "Male",
  ]
  expect_equal(under16_male$count_referrals_received, 137)
})

# ---- read_legacy_format_outcome_xlsx -------------------------------------------------------

test_that("read_legacy_format_outcome_xlsx extracts England block and stops at first CCG row", {
  path <- fixture_path_legacy_format("table-12b_2014.xlsx")
  result <- read_legacy_format_outcome_xlsx(
    path,
    "Sheet1",
    dim_col = "sexual_orientation"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3L)
  expect_equal(names(result)[1], "sexual_orientation")

  het <- result[result$sexual_orientation == "Heterosexual", ]
  expect_equal(het$count_finished_course_treatment, 265833)
  expect_equal(het$count_at_caseness, 238253)
  expect_equal(het$count_not_at_caseness, 26282)
  expect_equal(het$count_improvement, 165303)
  expect_equal(het$percentage_improvement, 62.2)
  expect_equal(het$count_no_reliable_change, 76483)
  expect_equal(het$percentage_no_reliable_change, 28.8)
  expect_equal(het$count_deterioration, 16370)
  expect_equal(het$percentage_deterioration, 6.2)
  expect_equal(het$count_recovery, 126891)
  expect_equal(het$count_reliable_recovery, 120397)
})

# ---- extract_legacy_format_age_gender_breakdowns_wide --------------------------------------

wide_schema <- c(
  "org_type",
  "org_code",
  "org_name",
  "variable_type",
  "variable_a",
  "variable_b"
)

test_that("extract_legacy_format_age_gender_breakdowns_wide returns wide schema with Age Group and Gender rows", {
  ag_data <- tibble::tibble(
    age_group = rep(c("Under 16", "16 to 17"), each = 3),
    gender = rep(c("All", "Male", "Female"), 2),
    count_referrals_received = c(682L, 182L, 392L, 20516L, 6039L, 14173L)
  )
  result <- extract_legacy_format_age_gender_breakdowns_wide(ag_data)

  expect_s3_class(result, "tbl_df")
  expect_true(all(wide_schema %in% names(result)))
  expect_true("count_referrals_received" %in% names(result))
  expect_true(all(c("Age Group", "Gender") %in% result$variable_type))

  age_rows <- result[result$variable_type == "Age Group", ]
  expect_equal(
    age_rows$count_referrals_received[age_rows$variable_a == "Under 16"],
    682
  )

  gender_rows <- result[result$variable_type == "Gender", ]
  expect_equal(
    gender_rows$count_referrals_received[gender_rows$variable_a == "Male"],
    182L + 6039L
  )
  expect_equal(
    gender_rows$count_referrals_received[gender_rows$variable_a == "Female"],
    392L + 14173L
  )
})

test_that("extract_legacy_format_age_gender_breakdowns_wide handles tibbles without count_finished_course_treatment", {
  ag_data <- tibble::tibble(
    age_group = rep(c("Under 16", "16 to 17"), each = 2),
    gender = rep(c("All", "Male"), 2),
    count_referrals_received = c(124L, 124L, 2503L, 2503L)
  )
  result <- extract_legacy_format_age_gender_breakdowns_wide(ag_data)

  expect_false("count_finished_course_treatment" %in% names(result))
  expect_true("count_referrals_received" %in% names(result))
})

test_that("extract_legacy_format_age_gender_breakdowns_wide includes both measure columns when present", {
  ag_data <- tibble::tibble(
    age_group = rep(c("Under 16", "16 to 17"), each = 3),
    gender = rep(c("All", "Male", "Female"), 2),
    count_referrals_received = c(495L, 137L, 358L, 1200L, 400L, 800L),
    count_finished_course_treatment = c(44L, 12L, 32L, 100L, 33L, 67L)
  )
  result <- extract_legacy_format_age_gender_breakdowns_wide(ag_data)

  expect_true("count_referrals_received" %in% names(result))
  expect_true("count_finished_course_treatment" %in% names(result))

  gender_rows <- result[result$variable_type == "Gender", ]
  expect_equal(
    gender_rows$count_finished_course_treatment[
      gender_rows$variable_a == "Male"
    ],
    12L + 33L
  )
})

test_that("extract_legacy_format_age_gender_breakdowns_wide sets England org columns", {
  ag_data <- tibble::tibble(
    age_group = c("Under 16", "16 to 17"),
    gender = c("All", "All"),
    count_referrals_received = c(100L, 200L)
  )
  result <- extract_legacy_format_age_gender_breakdowns_wide(ag_data)

  expect_true(all(result$org_type == "England"))
  expect_true(all(result$org_code == "All"))
  expect_true(all(result$org_name == "All"))
  expect_true(all(is.na(result$variable_b)))
})

# ---- read_legacy_format_row_xlsx -----------------------------------------------

test_that("read_legacy_format_row_xlsx returns numeric vector for known row label", {
  path <- fixture_path_legacy_format("table-12b_2014.xlsx")
  # Text cells (e.g. the label in col 1) become NA with a coercion warning — expected.
  result <- suppressWarnings(read_legacy_format_row_xlsx(
    path,
    "Sheet1",
    "England total"
  ))

  expect_type(result, "double")
  expect_true(length(result) > 0)
})

test_that("read_legacy_format_row_xlsx aborts when row label is not found", {
  path <- fixture_path_legacy_format("table-12b_2014.xlsx")

  expect_error(
    read_legacy_format_row_xlsx(path, "Sheet1", "Not a real label"),
    "not found"
  )
})

# ---- read_legacy_format_zip_breakdowns -----------------------------------------
#
# Fixtures available for multi-table ZIPs:
#   table-8a_2015.csv  → age_gender  (pattern "table-8a")
#   table-9b_2016.csv  → ethnicity   (pattern "9b")
#   table-12b_2015.csv → religion    (pattern "12b")
#   table-14_2016.csv  → ltc         (pattern "table-14")
#
# Not yet covered (needs new multi-table fixtures):
#   sexual_orientation (table-10b), disability (table-11b), imd (table-13b)
#   Per-year extractors (2015-16, 2016-17) need table-1a + table-7a fixtures.
#   XLSX-based years (2014-15, 2013-14, 2012-13) need dedicated XLSX fixtures.
#
# CCG extension: when CCG rows are added, extend each test below to also check
# rows where org_type == "CCG" with the appropriate org_code/org_name values.

all_csv_fixtures <- c(
  "table-8a_2015.csv",
  "table-9b_2016.csv",
  "table-12b_2015.csv",
  "table-14_2016.csv"
)

wide_meta_cols <- c(
  "org_type",
  "org_code",
  "org_name",
  "variable_type",
  "variable_a",
  "variable_b"
)

test_that("read_legacy_format_zip_breakdowns age_gender has correct variable_type and org columns", {
  zip <- zip_multi_fixture_legacy_format(all_csv_fixtures)
  result <- read_legacy_format_zip_breakdowns(zip, "age_gender")

  expect_true(all(wide_meta_cols %in% names(result$age_gender)))
  expect_setequal(
    unique(result$age_gender$variable_type),
    c("Age Group", "Gender")
  )
  expect_true(all(result$age_gender$org_type == "England"))
  expect_true(all(result$age_gender$org_code == "All"))
  expect_true(all(result$age_gender$org_name == "All"))
  expect_true(all(is.na(result$age_gender$variable_b)))
})

test_that("read_legacy_format_zip_breakdowns ethnicity splits variable_a and variable_b", {
  zip <- zip_multi_fixture_legacy_format(all_csv_fixtures)
  result <- read_legacy_format_zip_breakdowns(zip, "ethnicity")

  expect_true(all(wide_meta_cols %in% names(result$ethnicity)))
  expect_true(all(result$ethnicity$variable_type == "Ethnic Group"))
  expect_true(all(result$ethnicity$org_type == "England"))
  expect_true(is.character(result$ethnicity$variable_a))
  expect_true(is.character(result$ethnicity$variable_b))
  expect_false(any(
    grepl(" - ", result$ethnicity$variable_a, fixed = TRUE),
    na.rm = TRUE
  ))
})

test_that("read_legacy_format_zip_breakdowns religion has correct variable_type and no variable_b", {
  zip <- zip_multi_fixture_legacy_format(all_csv_fixtures)
  result <- read_legacy_format_zip_breakdowns(zip, "religion")

  expect_true(all(result$religion$variable_type == "Religion"))
  expect_true(all(result$religion$org_type == "England"))
  expect_true(all(is.na(result$religion$variable_b)))
  expect_true(is.character(result$religion$variable_a))
})

test_that("read_legacy_format_zip_breakdowns ltc has correct variable_type and no variable_b", {
  zip <- zip_multi_fixture_legacy_format(all_csv_fixtures)
  result <- read_legacy_format_zip_breakdowns(zip, "ltc")

  expect_true(all(result$ltc$variable_type == "Long Term Condition Status"))
  expect_true(all(result$ltc$org_type == "England"))
  expect_true(all(is.na(result$ltc$variable_b)))
})

test_that("read_legacy_format_zip_breakdowns returns NULL for unrequested breakdowns", {
  zip <- zip_multi_fixture_legacy_format(all_csv_fixtures)
  result <- read_legacy_format_zip_breakdowns(zip, c("religion", "ltc"))

  expect_null(result$age_gender)
  expect_null(result$ethnicity)
  expect_false(is.null(result$religion))
  expect_false(is.null(result$ltc))
})
