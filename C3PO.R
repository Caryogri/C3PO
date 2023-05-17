library(shiny)
library(shinyjs)
library(stringr)
library(yaml)
library(data.table)
library(Matrix)
library(splitstackshape)
library(Rutilitybelt)
library(r2d3)
library(jsonlite)
library(rsvg)
library(aws.s3)

pathing = yaml.load_file("data/onlinePathing.yaml")
awsInfo = yaml.load_file("data/awsInfo.yaml")

if (bucket_exists(awsInfo$bucketName, key = awsInfo$awsAccessKey, secret = awsInfo$awsSecretAccessKey)) {
  bucketInfo = as.data.table(get_bucket_df(awsInfo$bucketName, key = awsInfo$awsAccessKey, secret = awsInfo$awsSecretAccessKey))
  availableCancerTypes = union(pathing$bucketCancerTypes, bucketInfo[!str_detect(Key, "Pre-Filtered Matrices")][, Key := str_replace(Key, "\\..+", "")]$Key)
  awsConnected = TRUE
} else {
  availableCancerTypes = pathing$serverCancerTypes
  awsConnected = FALSE
}

nests = fread(file = "data/TheNEST.csv", header = FALSE, col.names=c("NEST", "Description", "Genes"))
nests = nests[, list(NEST, Genes)]
nests = cSplit(nests, "Genes", sep = " ", direction = "long")

allNests = unique(nests[,"NEST"])

hallmarks = fread(file = "data/hallmarks.tsv")
hallmarks = melt(hallmarks, id.vars = "Genes", variable.name = "Hallmark", value.name = "Value", na.rm = TRUE)
hallmarks = hallmarks[Value %chin% c("Y")]
hallmarks = hallmarks[, !c("Value")]
hallmarks = hallmarks[order(Genes)]

hallmarkImagePaths = fread(file = "data/hallmarkImagePathing.csv")

proteinIndex = fread("data/masterProteinIndex.tsv")

#sets max upload size to 50MB
options(shiny.maxRequestSize = 50 * 1024^2)


# Define UI for data upload app ----
ui <- fluidPage(
  
  useShinyjs(),
  
  # App title ----
  titlePanel("Combined Polygenetic Protein Prediction Algorithm for Oncology (C3PO)"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      #Input: Button to load example data.
      actionLink("useExampleData", "Load example data"),
      
      tags$h5("OR"),
      
      # Input: Select a file ----
      fileInput("file1", "Choose delimited File",
                multiple = FALSE,
                accept = c("text/csv",
                           "text/comma-separated-values,text/plain",
                           ".csv","text/tsv",
                           "text/tab-separated-values,text/plain",
                           ".tsv", ".txt")),
      
      # Horizontal line ----
      #tags$hr(),
      
      # Input: Checkbox if file has header ----
      checkboxInput("header", "File has a Header", TRUE),
      
      #Input: Select "Gene Column" ----
      selectInput("geneCol", "Gene Column", "Upload File..."),
      
      #Input: Select "Sample Column" ----
      selectInput("sampleCol", "Sample Column", "Upload File..."),
      
      
      # Horizontal line ----
      tags$hr(),
      
      # Input: Checkbox if file has cancer column ----
      checkboxInput("hasCCol", "File has column specifying cancer type", TRUE),
      
      #Input: Select "Cancer Type Column" ----
      selectInput("cancerTypeCol", "Cancer Type Column", "Upload File..."),
      
      #Input: Select "Cancer Type" ----
      selectInput("cancerType", "Cancer Type", availableCancerTypes, selected = "PANCAN"),
      
      # Horizontal line ----
      tags$hr(),
      
      # Input: Checkbox if using custom P-Values ----
      checkboxInput("useCustomP", "Use custom P-Value (SLOWER)", FALSE),
      
      # Input: Simple integer interval ----
      selectInput("pValPreGen", "P-Value:", pathing$pValues, selected = 0.05),
      
      # Input: Simple integer interval ----
      sliderInput("pValCustom", "P-Value:",
                  min = 0, max = 1,
                  value = 0.05, step = 0.01),
      
      # Input: Weights table checkboxes ----
      checkboxGroupInput("includedWeights", "Weights:", names(pathing$paths), names(pathing$paths)),
      
      # Horizontal line ----
      tags$hr(),
      
      sliderInput("numHallmarks", "Number of Hallmarks", min = 2, max = 21, value = 3, step = 1, ticks = FALSE)
      
      
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      tabsetPanel(type = "tabs",
                  tabPanel("Diagram",
                           d3Output("diagram", width = "100%", height="50em"),
                           downloadButton("downloadSVG", "Download plot as SVG"),
                           downloadButton("downloadPNG", "Download plot as PNG"),
                           tableOutput("clickInfo"),
                           dataTableOutput("selectedSamples"),
                           downloadButton("downloadSamplesList", "Download Sample List")
                  ),
                  tabPanel("Preview Upload", dataTableOutput("upload")),
                  tabPanel("Instructions", uiOutput("readme"))
      )
    )
    
  )
)

