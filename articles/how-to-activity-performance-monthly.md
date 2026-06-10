# Exploring monthly changes in treatment end codes

> This vignette provides the complete R code used to reproduce the
> analyses in our blog post: [From public NHS Talking Therapies reports
> to research insights: Introducing the *nhstt* R
> package](https://talkingtherapies.opensafely.org/from-public-nhs-talking-therapies-reports-to-research-insights-introducing-the-nhstt-r-package/).

In a [previous blog
post](https://talkingtherapies.opensafely.org/introducing-our-series-on-publicly-available-mental-health-data-nhs-talking-therapies-for-anxiety-and-depression/)
we introduced the NHS TT data reports that NHS England publishes openly
alongside interactive dashboards for exploring key measures directly in
a browser. These datasets cover various measures, including referral
activity, waiting times, clinical outcomes, and patient-reported outcome
measures. The value of these datasets has been demonstrated by Clark et
al. ([2018](#ref-Clark2018a)), who used publicly available NHS TT
reports to study between-service variation in clinical outcomes. They
found that organisational factors including waiting times, missed
appointments, and the proportion of patients receiving a course of
treatment were associated with rates of reliable recovery and
improvement. This illustrates the broader role of public reporting in
supporting transparency, benchmarking, and research on variation in
routine psychological therapy services ([Clark et al.
2018](#ref-Clark2018a); [Clark 2018](#ref-Clark2018b)).

The [*nhstt* R package](https://bennettoxford.github.io/nhstt/) is built
on top of these publicly available resources and designed to complement
them. It provides an additional point of access to the same data in a
tidy, analysis-ready format across all available reporting periods. In
this vignette we use treatment end codes from the monthly activity and
performance data as a worked example, but the same approach applies to
any of the measures in the dataset. The examples are descriptive and
intended to illustrate what can be done with the data, not to draw
conclusions about individual services.

## Treatment end codes

When a referral ends in the reporting period, NHS TT services record a
reason using a standardised treatment end code. These codes group
referral outcomes into three categories: (1) referred but not seen, (2)
seen but not taken on for a course of treatment, and (3) seen and taken
on for a course of treatment. This post focuses on the last category,
which covers patients who received two or more sessions, and captures
the recorded reason their treatment ended.

The monthly dataset includes counts for each end code, available from
January 2021 to March 2026. The table below shows the five end codes in
this category, with total recorded events and the number of services
contributing data. The four most commonly recorded end codes are
presented in the figures below. All [descriptions of monthly
measures](https://bennettoxford.github.io/nhstt/articles/metadata-monthly-core.html)
implemented in the *nhstt* R package can be explored online.

| ID | Description | Total events | NHS TT services |
|:---|:---|----|----|
| M066 | Count of referrals with an end date in the reporting period - Improving Access to Psychological Therapies care spell end code is 'Mutually agreed completion of treatment’ | 2,375,625 | 175 |
| M344 | Count of referrals that ended in the reporting period with an end code of ‘Termination of treatment earlier than Care Professional planned’ | 1,414,705 | 164 |
| M070 | Count of referrals that ended in the reporting period with an end code of ‘Not Known (Seen and taken on for a course of treatment)’ | 121,495 | 77 |
| M341 | Count of referrals that ended in the reporting period with an end code of ‘Termination of treatment earlier than patient requested’ | 89,715 | 84 |
| M069 | Count of referrals that ended in the reporting period with an end code of ‘Deceased (Seen and taken on for a course of treatment)’ | 365 | 13 |

End codes for referrals seen and taken on for a course of treatment in
the monthly NHS TT dataset (January 2021 to March 2026), with total
recorded events and number of services contributing data. {.table
.gt_table quarto-disable-processing="false" quarto-bootstrap="false"}

## Monthly trends and variation in treatment end codes

Across 63 reporting periods, these monthly counts make it possible to
look beyond annual totals and examine trends and variation in treatment
end codes over time. We first show service-level trends across all
services, then use decile bands to place two example services in
context.

### Trends across all services

The figure below shows the raw monthly counts for the four most commonly
recorded end codes across all NHS TT services. Each line represents one
service, showing both the scale of between-service variation and whether
it is stable over time. Because these are counts rather than rates,
differences between services will partly reflect differences in service
size.

![Monthly trends across all NHS TT services (one line per service) for
the four most commonly recorded end
codes.](how-to-activity-performance-monthly_files/figure-html/fig-monthly-end-code-measures-1.png)

Monthly trends across all NHS TT services (one line per service) for the
four most commonly recorded end codes.

Across all four end codes, most services record counts within a similar
range and follow broadly consistent trends over the reporting period. A
small number of services stand out as consistent outliers, particularly
for referrals that ended with *Completed* (M066), *Before care
professional planned* (M344), and *Unknown treated* (M070).

### Comparing services with decile bands

The figure below uses decile bands to place the two example services in
the context of the full distribution across all NHS TT services. Read
more on why we think [deciles charts are a useful tool to communicate
variation](https://www.bennett.ox.ac.uk/blog/2019/04/communicating-variation-in-prescribing-why-we-use-deciles/)
in a previous blog we wrote. The shaded bands show the distribution from
the 10th to the 90th percentile in decile steps, with darker shading
closer to the median. A service outside the bands falls in the top or
bottom 10% for that month. The width of the bands reflects how much
variation there is between services, with wider bands indicating greater
spread. These charts summarise activity patterns and are not intended as
rankings of service quality.

![Decile charts across all NHS TT services for the four most commonly
recorded end codes. Shaded bands show the 10th to 90th percentile range
in decile steps. The dark line shows the median. Two example services
are shown as coloured
lines.](how-to-activity-performance-monthly_files/figure-html/fig-monthly-end-code-measures-deciles-1.png)

Decile charts across all NHS TT services for the four most commonly
recorded end codes. Shaded bands show the 10th to 90th percentile range
in decile steps. The dark line shows the median. Two example services
are shown as coloured lines.

*Service A* sits above the median for completed referrals (M066) and
tracks closer to the median for the remaining end codes. *Service B*
records consistently high counts of completed referrals, sitting in the
top 10% of services throughout the reporting period, and also starts
above the median for end codes before the patient requested (M341) and
care professional planned (M344), trending closer towards the median
over the reporting period.

## Try it yourself

The *nhstt* package makes it easy to access publicly available NHS TT
data for research, is free to use, and is updated regularly as NHS
England publishes new reports. It provides access to each dataset in a
tidy, analysis-ready format, with no need to find the underlying files.
Whether you are interested in trends in referral activity, variation in
waiting times across services, or changes in clinical outcomes over
time, the data are there to be explored. We recommend checking the NHS
England [data quality
notes](https://digital.nhs.uk/binaries/content/assets/website-assets/data-and-information/datasets/nhs-talking-therapies/nhs_talking_therapies_dq_note-260327.xlsx)
before using these data, as they describe known issues affecting
specific reporting periods or measures.

If you use the package for a new analysis or have ideas for how it could
be extended, we would love to hear about it. For questions or to report
an issue, please [open an issue on
GitHub](https://github.com/bennettoxford/nhstt/issues) or get in touch
with [Milan Wiedemann](https://www.phc.ox.ac.uk/team/milan-wiedemann).

## References

Clark, David M. 2018. “Realising the Mass Public Benefit of
Evidence-Based Psychological Therapies: The IAPT Program.” *Annual
Review of Clinical Psychology*, ahead of print, January 19.
<https://doi.org/10.1146/annurev-clinpsy-050817-084833>.

Clark, David M, Lauren Canvin, John Green, Richard Layard, Stephen
Pilling, and Magdalena Janecka. 2018. “Transparency about the Outcomes
of Mental Health Services (IAPT Approach): An Analysis of Public Data.”
*The Lancet* 391 (10121): 679–86.
<https://doi.org/10.1016/S0140-6736(17)32133-5>.
