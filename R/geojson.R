library("jsonlite", lib.loc = "~/R/x86_64-redhat-linux-gnu-library/3.5")

filter <- function(weatherData, iTime, estado) {

  #return all data to a given time
  #new_pontos = weatherData
  #return (data.frame(new_pontos$latitude, new_pontos$longitude, new_pontos[,iTime]))

  tabela <- weatherData
  if ((length(estado) == 1) & (estado == "ALL"))
    shape_estado <- shape_br
  else if (is.null(shape_br@data[["MUNICIPIO"]]))
    shape_estado <- shape_br[shape_br$sigla %in% estado,]
  else
    shape_estado <- shape_br[shape_br$MUNICIPIO %in% estado,]
  
  pontos                  <- data.frame(tabela$longitude, tabela$latitude, tabela[, iTime])
  colnames(pontos)        <- c("longitude", "latitude", iTime)
  sp::coordinates(pontos) <- c("longitude", "latitude")
  sp::proj4string(pontos) <- sp::proj4string(shape_estado)
  new_pontos              <- tabela[!is.na(sp::over(pontos, as(shape_estado, "SpatialPolygons"))),]
  
  tab_raster     <- raster::rasterFromXYZ(new_pontos)
  r              <- raster::raster(tab_raster, layer = grep(iTime, colnames(new_pontos)))
  raster::crs(r) <- sp::CRS("+init=epsg:4326")
  
  return(data.frame(new_pontos$longitude, new_pontos$latitude, new_pontos[, iTime]))
}

feature <- function(state, dt_ini, dt_end) {
  cat(paste("Extraindo as dados do estado ", state, " no período ", dt_ini, " - ", dt_end, "\n", sep = ""))
  
  features <- list()
  index    <- 0
  for (col in colnames(TP2M))
  {
    if (col != "latitude" && col != "longitude" && col >= dt_ini)
    {
      temperature   <- filter(TP2M, col, state)
      humidity      <- filter(UR2M, col, state)
      precipitation <- filter(PREC, col, state)
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
            temperature        = temperature[row, 3],
            humidity           = format(humidity[row, 3], digits = 2, nsmall = 2),
            precipitation      = format(precipitation[row, 3], digits = 2, nsmall = 2),
            radiation          = format(radiation[row, 3], digits = 2, nsmall = 2),
            latitude           = temperature[row, "new_pontos.latitude"],
            longitude          = temperature[row, "new_pontos.longitude"],
            reading_time_start = date,
            reading_time_end   = date,
            index              = index
          ),
          geometry = list(
            type        = 'Point',
            coordinates = list(temperature[row, "new_pontos.longitude"], temperature[row, "new_pontos.latitude"])
          )
        )
        
        index <- index + 1
        
        feature[[length(feature) + 1]] <- temperature[row, 3]
        feature[[length(feature) + 1]] <- format(humidity[row, 3], digits = 2, nsmall = 2)
        feature[[length(feature) + 1]] <- format(precipitation[row, 3], digits = 2, nsmall = 2)
        feature[[length(feature) + 1]] <- format(radiation[row, 3], digits = 2, nsmall = 2)
        feature[[length(feature) + 1]] <- temperature[row, "new_pontos.latitude"]
        feature[[length(feature) + 1]] <- temperature[row, "new_pontos.longitude"]
        feature[[length(feature) + 1]] <- date
        feature[[length(feature) + 1]] <- date
        
        features[[length(features) + 1]] <-feature
      }
    }
    
    if (col == dt_end)
      break
  }
  
  cat("Dados extraídos\n")
  
  return (features)
}

readinput <- function(msg, default) {
  cat("\n\n")
  input <- readline(msg)
  if (input == "")
    input <- default
  
  return (input)
}

