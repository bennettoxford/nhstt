# Update the NHS England region boundaries used by the providers vignette

Developer tool. Downloads NHS England region boundaries from the Office
for National Statistics (ONS) Open Geography Portal and writes them as
GeoJSON for `vignettes/metadata-providers.qmd`. The ONS field names
include the year (e.g. `NHSER24NM`), so this renames them to
`region_code` and `region_name`. The vignette then works with any
boundary year. The file also stores the attribution, so the map credits
the boundaries it shows.

## Usage

``` r
update_region_boundaries(
  url = paste0("https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/",
    "NHS_England_Regions_January_2024_EN_BSC/FeatureServer/0/query",
    "?where=1%3D1&outFields=NHSER24CD,NHSER24NM&outSR=4326",
    "&geometryPrecision=4&f=geojson"),
  attribution = paste("Region boundaries: Office for National Statistics, OGL v3.0.",
    "Contains OS data &copy; Crown copyright and database right 2024"),
  path = "vignettes/assets/nhs-england-regions.geojson"
)
```

## Arguments

- url:

  Character, ArcGIS feature service query returning GeoJSON in WGS84
  with the region code and name fields

- attribution:

  Character, attribution required by the ONS licence

- path:

  Character, file to write

## Value

Invisibly returns `path`

## Details

Region names must match the `region_name` values in
[`get_metadata_providers()`](https://bennettoxford.github.io/nhstt/reference/get_metadata_providers.md)
for the region filter to work.
