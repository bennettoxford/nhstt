#' Key measures dataset from NHS TT annual reports
#'
#' Contains key performance indicators for NHS Talking Therapies services including
#' referrals, treatment completion, recovery, and improvement rates across different
#' problem descriptors and presenting complaints.
#'
#' After running [nhstt_setup()], this dataset can be accessed directly by running
#' `key_measures`.
#'
#' @format A tibble in tidy/long format with the following columns:
#' \describe{
#'   \item{start_date}{Start date of the annual reporting period (e.g., "2024-04-01")}
#'   \item{end_date}{End date of the annual reporting period (e.g., "2025-03-31")}
#'   \item{period}{NHS financial year identifier (e.g., "fy2425" for 2024/25)}
#'   \item{org_type}{Organisation type (e.g., "England", "Commissioning Region", "STP", "CCG", "Provider")}
#'   \item{org_code}{Organisation code (e.g., "All", "Y54", "15M")}
#'   \item{org_name}{Organisation name (e.g., "All", "NORTH OF ENGLAND COMMISSIONING REGION")}
#'   \item{variable_type}{Type of categorisation (e.g., "Problem Descriptor", "Presenting Complaint")}
#'   \item{variable_a}{Primary breakdown variable (e.g., "Depression", "Anxiety and stress related disorders", "All ADSM")}
#'   \item{variable_b}{Secondary breakdown variable, further breakfowns of some categories in variable_a (e.g., "Agoraphobia", "Generalized anxiety disorder") or NA}
#'   \item{statistic}{Type of statistic (e.g., "count", "percentage")}
#'   \item{measure}{Outcome measure (e.g., "referrals_received", "finished_course_treatment", "recovery", "improvement")}
#'   \item{value}{Numeric value of the measure, as specified in statistic column}
#' }
#'
#' @source <https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports>
#' @keywords datasets
#' @name key_measures
#' @export key_measures
#'
#' @examples
#' \donttest{
#' nhstt_setup(datasets = "key_measures")
#' key_measures
#' }
NULL

#' Medication status dataset from NHS TT annual reports
#'
#' Contains information about psychotropic medication status at the start and end
#' of treatment for NHS Talking Therapies patients, including whether they were
#' prescribed medication, taking it, or not prescribed.
#'
#' After running [nhstt_setup()], this dataset can be accessed directly by running
#' `medication_status`.
#'
#' @format A tibble in tidy/long format with the following columns:
#' \describe{
#'   \item{start_date}{Start date of the annual reporting period (e.g., "2024-04-01")}
#'   \item{end_date}{End date of the annual reporting period (e.g., "2025-03-31")}
#'   \item{period}{NHS financial year identifier (e.g., "fy2425" for 2024/25)}
#'   \item{org_type}{Organisation type (e.g., "England", "Commissioning Region", "STP", "CCG", "Provider")}
#'   \item{org_code}{Organisation code (e.g., "All", "Y54", "15M")}
#'   \item{org_name}{Organisation name (e.g., "All", "NORTH OF ENGLAND COMMISSIONING REGION")}
#'   \item{variable_type}{Type of categorisation (always "Psychotropic Medication Status")}
#'   \item{variable_a}{Primary breakdown variable (e.g., "Status Start - Prescribed and taking", "Status Start - Not Prescribed")}
#'   \item{variable_b}{Always NA for this dataset}
#'   \item{statistic}{Type of statistic (always "count")}
#'   \item{measure}{Medication status measure at end (e.g., "status_end_prescribed_and_taking", "status_end_not_prescribed")}
#'   \item{value}{Numeric value of the measure, as specified in statistic column}
#' }
#'
#' @source <https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports>
#' @keywords datasets
#' @name medication_status
#' @export medication_status
#'
#' @examples
#' \donttest{
#' nhstt_setup(datasets = "medication_status")
#' medication_status
#' }
NULL

