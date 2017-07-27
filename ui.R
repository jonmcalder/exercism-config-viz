
library(shiny)
library(visNetwork)
library(shinycssloaders)

shinyUI(fluidPage(

  # Application title
  titlePanel("Config visualizer for exercism.io"),

  fluidRow(
    
    sidebarLayout(
      sidebarPanel(
        # Specify config.json file
        radioButtons("config_mode", "Mode", 
                     choiceNames = c("File upload", "View example"), 
                     choiceValues = c("file", "example")
        ),
        helpText("Upload config.json or select one of the example configs"),
        conditionalPanel(
          condition = "input.config_mode == 'file'",
          fileInput("config_file", label = "Upload file")
        ),
        conditionalPanel(
          condition = "input.config_mode == 'example'",
          selectInput("config_example", label = "Choose example config", 
                    choices = c("none", "javascript", "r"))
        )
      ),
      
      # Render visualization of the track config
      mainPanel(
        visNetworkOutput("track_view", width = "100%", height = "800px") %>% 
          withSpinner()
      )
    )
  )
))
