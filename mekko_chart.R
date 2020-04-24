if (!exists("setup_env")) {
  stop("must be called from within setup.R")
}

setup_env$mekko_chart <- function(data, x, y,
                        show_labels = TRUE,
                        lab_min_x = 0.05,
                        lab_min_y = 0.05) {
  data.c <- count(data, {{x}}, {{y}})

  data.x <- data.c %>%
    group_by({{x}}) %>%
    summarise_at(vars(n), sum) %>%
    mutate_at(vars(n), ~.x / sum(.x)) %>%
    mutate(xmax = cumsum(n),
           xmin = lag(xmax, 1, 0)) %>%
    select(-n)

  data.f <- data.x %>%
    inner_join(data.c, by = as_name(enquo(x))) %>%
    group_by({{x}}) %>%
    mutate_at(vars(n), ~.x / sum(.x)) %>%
    mutate(ymax = cumsum(n),
           ymin = lag(ymax, 1, 0)) %>%
    select({{x}}, {{y}}, xmin, xmax, ymin, ymax) %>%
    mutate(lab_x = (xmin+xmax) / 2,
           lab_y = (ymin+ymax) / 2,
           lab_v = ifelse(show_labels &
                            ymax-ymin > lab_min_x &
                            xmax-xmin > lab_min_y,
                          percent(ymax-ymin, accuracy = 1),
                          NA))

  y_labs <- data.f %>%
    filter(xmin == 0) %>%
    mutate(y = (ymax+ymin) / 2)

  data.f %>%
    ggplot(aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
               fill = {{y}})) +
    geom_rect(colour="white", alpha = 0.4) +
    geom_text(aes(x = lab_x, y = lab_y, label = lab_v),
              colour = "white",
              na.rm = TRUE) +
    scale_x_continuous(breaks = (pull(data.x, xmax)+pull(data.x, xmin))/2,
                       labels = pull(data.x, {{x}}),
                       sec.axis = dup_axis(
                         breaks = seq(0,.9,.2),
                         labels = percent_format(accuracy = 1)
                       ),
                       expand = c(0, 0)) +
    scale_y_continuous(breaks = pull(y_labs, y),
                       labels = pull(y_labs, {{y}}),
                       sec.axis = dup_axis(
                         breaks = seq(0,.9,.2),
                         labels = percent_format(accuracy = 1)
                       ),
                       expand = c(0, 0)) +
    labs(x = "", y = "") +
    theme(legend.position = "none",
          axis.line = element_blank(),
          axis.ticks = element_blank())
}