# Plotting functions for measures tables created with create_measures().
# ggplot2 and scales are Suggests dependencies, so every user-facing function
# here checks they are installed before doing anything. Colours come from the
# Brewer Dark2 palette via ggplot2/scales rather than hard-coded values.

#' ggplot2 theme for NHS TT figures
#'
#' Applied internally by [plot_measures()] and [plot_measures_deciles()].
#'
#' @param base_size Numeric, base font size. Default 13
#'
#' @return A ggplot2 theme object
#'
#' @importFrom rlang check_installed
#'
#' @keywords internal
theme_nhstt <- function(base_size = 13) {
  check_installed("ggplot2")
  ggplot2::theme_classic(base_size = base_size) +
    ggplot2::theme(
      panel.grid.major = ggplot2::element_line(
        colour = "gray90",
        linetype = "dotted"
      ),
      strip.text = ggplot2::element_text(face = "bold"),
      strip.background = ggplot2::element_rect(linewidth = 0),
      strip.text.x = ggplot2::element_text(size = base_size, face = "bold"),
      legend.title = ggplot2::element_text(size = base_size),
      legend.text = ggplot2::element_text(size = base_size * 0.95)
    )
}

#' Convert raw measure names to sentence case for figure labels
#'
#' @param x Character vector of measure names (e.g., "ended_completed")
#'
#' @return Character vector in sentence case (e.g., "Completed")
#'
#' @importFrom stringr str_remove str_replace_all str_to_sentence
#'
#' @keywords internal
measure_name_to_sentence <- function(x) {
  x |>
    str_remove("^ended_") |>
    str_replace_all("_", " ") |>
    str_to_sentence()
}

#' Add a measure panel label column to a measures table
#'
#' Builds a `measure_name_id` factor like "Completed (M066)" (or
#' "A: Completed (M066)" with panel tags), ordered by measure ID.
#'
#' @param measures Tibble, as returned by [create_measures()]
#' @param panel_tags Logical, prefix panels with "A:", "B:", ... Default FALSE
#' @param measure_order Character vector of measure IDs giving the panel
#'   order. Default NULL (panels ordered by measure ID)
#'
#' @return The measures tibble with a `measure_name_id` factor column
#'
#' @importFrom dplyr distinct arrange mutate left_join select n
#' @importFrom cli cli_abort
#'
#' @keywords internal
measure_panel_labels <- function(
  measures,
  panel_tags = FALSE,
  measure_order = NULL
) {
  df_labels <- measures |>
    distinct(measure_id, measure_name)

  if (is.null(measure_order)) {
    df_labels <- arrange(df_labels, measure_id)
  } else {
    df_labels <- arrange(
      df_labels,
      factor(measure_id, levels = measure_order)
    )
  }

  if (panel_tags && nrow(df_labels) > length(LETTERS)) {
    cli_abort(
      "{.arg panel_tags} supports at most {length(LETTERS)} measures,
      not {nrow(df_labels)}"
    )
  }

  df_labels <- df_labels |>
    mutate(
      tag = if (panel_tags) paste0(LETTERS[seq_len(n())], ": ") else "",
      measure_name_id = paste0(
        tag,
        measure_name_to_sentence(measure_name),
        " (",
        measure_id,
        ")"
      )
    )

  measures |>
    left_join(
      df_labels |> select(measure_id, measure_name_id),
      by = "measure_id"
    ) |>
    mutate(
      measure_name_id = factor(
        measure_name_id,
        levels = df_labels$measure_name_id
      )
    )
}

#' Yearly x-axis breaks anchored to a fixed date within each year
#'
#' @param dates Date vector
#' @param break_start Character, format string giving the anchor date within
#'   the first year. Default "%Y-01-01" (1 January)
#'
#' @return Date vector with one break per year in the range of `dates`. When
#'   no yearly break falls inside the range (e.g. data spanning only a few
#'   months that do not include the anchor date), falls back to
#'   [pretty()] breaks so the axis is never left unlabelled
#'
#' @keywords internal
nhstt_year_breaks <- function(dates, break_start = "%Y-01-01") {
  from <- as.Date(format(min(dates, na.rm = TRUE), break_start))
  to <- max(dates, na.rm = TRUE)

  breaks <- if (from <= to) {
    seq(from, to, by = "1 year")
  } else {
    as.Date(character())
  }

  if (!any(breaks >= min(dates, na.rm = TRUE))) {
    return(pretty(range(dates, na.rm = TRUE)))
  }
  breaks
}

