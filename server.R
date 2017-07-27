
library(shiny)
library(dplyr)
library(jsonlite)
library(visNetwork)

shinyServer(function(input, output) {
  
  output$track_view <- renderVisNetwork({
    
    # Create a Progress object
    progress <- shiny::Progress$new()
    
    # Make sure it closes when reactive is exited, even if there's an error
    on.exit(progress$close())
    
    progress$set(value = 0.3, message = "Creating visualization",
                 detail = "Reading")
    
    if (input$config_mode == "example") {
      
      # Check for input
      shiny::validate(
        need(input$config_example != 'none', message = "Please choose an example config")
      )
      
      config <- fromJSON(paste0(input$config_example, ".json"))
      
    } else {
      
      # Check for input
      shiny::validate(
        need(input$config_file, message = "Please provide a 'config.json' file")
      )
      
      # Attempt to load JSON
      try(config <- fromJSON(input$config_file$datapath), silent = TRUE)
      
    }
    
    # Check that input is valid
    shiny::validate(
      need(exists("config"), message = "Problem with file/invalid JSON")
    )
    
    progress$set(value = 0.5, detail = "Parsing")
    
    if (is.null(config$exercises$deprecated)) {
      config$exercises$deprecated <- NA  
    }
    
    # Build nodes data frame from exercise data
    nodes <- config$exercises %>% 
      rename(id = slug) %>% 
      mutate(label = id,
             group = case_when(
               deprecated ~ "deprecated",
               core ~ "core",
               is.na(unlocked_by) ~ "floating",
               !is.na(unlocked_by) ~ "bonus"
             ),
             title = topics,
             topics = sapply(config$exercises$topics, paste0, collapse = ",")) %>% 
      select(id, label, group, title, topics)
    
    # Get names for core exercises (used to create edges between core exercises)
    core_exercises <- nodes %>% 
      filter(group == "core") %>% 
      select(id)
    
    # Build edges data frame from core exercises and unlocked_by attributes
    from = config$exercises$unlocked_by[!is.na(config$exercises$unlocked_by)] %>% 
      c(core_exercises$id[1:nrow(core_exercises) - 1])
    
    to = config$exercises$slug[!is.na(config$exercises$unlocked_by)] %>% 
      c(core_exercises$id[-1])
    
    edges <- data.frame(from = from, to = to)
    
    progress$set(value = 0.8, detail = "Rendering")
    
    # Create network visualization
    visNetwork(nodes, edges, 
        main = paste0("Track config for ", config$language)) %>% 
      visNodes(shape = "box") %>% 
      visEdges(smooth = FALSE, arrows = "to", width = 2) %>% 
      visOptions(highlightNearest = list(enabled = T, degree = 1)) %>%
      visOptions(selectedBy = list(variable = "topics", multiple = T)) %>%
      visLegend(position = "right") %>%
      visInteraction(navigationButtons = TRUE, hideEdgesOnDrag = TRUE)
      
  })
  
})
