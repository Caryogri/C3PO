requiredPackages = c("remotes", "shiny", "shinyjs", "stringr", "yaml",
                    "data.table", "Matrix", "splitstackshape",
                    "r2d3", "jsonlite", "rsvg", "aws.s3", "markdown")

installed_packages <- requiredPackages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

if(!"Rutilitybelt" %in% installed.packages()) {
  remotes::install_github('qdread/Rutilitybelt')
}
