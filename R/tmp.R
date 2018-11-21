arquivo = "/var/www/html/mapbox/R/"
shape_br <- rgdal::readOGR(arquivo, "estados", GDAL1_integer64_policy = TRUE)

#' @export
plot_map <- function(weatherData, iTime, estado) {
  tabela <- weatherData
  
    shape_estado <- shape_br
  
  pontos <- data.frame(tabela$longitude,tabela$latitude,tabela[,iTime])
  colnames(pontos) = c("longitude","latitude",iTime)
  sp::coordinates(pontos) <- c("longitude", "latitude")
  sp::proj4string(pontos) <- sp::proj4string(shape_estado)
  new_pontos <- tabela[!is.na(sp::over(pontos, as(shape_estado, "SpatialPolygons"))),]
  
  tab_raster = raster::rasterFromXYZ(new_pontos)
  r <- raster::raster(tab_raster,layer = grep(iTime, colnames(new_pontos)))
  raster::crs(r) <- sp::CRS("+init=epsg:4326")
  
  return(data.frame(new_pontos$longitude,new_pontos$latitude,new_pontos[,iTime]))
}

library("jsonlite", lib.loc = "~/R/x86_64-redhat-linux-gnu-library/3.5")

load("/var/www/html/mapbox/R/TP2M.Rda")
load("/var/www/html/mapbox/R/UR2M.Rda")
load("/var/www/html/mapbox/R/PREC.Rda")
load("/var/www/html/mapbox/R/OCIS.Rda")

json <- list()
for (col in colnames(TP2M))
{
  if (col != "latitude" && col != "longitude")
  {
   if (col >= '2018111500')
   {
    temperature <- TP2M
    humidity <- UR2M
    precipitation <- PREC
    radiation <- OCIS
    
    for (row in 1:nrow(temperature))
    {
      json[[length(json) + 1]] <- list(type = 'Feature', 
                                       properties = list(temperature = temperature[row, 3],
                                                         humidity = humidity[row, 3],
                                                         precipitation = precipitation[row, 3],
                                                         radiation = radiation[row, 3],
                                                         latitude = temperature[row, "latitude"],
                                                         longitude = temperature[row, "longitude"],
                                                         reading_time_start = col,
                                                         reading_time_end = col),
                                       geometry = list(type = 'Point', 
                                                       coordinates = list(temperature[row, "longitude"], temperature[row, "latitude"])))
      
      print(paste(row, col, temperature[row, "latitude"], temperature[row, "longitude"]))
    }
   } 

   if (col >= '2018111500')
       break
  }
}

str = toJSON(list(type = "FeatureCollection", features = json), pretty = TRUE, auto_unbox = TRUE)
write(str, paste("/var/www/html/mapbox/json/weather.geojson", sep=""))
