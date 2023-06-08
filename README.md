# Combined Polygenetic Protein Prediction Algorithm for Oncology (C3PO)

------------------------------------------------------------------------

The Combined Polygenetic Protein Prediction Algorithm for Oncology (C3PO) is an R Shiny based tool which uses genetic and proteomic data to perform predictions applying the Hallmarks of Cancer [(Hanahan, 2022).](https://pubmed.ncbi.nlm.nih.gov/35022204/) More can be read about C3PO's model at [EVENTUAL PAPER URL].

C3PO is available as a webtool at [mbailey.shinyapps.io/C3PO](mbailey.shinyapps.io/C3PO) or can be run through R Studio on a local machine (see [Running on your local machine]).

## How to use

### 1. Data formatting requirements

In order to make its predictions, C3PO requires tumor mutation data in the form of a text-delimited file (.csv, .tsv, etc.). Each row in this text-delimited document should contain the following data points:

1.  A single HGNC identifier for the mutant gene
2.  A unique sample ID
3.  (Optional) A cancer type identifier (see [Filtering by cancer type])

The uploaded document may contain additional data columns, however, they will not be used as part of C3PO's calculations.

An input document may look something like this:

| Sample ID | Gene  | Cohort | ... |
|-----------|-------|--------|-----|
| Sample1   | Gene1 | BCRA   | ... |
| Sample1   | Gene3 | BCRA   | ... |
| Sample2   | Gene2 | OV     | ... |
| Sample3   | Gene1 | BCRA   | ... |
| ...       | ...   | ...    | ... |

As shown above, if a sample contains multiple mutations, make sure to include a separate row for each mutation in the input document.

### 2. Uploading data

To upload your input file, click on the "Browse..." button beneath the "Choose delimited File" heading on the left hand side of the window. Select the your input file using your systems file browser and the upload will begin. Upload file size is limited to 50 MB or less. You can preview the contents of the uploaded file by opening the "Preview Upload" tab at the top of the tool's window.

With your data uploaded, you must indicate the following:

-   Whether your file contains a header row - to do this simply check the "File has a header box". If your file does not contain a header row, un-checking this box will generate temporary headers to allow for the correct processing of the data.
-   The column containing the HGNC Gene ID - this is done by selecting the column name using the dropdown menu under the "Gene Column" heading.
-   The column containing the Sample ID - this is done by selecting the column name using the dropdown menu under the "Sample Column" heading.
-   (Optional) The column specifying cancer type - make sure that the "File has a column specifying cancer type" box is checked. Select the column name from the dropdown menu under the "Cancer Type Column" heading.

Once all these values have been specified, C3PO will begin an inital calculation using the currently selected options.

If you are using the version of C3PO hosted on shinyapps.io, you can also choose to use provided sample data by clicking on the "Load sample data" link at the top of the sidebar.

### 3. Computation options

C3PO offers several options for customizing both its analysis and output. These can be selected using the options pane on the left side of the window.

#### Filtering by cancer type

C3PO can base its analysis on training data from a specific cancer type. This is done by selecting the desired type from the dropdown menu below the "Cancer Type" heading. If you select the "PANCAN" option from this menu, the analysis peformed will not be specific to a single cancer type, but rather use data from all cancer types to perform the analysis.

The cancer types available are:

-   BRCA -\> Breast invasive carcinoma

-   CCRCC -\> Clear renal cell carcinoma

-   COAD -\> Colon adenocarcinoma

-   GBM -\> Glioblastoma multiforme

-   HNSCC -\> Head and neck squamous cell carcinoma

-   LSCC -\> Lung squamous cell carcinoma

-   LUAD -\> Lung adenocarcinoma

-   OV -\> Ovarian serous cystadenocarcinoma

-   PDAC -\> Pancreatic ductal adenocarcinoma

-   UCEC -\> Uterine corpus enodmetrial carcinoma

If your input data contains a data column specifying cancer type, selecting a specific cancer type from the list above will only apply the targeted analysis to the samples marked with the selected cohort; just make sure to use the acronyms used in the above list. In this way, you can perform analysis on input data containing samples from multiple different cancer types without skewing your results.

If your input data doesn't contain a column specifying cancer type, regardless of the cancer types present, analysis will be performed on the entirety of the input data using the selected cancer type.

#### Filtering by p-value

C3PO allows you to filter the data used for the analysis by significance. You do this using one of the following methods:

1.  Use the pre-filtered prediction scores with p-values at or below 0.01, 0.05, 0.10, 0.50, or 0.80 - this is done by un-checking the "Use custom p-values" box and selecting the desired threshold from the dropdown menu under the "P-Value" heading.
2.  Select a custom p-value threshold - this is done by checking the "Use custom p-values" and selecting the desired threshold using the slider. If you chose to use this method, please note that the computation process will take much longer as the tool needs to refilter the prediction scores.

Prediction scores with p-values above the specified threshold will not be used in the analysis, meaning all predictive data used will have p-values at or below the specified threshold.

#### Filtering by mutation type

C3PO performs its predictions using data derived from three forms of mutation: Amplification, Deletion, and small-scale mutations. The summative nature of C3POs model allows these different data sources to be added or subtracted as desired. To do this simply check the boxes of the mutation types you wish to use in your analysis.

#### Selecting number of top hallmarks

To select the top hallmarks to display, use the slider below the "Number of Hallmarks" heading to select the desired amount.

### 4. Viewing output

C3PO uses d3.js to produce an interactive circos plot showing the combinations of top predicted hallmarks in the input data.

The segmented circle contains icons representing the different Hallmarks of Cancer. Each segment displays the hallmarks predicted overall prevalence in the data using a blue-colored bar. The size of this bar is relative to the overall prevalence of the that hallmark and is square-root normalized to allow the presence of less-prevalent hallmarks to be visualized. Hovering your mouse over these segments will display a tooltip indicating the name of the hallmark and the percentage of samples the hallmark is predicted to be utilized by.

The interior of the circle contains multiple lines which touch multiple hallmarks on the circle. Each of these lines represent a different permutation of hallmark combinations predicted to be in the uploaded data. Hovering your mouse over these lines will display a tooltip indicating the combination of hallmarks represented by the line as well as the number of samples predicted to apply to this combination of hallmarks. Clicking on the line will display a list of the samples in this combination below the plot.

### 5. Downloading results

The image output by C3PO can be downloaded as either a PNG or an SVG and can be done by clicking on the "Download plot as PNG" button and the "Download plot as SVG" button respectively. Doing this will preserve the selected state of any of the lines in the plot.

The list of samples shown when clicking on a line in the plot can also be downloaded as a text file and can be done by clicking on the "Download sample list" button.

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

Once you have acquired all supporting files and package dependencies, open your clone of the C3PO repository in R Studio. C3PO now be run by opening the "app.R" script and clicking the "Run App"button in the upper right-hand corner of the code window.
