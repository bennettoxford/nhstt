#' Tidy configuration for activity performance dataset
#'
#' @return List containing tidy configuration for activity_performance dataset
#' @keywords internal
tidy_config_activity_performance <- function() {
  # Common values
  filter_group_types <- c(
    "England",
    "Commissioning Region",
    "Integrated Care Board (ICB)",
    "Provider"
  )

  list(
    monthly = list(
      # Pre-combine: Applied to each period individually
      # Clean column names to snake_case
      clean_column_names = TRUE,

      # Standardize raw column names (handles year-to-year schema changes)
      rename = c(
        reporting_period_start = "start_date",
        reporting_period_end = "end_date",
        measure_value_suppressed = "value"
      ),

      # Row filtering
      filter = list(
        group_type = filter_group_types
      ),

      # Convert columns to numeric (handles NHS suppression markers)
      type_convert = c("value"),

      # Split columns into multiple columns
      separate = list(
        measure_name = list(
          into = c("measure_statistic", "measure_name"),
          sep = "^([^_]+)_(.+)$",
          remove = FALSE # Keep original as measure_source
        )
      ),

      # Create new columns from existing data
      mutate = list(
        reporting_period = list(
          from = "start_date",
          fn = "format",
          format = "%Y-%m"
        )
      ),

      # Post-combine: Applied after combining all periods
      # Clean values in columns
      clean_values = c("measure_name", "measure_statistic"),

      # Final column selection and order
      select = c(
        "reporting_period",
        "start_date",
        "end_date",
        "group_type",
        "org_code1",
        "org_name1",
        "org_code2",
        "org_name2",
        "measure_id",
        "measure_name",
        "measure_statistic",
        "value"
      )
    )
  )
}
