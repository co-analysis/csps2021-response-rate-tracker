library(tidyverse)

csps2021_id <- qualtRics::all_surveys() %>%
  filter(name == "CSPS 2021") %>%
  pull(id)

# generate url to fetch the data
fetch_url <- qualtRics:::generate_url(query = "fetchsurvey", surveyID = csps2021_id)

# generate the paylod
# need to include two questions in order to get toJSON to format correctly
raw_payload <- jsonlite::toJSON(list("useLabels" = TRUE, "questionIds" = c("QID4", "QID5"), "embeddedDataIds" = c("ParentOrgCode", "UnitLink"), "surveyMetadataIds" = c("endDate", "finished"), "format" = "csv"), auto_unbox = TRUE)

# send the request
tictoc::tic()
res <- qualtRics:::qualtrics_api_request("POST", url = fetch_url, body = raw_payload)
tictoc::toc()

# get the request ID
if (is.null(res$result$progressId)) {
  stop("Something went wrong. Please re-run your query.")
} else {
  requestID <- res$result$progressId
}

# download the data produced by the request
tictoc::tic()
survey.fpath <- qualtRics:::download_qualtrics_export(fetch_url, requestID,
                                          verbose = TRUE)
tictoc::toc()

# read the data and copy to the qualtrics_raw folder
data <- qualtRics::read_survey(survey.fpath)
file.copy(survey.fpath,
          file.path("R", "data", "qualtrics_raw",
                    paste0(format(Sys.time(), "%Y-%m-%d-%H%M%S"), "_",
                           basename(survey.fpath))))

headcounts <- readr::read_csv("R/data/headcounts.csv")

# process the data for response counts
# get counts from before today
rr_org <- data %>%
  filter(Finished & EndDate < Sys.Date()) %>%
  mutate(OUcode = case_when(
    ParentOrgCode == "HMICFRS" ~ "HMICFR0000",
    ParentOrgCode == "HMPPS0000" ~ "HMPPHQ0000",
    TRUE ~ toupper(ParentOrgCode)
  )) %>%
  mutate(org = str_remove_all(OUcode, "\\d+")) %>%
  count(org) %>%
  full_join(headcounts, by = "org") %>%
  mutate(rr = n/hc)

# create total count
rr_time <- data %>%
  filter(Finished & EndDate < Sys.Date()) %>%
  mutate(end_date = lubridate::as_date(EndDate),
         end_date = if_else(end_date == as.Date("2021-09-27"),
                             as.Date("2021-09-28"),
                             end_date)) %>%
  count(end_date, name = "daily") %>%
  mutate(cumulative = cumsum(daily),
         hc = sum(rr_org$hc, na.rm = TRUE),
         rr = cumulative/hc)

# write org counts
write_excel_csv(rr_org,
                file.path("R", "data", "org_response_counts",
                          paste0(Sys.Date() - 1, "_", "org_count.csv")))

# write CS total
write_excel_csv(rr_time,
                file.path("R", "data", "total_responses_2021.csv"))
