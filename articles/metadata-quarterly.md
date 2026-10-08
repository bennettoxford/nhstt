# Quarterly measures and breakdowns

> **Note:** The quarterly metadata comes from the most recent monthly
> metadata file. Older quarterly periods might have fewer, or different,
> measures.

## Measures

In total there are **32** measures that the metadata lists as quarterly:

The quarterly data also include the waiting time measures `M347` to
`M350` and `M352` to `M355`, which the metadata lists as monthly
measures. See
[`vignette("metadata-monthly-core")`](https://bennettoxford.github.io/nhstt/articles/metadata-monthly-core.md)
for their descriptions.

## Breakdowns

### Organisational

The `org_type` column shows the organisation level of each row (e.g.,
England, CommissioningRegion, ICB, SubICB, Provider, SubICB-Provider).
The `icb_code`, `sub_icb_code` and `provider_code` columns (and their
name columns) are filled for the levels that apply to the row and `NA`
otherwise.

### Demographic and clinical

These three columns provide further options for breakdowns:

- `variable_type`: The type of variable by which the data are
  categorised.
- `variable_a`: The high-level variable values for the categories.
- `variable_b`: The sub-category, where applicable. `NA` if not
  applicable.

The data also include a `Total` variable type with all records. The
following table shows the other **138** breakdowns:
