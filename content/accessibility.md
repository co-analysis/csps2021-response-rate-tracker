---
title: "Accessibility statement"
date: 2021-02-01
type: meta
---

{{< warning "This tool is currently under development and has not yet been fully tested for accessibility." >}}

This tool is built by the Cabinet Office's Analysis & Insight Directorate. We want as many people as possible to be able to use this website. For example, that means you should be able to:

-  change colours, contrast levels and fonts
- zoom in up to 300% without the text spilling off the screen
- navigate most of the website using just a keyboard
- navigate most of the website using speech recognition software
- listen to most of the website using a screen reader (including the most recent versions of JAWS, NVDA and VoiceOver)
- We’ve also made the website text as simple as possible to understand.


## Reporting accessibility problems with this website
We're always looking to improve the accessibility of this website. If you find any problems not listed on this page or think we're not meeting accessibility requirements, please contact the Civil Service People Survey team in the Cabinet Office on peoplesurveyhelpdesk@cabinetoffice.gov.uk. If you are a developer you can make technical suggestions by [raising an issue on GitHub](https://github.com/co-analysis/csps2021-response-rate-tracker/issues).

## Enforcement procedure
The Equality and Human Rights Commission (EHRC) is responsible for enforcing the Public Sector Bodies (Websites and Mobile Applications) (No. 2) Accessibility Regulations 2018 (the ‘accessibility regulations’). If you're not happy with how we respond to your complaint, contact the [Equality Advisory and Support Service (EASS)](https://www.equalityadvisoryservice.com/).


## Technical information about this website’s accessibility

This website is under development and has not yet been fully assessed for compliance with WCAG 2.1, we are committed to making this tool accessible, in accordance with the Public Sector Bodies (Websites and Mobile Applications) (No. 2) Accessibility Regulations 2018.

We are using the [IBM Accessibility Toolkit](https://www.ibm.com/able/toolkit/tools/) extension in Firefox to assess accessibility issues as we build and develop the tool, and we are aware of the following compliance issues.

### Interactive tables
The interactive tables in the tool use the DataTables JavaScript library, as implemented through the [DT package](https://rstudio.github.io/DT/) for R.

The R package and JavaScript library construct a table with the HTML role attribute of 'grid' but it does give the table a title or an ARIA-compliant label. The 'grid' role also means that the content of the interactive tables and table pagination controls are not accessible by keyboard navigation, this is also a function of the package used to construct the table.

The table content can be copied using the "Copy" button or downloaded as a file using the "CSV" button in the table's footer. These buttons are accessible by keyboard navigation.

## Preparation of this accessibility statement
This statement was prepared on 7 October 2020.
