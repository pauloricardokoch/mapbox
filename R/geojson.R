library("jsonlite", lib.loc = "~/R/x86_64-redhat-linux-gnu-library/3.5")

filter <- function(weatherData, iTime, estado) {
  tabela <- weatherData
  if ((length(estado) == 1) & (estado == "BR"))
    shape_estado <- shape_br
  else
    shape_estado <- shape_br[shape_br$sigla %in% estado,]
  
  pontos                  <- data.frame(tabela$LONGITUDE, tabela$LATITUDE, tabela[, iTime])
  colnames(pontos)        <- c("LONGITUDE", "LATITUDE", iTime)
  sp::coordinates(pontos) <- c("LONGITUDE", "LATITUDE")
  sp::proj4string(pontos) <- sp::proj4string(shape_estado)
  new_pontos              <- tabela[!is.na(sp::over(pontos, as(shape_estado, "SpatialPolygons"))),]
  
  tab_raster     <- raster::rasterFromXYZ(new_pontos)
  r              <- raster::raster(tab_raster, layer = grep(iTime, colnames(new_pontos)))
  raster::crs(r) <- sp::CRS("+init=epsg:4326")
  
  return(data.frame(new_pontos$LONGITUDE, new_pontos$LATITUDE, new_pontos[, iTime]))
}

feature <- function(state) {
  features <- list()
  index    <- 0
  for (col in colnames(TP2M))
  {
    if (col != "LATITUDE" && col != "LONGITUDE" && col > 2017082423)
    {
      temperature   <- filter(TP2M, col, state)
      humidity      <- filter(UR2M, col, state)
      precipitation <- filter(PREC, col, state)
      wind          <- filter(V10M, col, state)
      radiation     <- filter(OCIS, col, state)
      
      for (row in 1:nrow(temperature))
      {
        y    <- substr(col, start = 1, stop = 4)
        m    <- substr(col, start = 5, stop = 6)
        d    <- substr(col, start = 7, stop = 8)
        h    <- substr(col, start = 9, stop = 10)
        date <- paste(paste(y, m, d, sep = "-"), paste(h, "00", "00", sep = ":"), sep = " ")
        
        feature <- list()
        feature[[length(feature) + 1]] <- list(
          type = 'Feature',
          properties = list(
            temperature        = format(temperature[row, 3], digits = 2, nsmall = 2),
            humidity           = format(humidity[row, 3], digits = 2, nsmall = 2),
            precipitation      = format(precipitation[row, 3], digits = 2, nsmall = 2),
            wind               = format(wind[row, 3], digits = 2, nsmall = 2),
            radiation          = format(radiation[row, 3], digits = 2, nsmall = 2),
            latitude           = temperature[row, "new_pontos.LATITUDE"],
            longitude          = temperature[row, "new_pontos.LONGITUDE"],
            reading_time_start = date,
            reading_time_end   = date,
            index              = index
          ),
          geometry = list(
            type        = 'Point',
            coordinates = list(temperature[row, "new_pontos.LONGITUDE"], temperature[row, "new_pontos.LATITUDE"])
          )
        )
        
        index <- index + 1
        
        feature[[length(feature) + 1]] <- format(temperature[row, 3], digits = 2, nsmall = 2)
        feature[[length(feature) + 1]] <- format(humidity[row, 3], digits = 2, nsmall = 2)
        feature[[length(feature) + 1]] <- format(precipitation[row, 3], digits = 2, nsmall = 2)
        feature[[length(feature) + 1]] <- format(wind[row, 3], digits = 2, nsmall = 2)
        feature[[length(feature) + 1]] <- format(radiation[row, 3], digits = 2, nsmall = 2)
        feature[[length(feature) + 1]] <- temperature[row, "new_pontos.LATITUDE"]
        feature[[length(feature) + 1]] <- temperature[row, "new_pontos.LONGITUDE"]
        feature[[length(feature) + 1]] <- date
        feature[[length(feature) + 1]] <- date
        
        features[[length(features) + 1]] <-feature
        
        #print(paste(state, col))
      }
      
      #print(paste(state, col, sep = " - "))
    }
    
    if (col == 2017082523)
      break
  }
  
  return (features)
}

arquivo  <- "/var/www/html/mapbox/R"
shape_br <- rgdal::readOGR(arquivo, "estados", GDAL1_integer64_policy = TRUE)

load("/var/www/html/mapbox/R/TP2M.Rda")
load("/var/www/html/mapbox/R/UR2M.Rda")
load("/var/www/html/mapbox/R/PREC.Rda")
load("/var/www/html/mapbox/R/V10M.Rda")
load("/var/www/html/mapbox/R/OCIS.Rda")

