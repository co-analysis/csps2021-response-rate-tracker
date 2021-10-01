
# CSPS 2021 Response Rate Tracker

This repo contains the code to generate, and the resulting webpage, of the high-level response rates for the 2021 Civil Service People Survey.

The data is processed in [R](https://www.r-project.org/), the site is built with [Hugo](https://gohugo.io/) using the [govuk-hugo](https://github.com/co-analysis/govuk-hugo) theme.

## LICENCE

The R code in this repository (files under the R directory) are licensed under the MIT Licence, see [`R/LICENSE`](R/LICENSE.md).

The content published in the output documents is published under the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).

## Data

No data files are tracked in this repo - data should be stored on your local machine in the (`R/data`) folder and backed up to shared drive.

## Dependencies
You will need:

- R
- The [{qualtRics} package](https://docs.ropensci.org/qualtRics/) and set up your credentials for the Qualtrics API
- The [{govukhugo} package](https://github.com/co-analysis/govuk-hugo-r)

## Workflow

1. If you need to re-process headcounts use the file `1_process_headcounts.R`, this requires an export of the Qualtrics hierarchy to be stored in `R/data/raw_hierarcy`
2. Use the file `2_get_responses.R` to download the latest response data, this will download raw output to `R/data/qualtrics_raw` and process the response rates to create a daily output of response rates by organisation and a a tally of overall responses by day.
3. Run `govukhugo::build_hugo()` to process the Rmarkdown and build the site.

If interactively processing the Rmd file you will need to manually set the `data_dir` variable in the conosle to `../data` or `R/data` depending on how RStudio chooses to process the chunk you are working in.