input_current_dir     <- getwd()
input_shape_dir       <- readinput(paste("Informe o diretório onde se encontram os 'shape files', (default=[", input_current_dir, "]): ", sep = ""), input_current_dir);
input_shape_file_name <- readinput(paste("Informe o nome dos arquivos 'shape files', (default=[estados]): ", sep = ""), "estados");
shape_br              <- rgdal::readOGR(input_shape_dir, input_shape_file_name, GDAL1_integer64_policy = TRUE)

input_dir <- readinput(paste("Informe o diretório onde se encontram os arquivos .Rda, (default=[", input_current_dir, "]): ", sep = ""), input_current_dir);
for (file in list.files(path = input_dir, pattern = "*.Rda")) {
  cat(paste("Carregando o arquivo: /var/www/html/mapbox/R/", file, "\n", sep = ""))
  load(paste(input_dir, file, sep = "/"))
}

home <- path.expand("~")  
input_dir_output <- readinput(paste("Informe o diretório para salvar o arquivo geojson, (default=[", home, "]):"), home);

cols   <- colnames(TP2M)
dt_ini <- cols[3]
dt_end <- cols[length(cols)]

input_dt_ini   <- readinput(paste("Informe o início do período no formato YYYYMMDDHH, (default=[", dt_ini, "]): "), dt_ini);
input_dt_end   <- readinput(paste("Informe o término do período no formato YYYYMMDDHH, (default=[", dt_end, "]): "), dt_end);
input_state    <- readinput("Informe um estado/município ou digite ALL para todos, a informação deve estar contida no arquivo 'shape files' (default= [RS]): ", "RS");
splited_state  <- strsplit(input_state, "-")

datasets <- list()
ids      <- list();
for (state in unlist(splited_state))
{
  ids[[length(ids) + 1]]           <- paste("id", state, sep = "")
  datasets[[length(datasets) + 1]] <- list(
    version = "v1",
    data    = list(
      id      = paste("id", state, sep = ""),
      label   = paste(state, ".geojson", sep = ""),
      color   = list(143, 47, 191),
      allData = feature(state, input_dt_ini, input_dt_end),
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
split <- list()
filters <- list()
for (id in ids) {
  layers[[length(layers) + 1]] <- list(
    id     = paste("layer", id, "-tmp-rad", sep = ""),
    type   = "grid",
    config = list(
      dataId  = id,
      label   = paste(substring(id, 3, 100), "-tmp-rad", sep = ""),
      columns = list(
        lat = "latitude",
        lng = "longitude"
      ) ,
      isVisible = FALSE,
      visConfig = list(
        opacity       = .8,
        worldUnitSize = 15,
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
        name = "temperature"
      ),
      colorScale = "quantize",
      sizeField = list(
        name = "radiation"
      ),
      sizeScale = "linear"
    )
  )
  
  layers[[length(layers) + 1]] <- list(
    id     = paste("layer", id, "-hum-prec", sep = ""),
    type   = "grid",
    config = list(
      dataId  = id,
      label   = paste(substring(id, 3, 100), "-hum-prec", sep = ""),
      columns = list(
        lat = "latitude",
        lng = "longitude"
      ) ,
      isVisible = FALSE,
      visConfig = list(
        opacity       = .8,
        worldUnitSize = 15,
        resolution    = 8,
        colorRange = list(
          name     = "ColorBrewer RdYlBu-6",
          type     = "diverging",
          category = "ColorBrewer",
          colors   = c(
            "#e6fafa",
            "#c1e5e6",
            "#9dd0d4",
            "#75bbc1",
            "#4ba7af",
            "#00939c"
          ),
          reversed = FALSE
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
        name = "humidity"
      ),
      colorScale = "quantize",
      sizeField = list(
        name = "precipitation"
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

filename <- paste(input_dir_output, "/", input_state, "_", input_dt_ini, "_", input_dt_end, ".json", sep = "")
cat("Salvando dados\n")
write(str, filename)
cat(paste("Arquivo ", filename, " salvo ", "\n", sep = ""))
