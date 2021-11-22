library(tidyverse)

# interactively select file 2021-11-19_02g_responses-cleaned.csv
# from network drive
file <- rstudioapi::selectFile()

# check file selected
if (basename(file) != "2021-11-19_02g_responses-cleaned.csv") {
  stop("Incorrect file selected")
}

# read file
file_read <- readr::read_csv(
  file,
  col_select = c("ResponseId", "EndDate", "ParentOrgCode", "Method"),
  col_types = cols(.default = col_character())
)

# clean responses
responses <- file_read %>% slice(n = c(-1, -2)) %>%
  mutate(end_ts = parse_datetime(EndDate),
         end_date = as.Date(end_ts),
         end_date = if_else(end_date == as.Date("2021-11-04"),
                            as.Date("2021-11-03"),
                            end_date),
         org = str_remove_all(toupper(ParentOrgCode), "\\d+"))

# navigate to hierarchy file on drive
hierarchy_file <- rstudioapi::selectFile()

# check file selected
if (basename(hierarchy_file) != "2021-11-17_csps2021-hierarchy-interim.csv") {
  stop("Incorrect hierarchy file selected")
}

# read file
hierarchy_read <- readr::read_csv(
  hierarchy_file
)

# extract headcounts
headcounts <- hierarchy_read %>%
  filter(str_detect(ou_code, "\\d") & direct_hc > 0) %>%
  mutate(org = str_remove_all(ou_code, "\\d+")) %>%
  group_by(org) %>%
  summarise(hc = sum(direct_hc, na.rm = TRUE))

# extract group names
corporate_groups <- hierarchy_read %>%
  filter(str_detect(ou_code, "\\d", negate = TRUE)) %>%
  transmute(group = ou_code,
            org_group = str_remove(ou_name, "\\(Corporate Report\\)|Corporate Report.*"))

# extract organisation names
org_names <- hierarchy_read %>%
  filter(str_detect(ou_code, "0000")) %>%
  transmute(
    org = str_remove_all(ou_code, "\\d+"),
    name = case_when(
      org == "HMRC" ~ "HM Revenue & Customs",
      org == "DFE" ~ "Department for Education",
      TRUE ~ ou_name),
    group = if_else(ou_parent == "HMPPS0000", "MOJ", ou_parent)
  ) %>%
  left_join(corporate_groups, by = "group") %>%
  mutate(org_group = if_else(org == "SWNIO", name, org_group),
         across(c(name, org_group), ~str_replace(., "&", "and"))) %>%
  select(-group)

# calculate org response rates
rr_org <- responses %>%
  count(org) %>%
  left_join(headcounts, by = "org") %>%
  left_join(org_names, by = "org") %>%
  mutate(
    rr = n/hc
  )

# calculate response rates over time
rr_time <- responses %>%
  count(end_date, name = "daily") %>%
  mutate(cumulative = cumsum(daily),
         hc = sum(headcounts$hc),
         rr = cumulative/hc)

# write files
write_excel_csv(
  rr_org,
  "R/data/final_org_rates.csv"
)

write_excel_csv(
  rr_time,
  "R/data/total_responses_2021.csv"
)


# 2020 final rates --------------------------------------------------------

# get 2020 file
file2020 <- rstudioapi::selectFile()

# check file
if (basename(file2020) != "2020-11-15_combined_bind-online-paper.csv.zip") {
  stop("Incorrect 2020 file selected")
}

# read in file
file2020_read <- readr::read_csv(
  file2020,
  col_select = c("ResponseId", "EndDate", "flag_karen_cleaning",
                 "flag_lt3mins", "flag_lt20qs"),
  col_types = cols(.default = col_character())
)

# clean responses
responses2020 <- file2020_read %>% slice(n = c(-1, -2)) %>%
  mutate(
    valid = case_when(
      flag_karen_cleaning == "Delete record" ~ FALSE,
      flag_lt3mins == "1" ~ FALSE,
      flag_lt20qs == "1" ~ FALSE,
      TRUE ~ TRUE),
    end_date = as.Date(parse_datetime(EndDate))
  ) %>%
  filter(valid)

# calculate 2020 calculations
rr_time2020 <- responses2020 %>%
  count(end_date, name = "daily") %>%
  mutate(
    cumulative = cumsum(daily),
    day = if_else(
      is.na(end_date),
      99,
      as.numeric(end_date - as.Date("2020-10-01")) + 1),
    hc = 485831,
    rr = cumulative/hc
  ) %>%
  select(
    date_2020 = end_date,
    day = day,
    n_2020 = cumulative,
    hc_2020 = hc,
    rr_2020 = rr
  )

# write file
write_excel_csv(
  rr_time2020,
  "R/data/total_responses_2020.csv"
)