datasets <- list()
ids      <- list();
for (state in c("AC", 
                "AL", 
                "AM", 
                "AP", 
                "BA", 
                "CE", 
                "DF", 
                "ES", 
                "GO", 
                "MA", 
                "MG", 
                "MS", 
                "MT", 
                "PA",
                "PB",
                "PE",
                "PI",
                "PR",
                "RJ",
                "RN",
                "RO",
                "RR",
                "RS",
                "SC",
                "SE",
                "SP",
                "TO"#, 
                #"BR"
                ))
{
  ids[[length(ids) + 1]]           <- paste("id", state, sep = "")
  datasets[[length(datasets) + 1]] <- list(
    version = "v1",
    data    = list(
      id      = paste("id", state, sep = ""),
      label   = paste(state, ".geojson", sep = ""),
      color   = list(143, 47, 191),
      allData = feature(state),
      fields  = list(
        list(
          name   = "_geojson",
          type   = "geojson",
          format = ""
        ),
        list(
          name   = "temperature",
          type   = "real",
          format = ""
        ),
        list(
          name   = "humidity",
          type   = "real",
          format = ""
        ),
        list(
          name   = "precipitation",
          type   = "real",
          format = ""
        ),
        list(
          name   = "wind",
          type   = "real",
          format = ""
        ),
        list(
          name   = "radiation",
          type   = "real",
          format = ""
        ),
        list(
          name   = "latitude",
          type   = "real",
          format = ""
        ),
        list(
          name   = "longitude",
          type   = "real",
          format = ""
        ),
        list(
          name   = "reading_time_start",
          type   = "timestamp",
          format = "YYYY-M-D H:m:s"
        ),
        list(
          name   = "reading_time_end",
          type   = "timestamp",
          format = "YYYY-M-D H:m:s"
        )
      )
    )
  )
}

layers <- list()
filters <- list()
for (id in ids) {
  layers[[length(layers) + 1]] <- list(
    id     = paste("layer", id, sep = ""),
    type   = "hexagon",
    config = list(
      dataId  = id,
      label   = substr(id, start = 3, stop = 6),
      columns = list(
        lat = "latitude",
        lng = "longitude"
      ) ,
      isVisible = FALSE,
      visConfig = list(
        opacity       = .8,
        worldUnitSize = 12,
        resolution    = 8,
        colorRange = list(
          name     = "ColorBrewer RdYlBu-6",
          type     = "diverging",
          category = "ColorBrewer",
          colors   = c(
            "#4575b4",
            "#91bfdb",
            "#e0f3f8",
            "#fee090",
            "#fc8d59",
            "#d73027"
          ),
          reversed = TRUE
        ),
        coverage            = 1,
        sizeRange           = c(0, 500),
        percentile          = c(0, 100),
        elevationPercentile = c(0, 100),
        elevationScale      = 30,
        "hi-precision"      = FALSE,
        colorAggregation    = "average",
        sizeAggregation     = "average",
        enable3d            = TRUE
      )
    ),
    visualChannels = list(
      colorField = list(
        name = "temperature",
        type = "real"
      ),
      colorScale = "quantize",
      sizeField = list(
        name = "radiation",
        type = "real"
      ),
      sizeScale = "linear"
    )
  )
  
  filters[[length(filters) + 1]] <- list(
    dataId   = id,
    id       = paste("filter", id, sep = ""),
    name     = "reading_time_start",
    type     = "timeRange",
    value    = list(),
    enlarged = FALSE,
    plotType = "lineChart",
    yAxis    =  list(
      name = "humidity",
      type = "real"
    )
  )
}

str = toJSON(
  list(datasets = datasets,
       config   = list(
         version    = "v1",
         config     = list(
          visState            = list(
            filters           = filters,
            layers            = layers,
            interactionConfig = list(
              tooltip = list(
                fieldsToShow = NULL,
                enabled      = TRUE
              ),
              brush           = list(
                size    = .5,
                enabled = FALSE
              )
            ),
            layerBlending = "normal",
            splitMaps = list()
          ), 
          mapState            = list(
            bearing    = 24,
            dragRotate = TRUE,
            latitude   = -31.093130467636723,
            longitude  = -54.99532430462655,
            pitch      = 50,
            zoom       = 6.667760421641584,
            isSplit    = FALSE
          ),
          mapStyle            = list(
            styleType      = "dark",
            topLayerGroups = list(
              label = TRUE
            ),
            visibleLayerGroups = list(
              label    = TRUE,
              road     = TRUE,
              border   = FALSE,
              building = TRUE,
              water    = TRUE,
              land     = TRUE
            ),
            mapStyles          = NULL
          )
       )
     ),
     info       = list(
       app        = "kepler.gl",
       created_at = date()
     )
  ),
  pretty     = TRUE,
  auto_unbox = TRUE
)

write(str, paste("/var/www/html/mapbox/json/kepler.json", sep = ""))
