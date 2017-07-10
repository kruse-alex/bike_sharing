# load packages
require(dplyr)
require(leaflet)
require(rgdal)
require(RColorBrewer)
require(shiny)

# server fuction
shinyServer(
  function(input, output, session){
    
    # setwd
    # setwd("C:/Users/akruse/Documents/Projekte_Weitere/stadtrad")
    
    # load hamburg shape for map
    hhshape <- readOGR(dsn = ".", layer = "HH_ALKIS_Landesgrenze")
    
    # load stations for markers on map
    station <- read.csv("HACKATHON_RENTAL_ZONE_CALL_A_BIKE.csv", sep = ";", encoding = "UTF-8")
    station <- filter(station, CITY == "Hamburg")
    station <- select(station, RENTAL_ZONE_GROUP, RENTAL_ZONE_X_COORDINATE, RENTAL_ZONE_Y_COORDINATE)
    station$RENTAL_ZONE_X_COORDINATE <- gsub(",",".",station$RENTAL_ZONE_X_COORDINATE)
    station$RENTAL_ZONE_Y_COORDINATE <- gsub(",",".",station$RENTAL_ZONE_Y_COORDINATE)
    station <- filter(station, RENTAL_ZONE_X_COORDINATE != "0.000000000000000")
    station <- filter(station, RENTAL_ZONE_Y_COORDINATE != "0.000000000000000")
    station <- filter(station, RENTAL_ZONE_Y_COORDINATE != "")
    station <- filter(station, RENTAL_ZONE_X_COORDINATE != "")
    station$RENTAL_ZONE_X_COORDINATE = as.numeric(station$RENTAL_ZONE_X_COORDINATE)
    station$RENTAL_ZONE_Y_COORDINATE = as.numeric(station$RENTAL_ZONE_Y_COORDINATE)
    
    # get pre-processed sp file
    sp_plot <- readOGR(dsn = "sp_files", layer = "june16")
    
    # color palette
    qpal <- colorQuantile(rev(brewer.pal(4, "YlGnBu")), NULL, n = 4)
    
    # create map
    output$stadtrad.map <-  renderLeaflet({
      withProgress(message = 'Erstelle interaktive Karte...',
      
      stadtrad.map <- leaflet(sp_plot) %>% 
        setView(lng = 9.992924, lat = 53.55100, zoom = 12) %>%
        addTiles('http://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                 attribution='Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>') %>%
        addPolygons(data = hhshape, stroke = T, smoothFactor = 0.05, fillOpacity = 0.05, color = "red", weight = 1, layerId = "notfoo") %>%
        addPolylines(popup = paste("Fahrten:",sp_plot@data$count),color = qpal(sp_plot@data$count),opacity = 1,weight = 1.5) %>%
        addCircleMarkers(lng = station$RENTAL_ZONE_X_COORDINATE, lat = station$RENTAL_ZONE_Y_COORDINATE, popup=station$RENTAL_ZONE_GROUP, fillOpacity = 100, color = "red", stroke = F, radius = 3, group="markers") %>%
        addLegend(position = 'bottomleft',colors =  rev(brewer.pal(5, "YlGnBu")),labels = c("sehr schwach","schwach","mittel","stark","sehr stark"),title = 'Frequentierung')
      )
      })
    
    # observer to view/hide markers
    observeEvent(input$show, {
      proxy <- leafletProxy('stadtrad.map')
      if (input$show) proxy %>% showGroup('markers')
      else proxy %>% hideGroup('markers')
    })
  })
