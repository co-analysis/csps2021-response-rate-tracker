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

# write file
write_excel_csv(out_headcounts, "R/data/headcounts.csv")
write_lines(hc_dt[[1]], "R/data/headcount_timestamp.txt")