#' Plot monthly trends for each measure across all services
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Draws one line per service, facetted by measure, for either the raw
#' numerator counts or the ratio relative to the denominator.
#'
#' @param measures Tibble, as returned by [create_measures()], filtered to the
#'   measures to plot
#' @param y Character, plot the "ratio" (default) or the "numerator" counts
#' @param ncol Integer, number of facet columns. Default 2
#' @param panel_tags Logical, prefix panels with "A:", "B:", ... Default FALSE
#' @param measure_order Character vector of measure IDs giving the panel
#'   order. Default NULL (panels ordered by measure ID)
#'
#' @return A ggplot object, so labels and theme can be adjusted with `+`
#'
#' @importFrom rlang check_installed arg_match
#'
#' @export
#'
#' @examples
#' \dontrun{
#' df_clean |> plot_measures(y = "ratio")
#' df_clean |> plot_measures(y = "numerator") + ggplot2::labs(y = "Referrals")
#' }
plot_measures <- function(
  measures,
  y = c("ratio", "numerator"),
  ncol = 2,
  panel_tags = FALSE,
  measure_order = NULL
) {
  check_installed(c("ggplot2", "scales"))
  validate_measures(measures)
  y <- arg_match(y)

  df_plot <- measure_panel_labels(
    measures,
    panel_tags = panel_tags,
    measure_order = measure_order
  )

  # coord_cartesian() zooms without censoring, so ratios outside [0, 1]
  # (possible when implausible ratios have not been removed yet) are not
  # silently dropped and lines through them are not broken
  if (y == "ratio") {
    scale_y <- ggplot2::scale_y_continuous(
      labels = scales::label_percent(accuracy = 1)
    )
    coord <- ggplot2::coord_cartesian(ylim = c(0, 1))
  } else {
    scale_y <- ggplot2::scale_y_continuous(labels = scales::label_comma())
    coord <- ggplot2::coord_cartesian()
  }
  y_lab <- if (y == "ratio") "Proportion of denominator" else "Count"

  ggplot2::ggplot(
    df_plot,
    ggplot2::aes(
      y = .data[[y]],
      x = interval_end,
      colour = measure_name_id,
      group = org_code2
    )
  ) +
    ggplot2::geom_line(alpha = 0.2) +
    ggplot2::geom_point(size = 0.2) +
    ggplot2::scale_colour_brewer(palette = "Dark2") +
    ggplot2::scale_x_date(
      breaks = nhstt_year_breaks(df_plot$interval_end),
      labels = scales::label_date("%b\n%Y")
    ) +
    scale_y +
    coord +
    ggplot2::labs(x = NULL, y = y_lab) +
    ggplot2::facet_wrap(
      ggplot2::vars(measure_name_id),
      scales = "fixed",
      ncol = ncol,
      axes = "all"
    ) +
    theme_nhstt() +
    ggplot2::theme(legend.position = "none")
}

