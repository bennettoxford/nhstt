#' Tidy configuration for metadata dataset
#'
#' @return List containing tidy configuration for metadata dataset
#' @keywords internal
tidy_config_metadata <- function() {
  list(
    monthly = list(
      clean_column_names = TRUE,
      rename = c(
        meaure_type = "measure_type",
        measure_reference_number = "measure_id",
        description_of_measure_where_possible_measures_are_described_in_terms_of_the_classes_of_information_defined_in_nhs_data_dictionary = "description",
        ui_ds_of_derivations_used_defined_in_technical_output_specification = "derivation_uids"
      ),
      select = c(
        "reporting_period",
        "measure_type",
        "frequency",
        "measure_id",
        "measure_name",
        "description",
        "derivation_uids",
        "tables_used",
        "construction"
      )
    )
  )
}

#' Tidy configuration for annual metadata measures (main)
#'
#' @return List containing tidy configuration for metadata_measures_main dataset
#' @keywords internal
tidy_config_metadata_measures_main <- function() {
  list(
    annual = list(
      clean_column_names = TRUE,
      rename = c(
        csv_field_name = "field_name",
        description_of_measure = "description"
      ),
      mutate = list(
        dataset_name = list(value = "key_measures")
      ),
      select = c(
        "reporting_period",
        "dataset_name",
        "field_name",
        "description",
        "technical_construction",
        "additional_notes"
      )
    )
  )
}

#' Tidy configuration for annual metadata measures (additional)
#'
#' @return List containing tidy configuration for metadata_measures_additional dataset
#' @keywords internal
tidy_config_metadata_measures_additional <- function() {
  list(
    annual = list(
      clean_column_names = TRUE,
      rename = c(
        name_of_additional_csv_data_file = "dataset_name",
        csv_field_name = "field_name",
        description_of_measure = "description"
      ),
      select = c(
        "reporting_period",
        "dataset_name",
        "field_name",
        "description",
        "technical_construction",
        "additional_notes"
      )
    )
  )
}

#' Tidy configuration for annual metadata variables (main)
#'
#' @return List containing tidy configuration for metadata_variables_main dataset
#' @keywords internal
tidy_config_metadata_variables_main <- function() {
  list(
    annual = list(
      clean_column_names = TRUE,
      rename = c(
        data_field_s_used_for_variable_type = "fields_for_variable_type",
        data_value_s_used_in_variable_a = "values_for_variable_a",
        data_value_s_used_in_variable_b = "values_for_variable_b"
      ),
      mutate = list(
        dataset_name = list(value = "key_measures")
      ),
      select = c(
        "reporting_period",
        "dataset_name",
        "variable_type",
        "variable_a",
        "variable_b",
        "fields_for_variable_type",
        "values_for_variable_a",
        "values_for_variable_b",
        "notes"
      )
    )
  )
}

#' Tidy configuration for annual metadata variables (additional)
#'
#' @return List containing tidy configuration for metadata_variables_additional dataset
#' @keywords internal
tidy_config_metadata_variables_additional <- function() {
  list(
    annual = list(
      clean_column_names = TRUE,
      rename = c(
        name_of_additional_csv_data_file = "dataset_name",
        data_field_s_used_for_variable_type = "fields_for_variable_type",
        data_value_s_used_in_variable_a = "values_for_variable_a",
        data_value_s_used_in_variable_b = "values_for_variable_b"
      ),
      select = c(
        "reporting_period",
        "dataset_name",
        "variable_type",
        "variable_a",
        "variable_b",
        "fields_for_variable_type",
        "values_for_variable_a",
        "values_for_variable_b",
        "notes"
      )
    )
  )
}
