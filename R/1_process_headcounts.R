library(tidyverse)

# get hierarchy files
hc_files <- dir("R/data/raw_hierarchy", full.names = TRUE)

# get hierachy datetime
hc_dt <- as.POSIXct(
  gsub("^.*export_([A-Z].*)\\.csv", "\\1", hc_files),
  format = "%a %b %d %H_%M_%S UTC %Y"
)

names(hc_dt) <- hc_files

hc_dt <- sort(hc_dt, decreasing = TRUE)

# import hierarchy file
raw_hierarchy <- readr::read_csv(names(hc_dt[1]))

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

# compare overall sum
if (sum(out_headcounts$hc, na.rm = TRUE) ==
    sum(raw_hierarchy$ExpectedCount, na.rm = TRUE)) {
  message("Headcount total matches, total is: ",
          prettyNum(sum(out_headcounts$hc, na.rm = TRUE), big.mark = ","))
} else {
  stop("Headcount total does not!, Raw total is: ",
       prettyNum(sum(raw_hierarchy$ExpectedCount, na.rm = TRUE), big.mark = ","),
       ". Processed total is: ",
       prettyNum(sum(out_headcounts$hc, na.rm = TRUE), big.mark = ","), ".")
}

# get families
org_families <- raw_hierarchy %>%
  filter(str_detect(ParentOrgCode, "\\d+", negate = TRUE) &
           ParentOrgCode != "All") %>%
  select(ParentOrgCode, UnitName, UnitID) %>%
  transmute(
    parent_code = toupper(ParentOrgCode),
    parent_OHU = UnitID,
    parent_name = str_replace(
      UnitName,
      "^\\w{2,7}\\s(.*)\\s(\\(Corporate Report\\)|Corporate Report.*)$",
      "\\1")
  )

# get org with family
org_with_family <- raw_hierarchy %>%
  filter(str_detect(ParentOrgCode, "0000$") & ParentOrgCode != "HMPPS0000") %>%
  select(ParentOrgCode, UnitID, parent_OHU = ParentUnitID) %>%
  left_join(org_families, by = "parent_OHU") %>%
  mutate(
    parent_code = if_else(
      parent_OHU == "OHU_1MNiNxNPdB6Ni7k",
      "MOJ",
      parent_code
    ),
    parent_name = if_else(
      parent_OHU == "OHU_1MNiNxNPdB6Ni7k",
      "Ministry of Justice",
      parent_name
    )
  )

# get multi-org families
family_counts <- org_with_family %>%
  count(parent_code, parent_name) %>%
  filter(n > 1)

# output family groups
org_groups <- org_with_family %>%
  transmute(
    org = str_remove(toupper(ParentOrgCode), "\\d+"),
    org_group = if_else(
      parent_code %in% family_counts$parent_code,
      parent_name,
      NA_character_
    )
  )

# merge headcounts
out_headcounts_with_group <- out_headcounts %>%
  left_join(org_groups, by = "org")

# write file
write_excel_csv(out_headcounts_with_group, "R/data/headcounts.csv")
write_lines(hc_dt[[1]], "R/data/headcount_timestamp.txt")
