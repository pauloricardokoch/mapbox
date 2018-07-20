library("jsonlite", lib.loc="~/R/x86_64-redhat-linux-gnu-library/3.5")

load("~/Downloads/TP2M.Rda")

MAPBOX <- TP2M[,c("LONGITUDE", "LATITUDE", "2017082200")]

json <- list()
for (row in 1:nrow(MAPBOX)) {
  json[[length(json) + 1]] <- list(type = 'Feature', 
                                   properties = list(dbh = MAPBOX[row, 3]),
                                   geometry = list(type = 'Point', 
                                                   coordinates = list(MAPBOX[row, "LONGITUDE"], MAPBOX[row, "LATITUDE"])))
}

str = toJSON(list(type = "FeatureCollection", features = json), pretty = TRUE, auto_unbox = TRUE)
write(str, "/var/www/html/mapbox/json/mapbox.geojson")