#' Plot decile charts for each measure, optionally highlighting services
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Shows the distribution of ratios across all services as decile bands (10th
#' to 90th percentile, darker closer to the median), facetted by measure.
#' Selected services can be highlighted as coloured lines, labelled with their
#' service name by default or with generic "Service A", "Service B", ... labels
#' when service names should not be shown (e.g. in a blog post).
#'
#' @param measures Tibble, as returned by [create_measures()], filtered to the
#'   measures to plot
#' @param highlight_services Character vector of org codes to highlight (e.g.,
#'   `c("RNUDT", "RTQ")`). Default NULL (no services highlighted)
#' @param hide_service_names Logical, label highlighted services "Service A",
#'   "Service B", ... instead of their service name. Default FALSE
#' @param ncol Integer, number of facet columns. Default 2
#' @param panel_tags Logical, prefix panels with "A:", "B:", ... Default FALSE
#' @param measure_order Character vector of measure IDs giving the panel
#'   order. Default NULL (panels ordered by measure ID)
#'
#' @return A ggplot object, so labels and theme can be adjusted with `+`
#'
#' @importFrom dplyr filter distinct mutate left_join select arrange pull
#' @importFrom tidyr pivot_wider
#' @importFrom stats setNames
#' @importFrom grDevices gray
#' @importFrom cli cli_abort
#' @importFrom rlang check_installed
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # highlighted services labelled with their names
#' df_clean |> plot_measures_deciles(highlight_services = c("RNUDT", "RTQ"))
#'
#' # generic labels when service names should not be shown
#' df_clean |> plot_measures_deciles(highlight_services = c("RNUDT", "RTQ"), hide_service_names = TRUE)
#' }
plot_measures_deciles <- function(
  measures,
  highlight_services = NULL,
  hide_service_names = FALSE,
  ncol = 2,
  panel_tags = FALSE,
  measure_order = NULL
) {
  check_installed(c("ggplot2", "scales"))
  validate_measures(measures)

  df_plot <- measure_panel_labels(
    measures,
    panel_tags = panel_tags,
    measure_order = measure_order
  )

  df_deciles <- df_plot |>
    summarise_percentiles(
      period_col = interval_end,
      value_col = ratio,
      group_by = c(measure_id, measure_name_id)
    ) |>
    pivot_wider(
      names_from = percentile,
      values_from = value,
      names_prefix = "p"
    )

  ribbon_palette <- setNames(
    gray(seq(0.7, 0.5, length.out = 4)),
    c("10th-90th", "20th-80th", "30th-70th", "40th-60th")
  )
  ribbon_alpha <- 0.2
  median_line_colour <- gray(0.3)

  # Brewer Dark2 (via scales, the same palette plot_measures() uses through
  # scale_colour_brewer), reordered so the first two highlighted services get
  # the green/pink pairing used in our blog posts. The shape vector caps how
  # many services can be highlighted
  service_palette <- scales::brewer_pal(palette = "Dark2")(8)[
    c(1, 4, 2, 3, 5, 6, 7, 8)
  ]
  service_highlight_shapes <- c(16, 17, 15, 18, 8, 7, 3, 4)

  p <- ggplot2::ggplot() +
    ggplot2::geom_ribbon(
      data = df_deciles,
      ggplot2::aes(
        x = interval_end,
        ymin = p10,
        ymax = p90,
        fill = "10th-90th"
      ),
      alpha = ribbon_alpha
    ) +
    ggplot2::geom_ribbon(
      data = df_deciles,
      ggplot2::aes(
        x = interval_end,
        ymin = p20,
        ymax = p80,
        fill = "20th-80th"
      ),
      alpha = ribbon_alpha
    ) +
    ggplot2::geom_ribbon(
      data = df_deciles,
      ggplot2::aes(
        x = interval_end,
        ymin = p30,
        ymax = p70,
        fill = "30th-70th"
      ),
      alpha = ribbon_alpha
    ) +
    ggplot2::geom_ribbon(
      data = df_deciles,
      ggplot2::aes(
        x = interval_end,
        ymin = p40,
        ymax = p60,
        fill = "40th-60th"
      ),
      alpha = ribbon_alpha
    ) +
    ggplot2::geom_line(
      data = df_deciles,
      ggplot2::aes(x = interval_end, y = p50),
      colour = median_line_colour,
      linewidth = 0.6,
      show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(
      values = ribbon_palette,
      breaks = names(ribbon_palette)
    )

  if (!is.null(highlight_services)) {
    highlight_services <- unique(highlight_services)

    if (length(highlight_services) > length(service_highlight_shapes)) {
      cli_abort(
        "{.arg highlight_services} supports at most
        {length(service_highlight_shapes)} services,
        not {length(highlight_services)}"
      )
    }

    unknown <- setdiff(highlight_services, unique(measures$org_code2))
    if (length(unknown) > 0) {
      cli_abort(
        "Org code{?s} not found in {.arg measures}: {.val {unknown}}"
      )
    }

    if (hide_service_names) {
      service_labels <- setNames(
        paste("Service", LETTERS[seq_along(highlight_services)]),
        highlight_services
      )
    } else {
      service_labels <- latest_org_names(df_plot) |>
        filter(org_code2 %in% highlight_services) |>
        pull(org_name2, name = org_code2)
      service_labels <- service_labels[highlight_services]
      # Different org codes can share a service name; disambiguate so the
      # factor levels below stay unique
      if (anyDuplicated(service_labels) > 0) {
        service_labels <- setNames(
          paste0(service_labels, " (", highlight_services, ")"),
          highlight_services
        )
      }
    }

    df_highlight <- df_plot |>
      filter(org_code2 %in% highlight_services) |>
      mutate(
        service_label = factor(
          service_labels[org_code2],
          levels = unname(service_labels)
        )
      )

    service_colours <- setNames(
      service_palette[seq_along(highlight_services)],
      unname(service_labels)
    )
    service_shapes <- setNames(
      service_highlight_shapes[seq_along(highlight_services)],
      unname(service_labels)
    )

    p <- p +
      ggplot2::geom_line(
        data = df_highlight,
        ggplot2::aes(
          x = interval_end,
          y = ratio,
          colour = service_label,
          group = service_label
        ),
        alpha = 0.5
      ) +
      ggplot2::geom_point(
        data = df_highlight,
        ggplot2::aes(
          x = interval_end,
          y = ratio,
          shape = service_label,
          colour = service_label,
          group = service_label
        )
      ) +
      ggplot2::scale_colour_manual(
        name = "NHS TT service:",
        values = service_colours
      ) +
      ggplot2::scale_shape_manual(
        name = "NHS TT service:",
        values = service_shapes
      ) +
      ggplot2::guides(
        colour = ggplot2::guide_legend(order = 1, nrow = 1),
        shape = ggplot2::guide_legend(order = 1, nrow = 1),
        fill = ggplot2::guide_legend(order = 2, nrow = 1)
      )
  }

  p +
    ggplot2::scale_x_date(
      breaks = nhstt_year_breaks(df_plot$interval_end),
      labels = scales::label_date("%b\n%Y")
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_percent(accuracy = 1)
    ) +
    # zoom rather than censor, so ratios outside [0, 1] are not silently
    # dropped (see plot_measures())
    ggplot2::coord_cartesian(ylim = c(0, 1)) +
    ggplot2::labs(
      x = NULL,
      y = "Proportion of denominator",
      fill = "Decile range:"
    ) +
    theme_nhstt() +
    ggplot2::theme(
      legend.position = "bottom",
      legend.box = "vertical"
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(measure_name_id),
      ncol = ncol,
      axes = "all"
    )
}
