library(tidyverse)

# get hierarchy file
raw_hierarchy <- readr::read_csv("R/data/raw_hierarchy/ukcivilservice_export_Thu Sep 30 13_53_58 UTC 2021.csv")

# get org names
org_names <- raw_hierarchy %>%
  filter(str_detect(ParentOrgCode, "0000$")) %>%
  transmute(
    org = str_remove_all(toupper(ParentOrgCode), "\\d+"),
    name = str_remove(UnitName, "^[A-Z]+\\d{4} ")
  ) %>%
  filter(org != "HMPPS") %>%
  mutate(
    name = case_when(
      org == "HMRC" ~ "HM Revenue & Customs",
      org == "DFE" ~ "Department for Education",
      TRUE ~ name
    )
  )

# calculate org headcount
out_headcounts <- raw_hierarchy %>%
  select(ParentOrgCode, ExpectedCount) %>%
  mutate(org = str_remove_all(toupper(ParentOrgCode), "\\d+")) %>%
  count(org, wt = ExpectedCount, name = "hc") %>%
  filter(org != "All" & org != "AGD" & hc > 0) %>%
  full_join(org_names, by = "org")

# write file
write_excel_csv(out_headcounts, "R/data/headcounts.csv")
