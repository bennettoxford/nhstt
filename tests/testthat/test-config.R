# Dataset configurations
test_that("dataset configurations are valid", {
  configs <- get_dataset_configs()

  expect_type(configs, "list")
  expect_gt(length(configs), 0)

  # Each config has required fields
  for (name in names(configs)) {
    config <- configs[[name]]
    expect_true("name" %in% names(config))
    expect_true("description" %in% names(config))
    expect_true("version" %in% names(config))
    expect_equal(config$name, name)
  }
})

# Dataset configuration structure
test_that("annual dataset configs have id_cols and measure_cols", {
  configs <- get_annual_dataset_configs()

  for (name in names(configs)) {
    config <- configs[[name]]
    expect_true("id_cols" %in% names(config), label = paste(name, "has id_cols"))
    expect_true("measure_cols" %in% names(config), label = paste(name, "has measure_cols"))
    expect_type(config$id_cols, "character")
    expect_type(config$measure_cols, "character")
    expect_gt(length(config$id_cols), 0)
    expect_gt(length(config$measure_cols), 0)
  }
})
