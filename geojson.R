library("jsonlite", lib.loc="~/R/x86_64-redhat-linux-gnu-library/3.5")
load("~/Downloads/TP2M.Rda")

dir <- "tp2m"
for (col in colnames(TP2M))
{
  if (col != "LATITUDE" && col != "LONGITUDE")
  {
    mapbox <- TP2M[, c("LONGITUDE", "LATITUDE", col)]
    
    json <- list()
    for (row in 1:nrow(mapbox))
    {
      json[[length(json) + 1]] <- list(type = 'Feature', 
                                       properties = list(dbh = mapbox[row, 3]),
                                       geometry = list(type = 'Point', 
                                                       coordinates = list(mapbox[row, "LONGITUDE"], mapbox[row, "LATITUDE"])))
    }
    
    str = toJSON(list(type = "FeatureCollection", features = json), pretty = TRUE, auto_unbox = TRUE)
    write(str, paste("/var/www/html/mapbox/json/", dir, "/", col, ".geojson", sep=""))
  }
}