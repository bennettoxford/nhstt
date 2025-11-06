#' Get dataset configurations for annual reports
#'
#' Configurations for datasets from annual report zip files.
#' Each annual zip contains multiple CSV files that are extracted using patterns.
#'
#' @return List of dataset configurations
#' @keywords internal
get_annual_dataset_configs <- function() {
  list(
    key_measures = list(
      name = "key_measures",
      description = "Key measures like referrals, finished treatments, and treatment outcomes",
      version = "0.1.0",
      output_filename = "key_measures.rds",
      tidy_fn = tidy_annual_dataset,
      pattern = "key_measures",
      source_type = "annual_reports",
      frequency = "annual",
      var_mapping = NULL,
      id_cols = c(
        "org_type", "org_code", "org_name", "variable_type", "variable_a", "variable_b"
      ),
      measure_cols = c(
        "count_referrals_received", "count_finished_course_treatment",
        "count_at_caseness", "count_not_at_caseness",
        "count_improvement", "percentage_improvement",
        "count_deterioration", "percentage_deterioration",
        "count_no_reliable_change", "percentage_no_reliable_change",
        "count_reliable_recovery", "percentage_reliable_recovery",
        "count_recovery", "percentage_recovery"
      ),
      extract_regex = "^(count|mean|median|percentage|sum)_(.+)$",
      filters = list(
        org_type = c("England", "Commissioning Region", "STP", "CCG", "Provider"),
        variable_type = c("Problem Descriptor", "Presenting Complaint")
      )
    ),
    medication_status = list(
      name = "medication_status",
      description = "Psychotropic medication status at start and end of treatment",
      version = "0.1.0",
      output_filename = "medication_status.rds",
      tidy_fn = tidy_annual_dataset,
      pattern = "medication_status",
      source_type = "annual_reports",
      frequency = "annual",
      var_mapping = c(
        "countstatus_end_prescribed_but_not_taking" = "count_status_end_prescribed_but_not_taking",
        "not_prescribed" = "count_status_end_not_prescribed",
        "not_stated_known_invalid" = "count_status_end_not_stated_not_known_invalid",
        "prescribed_not_taking" = "count_status_end_prescribed_but_not_taking",
        "prescribed_taking" = "count_status_end_prescribed_and_taking",
        "total" = "count_status_end_total"
      ),
      id_cols = c(
        "org_type", "org_code", "org_name", "variable_type", "variable_a", "variable_b"
      ),
      measure_cols = c(
        "count_status_end_total", "count_status_end_prescribed_but_not_taking",
        "count_status_end_prescribed_and_taking", "count_status_end_not_prescribed",
        "count_status_end_not_stated_not_known_invalid"
      ),
      extract_regex = "^(count|mean|median|percentage|sum)_(.+)$",
      filters = list(
        org_type = c("England", "Commissioning Region", "STP", "CCG", "Provider"),
        variable_type = "Psychotropic Medication Status"
      )
    ),
    therapy_type = list(
      name = "therapy_type",
      description = "Therapy type at start and end of treatment",
      version = "0.1.0",
      output_filename = "therapy_type.rds",
      measure_strip_prefix = "therapy_end_treatment_",
      tidy_fn = tidy_annual_dataset,
      pattern = "therapy.*type",
      source_type = "annual_reports",
      frequency = "annual",
      var_mapping = NULL,
      id_cols = c(
        "org_type", "org_code", "org_name", "variable_type", "variable_a", "variable_b"
      ),
      measure_cols = c(
        "count_therapy_end_treatment_li_guided_self_help_book",
        "count_therapy_end_treatment_li_non_guided_self_help_book",
        "count_therapy_end_treatment_li_guided_self_help_computer",
        "count_therapy_end_treatment_li_non_guided_self_help_computer",
        "count_therapy_end_treatment_li_structured_physical_activity",
        "count_therapy_end_treatment_li_psycho_educational_peer_support",
        "count_therapy_end_treatment_li_other",
        "count_therapy_end_treatment_hi_applied_relaxation",
        "count_therapy_end_treatment_hi_couples_therapy_for_depression",
        "count_therapy_end_treatment_hi_collaborative_care",
        "count_therapy_end_treatment_hi_counselling_for_depression",
        "count_therapy_end_treatment_hi_eye_movement_desensitisation_reprocessing",
        "count_therapy_end_treatment_hi_mindfulness",
        "count_therapy_end_treatment_hi_cognitive_behaviour_therapy",
        "count_therapy_end_treatment_hi_interpersonal_psycho_therapy",
        "count_therapy_end_treatment_hi_other",
        "count_therapy_end_treatment_last_not_stated"
      ),
      extract_regex = "^(count|mean|median|percentage|sum)_(.+)$",
      filters = list(
        org_type = c("England", "Commissioning Region", "STP", "CCG", "Provider"),
        variable_type = "Therapy type recorded at start of treatment"
      )
    ),
    effect_size = list(
      name = "effect_size",
      description = "Effect sizes for PHQ9 and GAD7, with start and end of treatment scores",
      version = "0.1.0",
      output_filename = "effect_size.rds",
      tidy_fn = tidy_annual_dataset,
      pattern = "effect_size",
      source_type = "annual_reports",
      frequency = "annual",
      var_mapping = c(
        "measure" = "proms",
        "effect_size" = "effect_size_start_to_end"
      ),
      id_cols = c(
        "org_type", "org_code", "org_name", "proms", "initial_caseness",
        "variable_type", "variable_a", "variable_b"
      ),
      measure_cols = c(
        "count_finished_course_treatment_by_initial_caseness_status",
        "count_finished_course_treatment_paired_wsas",
        "mean_start", "sd_start", "mean_end", "sd_end",
        "effect_size_start_to_end"
      ),
      extract_regex = "^(count|mean|sd|effect_size)_(.+)$",
      filters = list(
        org_type = c("England", "Commissioning Region", "STP", "CCG", "Provider"),
        initial_caseness = c("AtCaseness", "NotCaseness")
      )
    )
  )
}

#' Get dataset configurations for metadata
#'
#' Configurations for metadata extracted from Excel files.
#' Placeholder for future implementation.
#'
#' @return List of dataset configurations
#' @keywords internal
get_metadata_configs <- function() {
  list()
}

#' Get all dataset configurations
#'
#' Combines all dataset configurations from different sources.
#'
#' @return List of all dataset configurations
#' @keywords internal
get_dataset_configs <- function() {
  c(
    get_annual_dataset_configs(),
    get_metadata_configs()
  )
}