server <- function(input, output, session) {
  
  rv = reactiveValues()
  rv$exampleDataLoaded = FALSE
  
  if (awsConnected == FALSE) {
    print(awsConnected)
    showNotification("Connection to AWS not found. Using limited datasets. Please contact developers to notify them of issue.")
  }
  
  observe({
    
    req(input$file1)
    disable("downloadSamplesList")
    print("Reading file...")
    
    tryCatch(
      {
        rv$sampleGenesInput <- fread(file = input$file1$datapath, header = input$header)
        cNames = names(rv$sampleGenesInput)
      },
      error = function(e) {
        # return a safeError if a parsing error occurs
        stop(safeError(e))
      }
    )
    
    columns = reactive({
      cNames
    })
    observe({
      updateSelectInput(session, "geneCol", choices=columns())
      updateSelectInput(session, "sampleCol", choices=columns())
      updateSelectInput(session, "cancerTypeCol", choices=columns())
    })
    
    rv$exampleDataLoaded = FALSE
    
    enable("geneCol")
    enable("sampleCol")
    enable("hasCCol")
    enable("cancerTypeCol")
  })
  
  output$upload <- renderDataTable({
    return(rv$sampleGenesInput)
  })
  
  observeEvent(input$hasCCol, {
    toggleState("cancerTypeCol", condition = (input$hasCCol & rv$exampleDataLoaded == FALSE))
  })
  
  observeEvent(input$useCustomP, {
    toggle("pValPreGen", condition = !input$useCustomP)
    toggle("pValCustom", condition = input$useCustomP)
  })
  
  observeEvent(input$useExampleData, {
    rv$exampleDataLoaded = TRUE
    disable("downloadSamplesList")
    rv$sampleGenesInput <- fread(file = "data/CPTAC_maf_annotated_simplified.txt", header = TRUE)
    cNames = names(rv$sampleGenesInput)
    
    columns = reactive({
      cNames
    })
    observe({
      updateSelectInput(session, "geneCol", choices=columns(), selected = "Hugo_Symbol")
      updateSelectInput(session, "sampleCol", choices=columns(), selected = "Tumor_Sample_Barcode")
      updateSelectInput(session, "cancerTypeCol", choices=columns(), selected = "COHORT")
    })
    
    updateCheckboxInput(session, "hasCCol", value = TRUE)
    
    disable("geneCol")
    disable("sampleCol")
    disable("hasCCol")
    disable("cancerTypeCol")
    
  })
  
  samplesByNest <- reactive({
    req(rv$sampleGenesInput)
    gCol = input$geneCol
    sCol = input$sampleCol
    cCol = input$cancerTypeCol
    
    if ((input$geneCol != input$sampleCol) & ((input$hasCCol & (input$cancerTypeCol != input$geneCol) & (input$sampleCol != input$cancerTypeCol)) | !input$hasCCol)) {
      print(str_c("samplesByNest: ", gCol, ", ", sCol, ", ", cCol))
      withProgress(value = 0, message = "Creating sample matrix", {
        samples = copy(rv$sampleGenesInput)
        setnames(samples, sCol, "Samples", skip_absent = TRUE)
        setnames(samples, gCol, "Genes", skip_absent = TRUE)
        if (input$hasCCol & (input$cancerType != "PANCAN")) {
          setnames(samples, cCol, "cancerType", skip_absent = TRUE)
          samples = samples[,list(Samples, Genes, cancerType)]
          samples = samples[cancerType == input$cancerType]
        }
        samples = samples[,list(Samples, Genes)]
        incProgress(.2)
        #view(samples)
        samples = unique(samples)
        samples = merge(samples, nests, all = TRUE, by = "Genes", allow.cartesian = TRUE)
        samples = na.omit(samples, cols = 2:3)
        incProgress(.2)
        samples = samples[, !"Genes"]
        samples = unique(samples)
        samples = samples[, Value := 1]
        samples = merge(samples, allNests, all = TRUE, by = "NEST", allow.cartesian = TRUE)
        incProgress(.2)
        samples[, "Value"][is.na(samples[, "Value"])] = 0
        samples = dcast(samples, Samples ~ NEST, fun = mean, fill = 0)
        samples = na.omit(samples, cols = 1)
        incProgress(.2)
        
        samples = as.matrix(samples, rownames = 1)
        incProgress(.2)
      })
      
      
      #print(dim(samples))
      #view(samples)
      print("samplesByNest: DONE")
      return(samples)
    }
  })
  
  nestByProtein <- reactive({
    if (input$useCustomP & !(input$pValCustom %in% pathing$pValues)) {
      matrices = nestByProteinCustom()
    } else {
      matrices = nestByProteinPreGen()
    }
    
    return(matrices)
  })
  
  nestByProteinRead <- reactive({
    cancer = input$cancerType
    matrices = list()
    
    disable("downloadSamplesList")
    withProgress(message = 'Downloading weight data', value = 0, {
      n = length(names(pathing$paths))
      
      for (weightSource in names(pathing$paths)) {
        if (cancer %in% pathing$serverCancerTypes) {
          fileName = str_c(pathing$serverPath, cancer, pathing$paths[[weightSource]])
          proteins = fread(file = fileName)
          incProgress(1/(n*2), detail = str_c(cancer, " ", weightSource))
        } else {
          fileName = str_c(cancer, pathing$paths[[weightSource]])
          proteins = get_object(fileName, awsInfo$bucketName, as = "text", key = awsInfo$awsAccessKey, secret = awsInfo$awsSecretAccessKey)
          incProgress(1/(n*2), detail = str_c(cancer, " ", weightSource))
          proteins = fread(text = proteins)
        }
        
        proteins = proteins[,list(NESTv1, Protein, TPVALUE, COHEN_D)]
        setnames(proteins, old = "NESTv1", new = "NEST")
        proteins = unique(proteins)
        
        matrices[[weightSource]] = proteins
        incProgress(1/(n*2), detail = str_c(cancer, " ", weightSource))
      }
    })
    
    return(matrices)
  })
  
  nestByProteinCustom <- reactive({
    matrices = nestByProteinRead()
    cancer = input$cancerType
    pValue = input$pValCustom
    
    
    disable("downloadSamplesList")
    
    withProgress(message = 'Generating weight matrices', value = 0, {
      n = length(names(pathing$paths))
      
      for (weightSource in names(pathing$paths)) {
        if (pValue == input$pValCustom) {
          proteins = matrices[[weightSource]]
          
          proteins = proteins[TPVALUE < pValue]
          proteins = proteins[, !"TPVALUE"]
          proteins = merge(proteins, proteinIndex, all = TRUE, by = c("NEST", "Protein"))
          proteins[, "COHEN_D"][is.na(proteins[, "COHEN_D"])] = 0
          #proteins = dcast(proteins, NEST ~ factor(Protein, levels = proteinIndex[, Protein][c(-1)]), fill = 0)
          proteins = dcast(proteins, NEST ~ Protein, fill = 0, value.var = "COHEN_D")
          proteins = as.matrix(proteins, rownames = 1)
          
          matrices[[weightSource]] = proteins
          incProgress(1/n, detail = str_c(cancer, " ", weightSource, " - ", pValue))
        } else {
          return(NULL)
        }
      }
    })
    
    print("nestByProtein: DONE")
    #view(matrices)
    return(matrices)
  })
  
  nestByProteinPreGen <- reactive({
    cancer = input$cancerType
    pValue = input$pValPreGen
    matrices = list()
    
    disable("downloadSamplesList")
    
    withProgress(message = 'Downloading weight matrices', value = 0, {
      n = length(names(pathing$paths))
      for (weightSource in names(pathing$paths)) {
        if (pValue == input$pValPreGen) {
          if (cancer %in% pathing$serverCancerTypes) {
            fileName = str_c(pathing$serverPath, pathing$pPathServer, "DT.", cancer, ".", pValue, pathing$paths[[weightSource]])
            fileName = str_replace(fileName, ".txt", ".tsv")
            incProgress(1/(n*2), detail = str_c(cancer, " ", weightSource, " - ", pValue))
            proteins = fread(file = fileName)
            incProgress(1/(n*2), detail = str_c(cancer, " ", weightSource, " - ", pValue))
          } else {
            fileName = str_c(pathing$pPathServer, "DT.", cancer, ".", pValue, pathing$paths[[weightSource]])
            fileName = str_replace(fileName, ".txt", ".tsv")
            proteins = get_object(fileName, awsInfo$bucketName, as = "text", key = awsInfo$awsAccessKey, secret = awsInfo$awsSecretAccessKey)
            incProgress(1/(n*2), detail = str_c(cancer, " ", weightSource, " - ", pValue))
            proteins = fread(text = proteins)
          }
          print(str_c("nestByProtein: ", cancer, ", ", pValue, ", ", weightSource))
          proteins = as.matrix(proteins, rownames = 1)
          
          
          matrices[[weightSource]] = proteins
          incProgress(1/(n*2), detail = str_c(cancer, " ", weightSource, " - ", pValue))
          #print(dim(proteins))
        } else {
          return(NULL)
        }
      }
      
      rm(proteins)
    })
    
    print("nestByProtein: DONE")
    #view(matrices)
    return(matrices)
  })
  
  sumMatrices <- reactive({
    req(nestByProtein())
    
    disable("downloadSamplesList")
    
    print(str_c("sumMatrices: ", input$includedWeights))
    
    matrices = nestByProtein()
    
    sMatrix = NULL
    
    withProgress(value = 0, message = "Summing weight matrices", {
      n = length(input$includedWeights)
      
      for (weightSource in input$includedWeights) {
        if (is.null(sMatrix)) {
          sMatrix = matrices[[weightSource]]
          #print(typeof(matrices[[weightSource]]))
        } else {
          sMatrix = sMatrix + matrices[[weightSource]]
        }
        incProgress(1/n, detail = str_c(weightSource))
      }
    })
    
    rm(matrices)
    print(str_c("sumMatrices: DONE, ", typeof(sMatrix)))
    return(sMatrix)
  })
  
  finalMatrix <- reactive({
    req(samplesByNest())
    #req(sumMatrices())
    
    print("finalMatrix")
    final = NULL
    sam = Matrix(samplesByNest(), sparse = T)
    sum = Matrix(sumMatrices(), sparse = T)
    #view(sam)
    #view(sum)
    #print(dim(sam))
    #print(dim(sum))
    
    withProgress(value = 0, message = "Multiplying matrices", {
      final = sam %*% sum
      incProgress(1)
    })
    
    return(final)
  })
  
  productMatrix <- reactive({
    req(finalMatrix)
    
    product = finalMatrix()
    
    result = as.data.table(as.matrix(product), keep.rownames = "Sample")
    rm(product)
    return(result)
  })
  
  getD3Input <- reactive({
    req(productMatrix())
    d3Input = NULL
    
    withProgress(value = 0, message = "Analyzing hallmark data", {
      d3Input = melt(productMatrix(), id.vars = "Sample", variable.name = "Genes", value.name = "COHEN_D")
      incProgress(0.1)
      numSamples = length(unique(d3Input$Sample))
      d3Input = merge(d3Input, hallmarks, all.x = TRUE, by = "Genes", allow.cartesian = TRUE)
      incProgress(0.1)
      d3Input = na.omit(d3Input, cols = 4)
      d3Input = d3Input[, !c("Genes")]
      d3Input = d3Input[, keyby = .(Sample, Hallmark), .(Score = sum(abs(COHEN_D)) / .N)]
      d3Input = d3Input[order(Sample, -Score)]
      d3Input = d3Input[, hallmarkRank := str_c("Hallmark", seq_len(.N)), by = "Sample"]
      d3Input = d3Input[, head(.SD, input$numHallmarks), by = Sample]#Select num hallmarks per sample
      incProgress(0.2)
      d3Input = d3Input[,!c("Score")]
      
      d3Input2 = copy(d3Input)
      
      d3Input = dcast(d3Input, Sample~hallmarkRank, value.var= "Hallmark")
      
      incProgress(0.2)
      
      hallmarkCols = colnames(d3Input)[c(-1)]
      
      rv$ranked = group_nest_dt(d3Input, group_vars = hallmarkCols)
      
      incProgress(0.2)
      
      d3Input = d3Input[, !c("Sample")]
      d3Input = d3Input[, Value := 1]
      
      d3Input = d3Input[, keyby = hallmarkCols, .(Count = sum(Value))]
      #print(d3Input)
      
      d3Input2 = d3Input2[, !c("hallmarkRank")]
      d3Input2 = d3Input2[, Present := 1]
      d3Input2 = d3Input2[, !c("Sample")]
      d3Input2 = d3Input2[, keyby = Hallmark, .(Count = sum(Present))]
      d3Input2 = merge(d3Input2, unique(hallmarks[,.(Hallmark)]), by = "Hallmark", all = TRUE)
      d3Input2 = d3Input2[, proportion := (Count / numSamples)]
      d3Input2[, "proportion"][is.na(d3Input2[, "proportion"])] = 0
      d3Input2 = d3Input2[, !c("Count")]
      d3Input2 = d3Input2[, size := 1]
      d3Input2 = d3Input2[, connections := 0]
      d3Input2 = d3Input2[, order := .I]
      d3Input2 = merge(d3Input2, hallmarkImagePaths, all = TRUE)[order(order)]
      d3Input2 = d3Input2[, !c("order")]
      setnames(d3Input2, "Hallmark", "name")
      
      incProgress(0.2)
      #rv$topHallmarkIndices = c(-1,-1)
      
      
    })
    #print(d3Input2)
    combined = list(d3Input, d3Input2)
    #print(dput(combined))
    rm(d3Input)
    rm(d3Input2)
    return(toJSON(combined))
  })
  
  output$diagram <- renderD3({
    print("Displaying d3")
    disable("downloadSamplesList")
    disable("downloadSVG")
    disable("downloadPNG")
    r2d3(getD3Input(), script = "data/d3Plot.js", d3_version = 4)
  })
  
  output$clickInfo <- renderTable({
    req(getD3Input(), input$selectedPathData)
    
    selectedHallmarks = as.data.table(input$selectedPathData)
    setkeyv(rv$ranked, colnames(rv$ranked[, !c("data")]))
    rv$selected = unique(rv$ranked[selectedHallmarks[,!c("Count")], nomatch = 0])[1][["data"]][[1]]
    
    return(selectedHallmarks)
  })
  
  output$selectedSamples <- renderDataTable({
    req(getD3Input(), rv$selected)
    enable("downloadSamplesList")
    return(rv$selected)
  })
  
  output$downloadSamplesList <- downloadHandler(
    filename = function() {
      if (rv$exampleDataLoaded == TRUE) {
        return(str_c("c3poSample_CPTAC_", input$cancerType, "_", rv$pValue, ".txt"))
      } else  {
        return(str_c(str_replace(input$file1$name, "\\..+$", ""), "_", input$cancerType, "_", rv$pValue, ".txt"))
      }
    },
    content = function(file) {
      fwrite(rv$selected, file = file, sep = "\t")
    })
  
  output$downloadSVG <- downloadHandler(
    filename = function() {
      if (rv$exampleDataLoaded == TRUE) {
        return(str_c("c3poSample_CPTAC_", input$cancerType, "_", rv$pValue, "_plot.svg"))
      } else  {
        return(str_c(str_replace(input$file1$name, "\\..+$", ""), "_", input$cancerType, "_", rv$pValue, "_plot.svg"))
      }
    },
    content = function(file) {
      write(input$d3SVG, file = file)
    },
    contentType = "image/svg+xml"
  )
  
  output$downloadPNG <- downloadHandler(
    filename = function() {
      if (rv$exampleDataLoaded == TRUE) {
        return(str_c("c3poSample_CPTAC_", input$cancerType, "_", rv$pValue, "_plot.png"))
      } else  {
        return(str_c(str_replace(input$file1$name, "\\..+$", ""), "_", input$cancerType, "_", rv$pValue, "_plot.png"))
      }
    },
    content = function(file) {
      rsvg_png(charToRaw(input$d3SVG), file = file)
    },
    contentType = "image/png"
  )
  
  disable("downloadSamplesList")
  
  disable("downloadSVG")
  
  disable("downloadPNG")
  
  observe({
    req(input$d3SVG)
    enable("downloadSVG")
    enable("downloadPNG")
  })
  
  output$readme <- renderUI({
    includeMarkdown("README.md")
  })
  
}

# Create Shiny app ----
shinyApp(ui, server)