arquivo = "/home/pkoch/Downloads/tcc/"
shape_br <- rgdal::readOGR(arquivo, "estados", GDAL1_integer64_policy = TRUE)

#' @export
plot_map <- function(weatherData, iTime, estado) {
  tabela <- weatherData
  
  if((length(estado) == 1) & (estado == "BR"))
    shape_estado <- shape_br
  else
    shape_estado <- shape_br[shape_br$sigla %in% estado,]
  
  pontos <- data.frame(tabela$LONGITUDE,tabela$LATITUDE,tabela[,iTime])
  colnames(pontos) = c("LONGITUDE","LATITUDE",iTime)
  sp::coordinates(pontos) <- c("LONGITUDE", "LATITUDE")
  sp::proj4string(pontos) <- sp::proj4string(shape_estado)
  new_pontos <- tabela[!is.na(sp::over(pontos, as(shape_estado, "SpatialPolygons"))),]
  
  tab_raster = raster::rasterFromXYZ(new_pontos)
  r <- raster::raster(tab_raster,layer = grep(iTime, colnames(new_pontos)))
  raster::crs(r) <- sp::CRS("+init=epsg:4326")
  
  return(data.frame(new_pontos$LONGITUDE,new_pontos$LATITUDE,new_pontos[,iTime]))
}

library("jsonlite", lib.loc = "~/R/x86_64-redhat-linux-gnu-library/3.5")

load("/var/www/html/mapbox/R/TP2M.Rda")
load("/var/www/html/mapbox/R/UR2M.Rda")
load("/var/www/html/mapbox/R/PREC.Rda")
load("/var/www/html/mapbox/R/V10M.Rda")
load("/var/www/html/mapbox/R/OCIS.Rda")

json <- list()
for (col in colnames(TP2M))
{
  if (col != "LATITUDE" && col != "LONGITUDE")
  {
    temperature <- plot_map(TP2M, col, "RS")
    humidity <- plot_map(UR2M, col, "RS")
    precipitation <- plot_map(PREC, col, "RS")
    wind <- plot_map(V10M, col, "RS")
    radiation <- plot_map(OCIS, col, "RS")
    
    for (row in 1:nrow(temperature))
    {
      y <- substr(col, start=1, stop=4)
      m <- substr(col, start=5, stop=6)
      d <- substr(col, start=7, stop=8)
      h <- substr(col, start=9, stop=10)
      date <- paste(paste(y, m, d, sep="-"), paste(h, "00", "00", sep=":"), sep=" ")
      
      json[[length(json) + 1]] <- list(type = 'Feature', 
                                       properties = list(temperature = temperature[row, 3],
                                                         humidity = humidity[row, 3],
                                                         precipitation = precipitation[row, 3],
                                                         wind = wind[row, 3],
                                                         radiation = radiation[row, 3],
                                                         latitude = temperature[row, "new_pontos.LATITUDE"],
                                                         longitude = temperature[row, "new_pontos.LONGITUDE"],
                                                         reading_time_start = date,
                                                         reading_time_end = date),
                                       geometry = list(type = 'Point', 
                                                       coordinates = list(temperature[row, "new_pontos.LONGITUDE"], temperature[row, "new_pontos.LATITUDE"])))
      
      print(paste(row, col, temperature[row, "new_pontos.LATITUDE"], temperature[row, "new_pontos.LATITUDE"]))
    }
  }
  
  if (col == "2017082323")
    break
}

str = toJSON(list(type = "FeatureCollection", features = json), pretty = TRUE, auto_unbox = TRUE)
write(str, paste("/var/www/html/mapbox/json/weather.geojson", sep=""))