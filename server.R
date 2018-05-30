#-----------------------------------------#
# Server.R UDPipe App
#-----------------------------------------#
# d1 <- 

shinyServer(function(input, output,session) {
  
  drec = reactive({
    loc_sub = loc_data[loc_data$e_key %in% input$entity & loc_data$city_id == input$city,1:3]
    loc_sub = merge(loc_sub,e_dt, by = 'e_key')
      })
  
  output$plot1 = renderUI({ 
    
    api="https://maps.googleapis.com/maps/api/js?key=AIzaSyBk1iNGBRPz1DQuKwtKzSwRFHckK996YPw"
    sample = drec()
    
    coordinates(sample) <-~ longitude +latitude # Create cordinates
    proj4string(sample) = CRS('+proj=longlat +datum=WGS84') # Add Projections
    
    m <- mcGoogleMaps(sample, mapTypeId='ROADMAP', zcol="entity",api = api,filename = 'myMap1.html', openMap = F)
    # plot(m)
    
    tags$iframe(
      srcdoc = paste(readLines('myMap1.html'), collapse = '\n'),
      width = "100%",
      height = "800px"
    )
    
  })
  
  
  output$plot2 = renderUI({ 
    
    api="https://maps.googleapis.com/maps/api/js?key=AIzaSyBk1iNGBRPz1DQuKwtKzSwRFHckK996YPw"
    loc_sub = drec()

    loc_sub$id = 1:nrow(loc_sub)
    loc_dt <- expand.grid.df(loc_sub,loc_sub)
    names(loc_dt)[9:10] <- c("latitude_dest","longitude_dest")
    # head(loc_dt)
    
    # calculate distances in meters:
    setDT(loc_dt)[ , dist_km := distGeo(matrix(c(longitude, latitude), ncol = 2),
                                        matrix(c(longitude_dest, latitude_dest), ncol = 2))/1000]
    distm = matrix(loc_dt$dist_km,sqrt(nrow(loc_dt)),sqrt(nrow(loc_dt)))
    rownames(distm) = loc_sub$id
    colnames(distm) = loc_sub$id
    
    # Create clusters based in distances
    fit <- hclust(as.dist(distm), method="ward")
    # plot(fit) # display dendogram

    groups <- cutree(fit, k=input$k) # cut tree into 18 clusters
    # # draw dendogram with red borders around the 18 clusters
    # rect.hclust(fit, k=10, border="red")
    
    loc_sub$group = groups # Assign cluster groups
    # # Plot stores with clustor as label
    sample = loc_sub
    
    coordinates(sample) <-~ longitude +latitude # Create cordinates
    proj4string(sample) = CRS('+proj=longlat +datum=WGS84') # Add Projections
    
    m <- mcGoogleMaps(sample, mapTypeId='ROADMAP', zcol="group",api = api,filename = 'myMap2.html', openMap = F)
    # plot(m)
    
    tags$iframe(
      srcdoc = paste(readLines('myMap2.html'), collapse = '\n'),
      width = "100%",
      height = "800px"
    )
    
  })
  
  output$leaf1 = renderLeaflet({
    icons <- awesomeIcons(
      icon = 'ios-close',
      iconColor = 'black',
      library = 'ion',
      markerColor = loc_sub$col
    )
    
    leaflet(drec()) %>% addTiles() %>% addAwesomeMarkers(~longitude, ~latitude, icon=icons, label=~as.character(entity))
    
  })
  
})
