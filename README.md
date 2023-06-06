# Combined Polygenetic Protein Prediction Algorithm for Oncology (C3PO)

------------------------------------------------------------------------

C3PO is available as a webtool at [mbailey.shinyapps.io/C3PO](mbailey.shinyapps.io/C3PO) or can be run through R Studio on a local machine (see [Running on your local machine]).

## How to use

### 1. Data formatting requirements

### 2. Uploading data

### 3. Computation options

### 4. Viewing output

### 5. Downloading results

## Running on your local machine

As an R Shiny application, C3PO is quite portable and is easy to get running on your local machine. The benefit to this over the web-hosted version is not having to wait for C3PO to download the data it needs to run from AWS.

### System requirements

1.  An installation of R (Version 4.0 or greater recommended)
2.  R Studio
3.  At least 4 GB of RAM is recommended

### Installation

1.  Clone the GitHub repository to a directory of your choice on your local machine.
2.  Download and unzip the archive from [EVENTUAL HOST URL] and place the "Weights" folder in "C3PO/data".

### Package dependencies

Packages required by C3PO can be installed manually from CRAN and GitHub or through running the "installDependancies.R" script.

### Running the app

Once you have acquired all supporting files and package dependencies, open your clone of the C3PO repository in R Studio. C3PO now be run by opening the "C3PO.R" script and clicking the "Run App"button in the upper right-hand corner of the code window.
