#' Tidy configuration for key measures dataset
#'
#' @return List containing tidy configuration for key_measures dataset
#' @keywords internal
tidy_config_key_measures <- function() {
  # Common values
  filter_org_types <- c(
    "England",
    "Commissioning Region",
    "STP",
    "CCG",
    "Provider"
  )
  filter_variable_types <- c(
    "Total",
    "Age Group",
    "Consultation Medium",
    "Disability Type",
    "Ethnic Group",
    "BME Group",
    "Indices of Deprivation Decile",
    "Long Term Condition Status",
    "Mental Health Care Cluster",
    "Gender",
    "Sexual Orientation Type",
    "Problem Descriptor",
    "Presenting Complaint",
    "Stepped Care Pathway",
    "Religion",
    "Waiting Time"
  )

  list(
    annual = list(
      # Pre pivot: Applied to each period individually
      # Clean column names to snake_case
      clean_column_names = TRUE,

      # Row filtering
      filter = list(
        org_type = filter_org_types,
        variable_type = filter_variable_types
      ),

      # Pivot longer
      # Pivot configuration
      pivot_longer = list(
        # ID columns preserved in output
        id_cols = c(
          "org_type",
          "org_code",
          "org_name",
          "variable_type",
          "variable_a",
          "variable_b"
        ),
        # Measure columns to pivot
        measure_cols = c(
          "count_referrals_received",
          "count_finished_course_treatment",
          "count_at_caseness",
          "count_not_at_caseness",
          "count_improvement",
          "percentage_improvement",
          "count_deterioration",
          "percentage_deterioration",
          "count_no_reliable_change",
          "percentage_no_reliable_change",
          "count_reliable_recovery",
          "percentage_reliable_recovery",
          "count_recovery",
          "percentage_recovery"
        ),
        # Extract pattern for splitting measure names
        sep = "^(count|mean|median|percentage|sum)_(.+)$",
        # Output column names for extracted parts
        into = c("measure_statistic", "measure_name")
      ),

      # Post-pivot: Applied after combining all periods
      # Clean values in columns
      clean_values = c("measure_name", "measure_statistic"),

      # Final column selection and order
      select = c(
        "reporting_period",
        "start_date",
        "end_date",
        "org_type",
        "org_code",
        "org_name",
        "variable_type",
        "variable_a",
        "variable_b",
        "measure_id",
        "measure_name",
        "measure_statistic",
        "value"
      )
    )
  )
}