#' Therapy type dataset from NHS TT annual reports
#'
#' Contains information about the types of therapy recorded at the start of treatment,
#' including low intensity interventions (e.g., guided self-help) and high intensity
#' interventions (e.g., CBT, EMDR).
#'
#' After running [nhstt_setup()], this dataset can be accessed directly by running
#' `therapy_type`.
#'
#' @format A tibble in tidy/long format with the following columns:
#' \describe{
#'   \item{start_date}{Start date of the annual reporting period (e.g., "2024-04-01")}
#'   \item{end_date}{End date of the annual reporting period (e.g., "2025-03-31")}
#'   \item{period}{NHS financial year identifier (e.g., "fy2425" for 2024/25)}
#'   \item{org_type}{Organisation type (e.g., "England", "Commissioning Region", "STP", "CCG", "Provider")}
#'   \item{org_code}{Organisation code (e.g., "All", "Y54", "15M")}
#'   \item{org_name}{Organisation name (e.g., "All", "NORTH OF ENGLAND COMMISSIONING REGION")}
#'   \item{variable_type}{Type of categorisation (always "Therapy type recorded at start of treatment")}
#'   \item{variable_a}{Primary breakdown variable (e.g., "Low Intensity", "High Intensity", "Not stated/Not known/Invalid")}
#'   \item{variable_b}{Secondary breakdown variable, further breakfowns of some categories in variable_a (e.g., "Guided self help book", "CBT", "Counselling for depression") or NA}
#'   \item{statistic}{Type of statistic (always "count" in this dataset)}
#'   \item{measure}{Therapy type measure (e.g., "li_guided_self_help_book", "hi_cbt")}
#'   \item{value}{Numeric value of the measure, as specified in statistic column}
#' }
#'
#' @source <https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports>
#' @keywords datasets
#' @name therapy_type
#' @export therapy_type
#'
#' @examples
#' \donttest{
#' nhstt_setup(datasets = "therapy_type")
#' therapy_type
#' }
NULL

#' Effect size dataset from NHS TT annual reports
#'
#' Contains patient-reported outcome measures (PROMs) data including PHQ-9 and GAD-7
#' scores at start and end of treatment, along with effect sizes and Work and Social
#' Adjustment Scale (WSAS) scores.
#'
#' After running [nhstt_setup()], this dataset can be accessed directly by running
#' `effect_size`.
#'
#' @format A tibble in tidy/long format with the following columns:
#' \describe{
#'   \item{start_date}{Start date of the annual reporting period (e.g., "2024-04-01")}
#'   \item{end_date}{End date of the annual reporting period (e.g., "2025-03-31")}
#'   \item{period}{NHS financial year identifier (e.g., "fy2425" for 2024/25)}
#'   \item{org_type}{Organisation type (e.g., "England", "Commissioning Region", "STP", "CCG", "Provider")}
#'   \item{org_code}{Organisation code (e.g., "All", "Y54", "15M")}
#'   \item{org_name}{Organisation name (e.g., "All", "NORTH OF ENGLAND COMMISSIONING REGION")}
#'   \item{proms}{Patient-reported outcome measure (e.g., "PHQ9" for depression, "GAD7" for anxiety)}
#'   \item{initial_caseness}{Caseness status at start (e.g., "AtCaseness", "NotCaseness")}
#'   \item{variable_type}{Type of categorisation (e.g., "Total", "Problem Descriptor", "Presenting Complaint")}
#'   \item{variable_a}{Primary breakdown variable (e.g., "ALL", "Depression", "Anxiety and stress related disorders")}
#'   \item{variable_b}{Secondary breakdown variable, further breakfowns of some categories in variable_a (e.g., "Agoraphobia") or "ALL" or NA}
#'   \item{statistic}{Type of statistic (e.g., "count", "mean", "sd", "effect_size")}
#'   \item{measure}{Measurement type (e.g., "start", "end", "start_to_end" for PROM scores, "finished_course_treatment_paired_wsas")}
#'   \item{value}{Numeric value of the measure, as specified in statistic column}
#' }
#'
#' @source <https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports>
#' @keywords datasets
#' @name effect_size
#' @export effect_size
#'
#' @examples
#' \donttest{
#' nhstt_setup(datasets = "effect_size")
#' effect_size
#' }
NULL
