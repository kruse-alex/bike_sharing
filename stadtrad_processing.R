#############################################################################################################################################
# PACKAGES
#############################################################################################################################################

# load packages
library(sqldf)
require(dplyr)
require(data.table)
require(sp)
require(rgdal)
require(stplanr)
require(reshape2)
require(rmapshaper)

# check for cs key
Sys.getenv("CYCLESTREET")

#############################################################################################################################################
# LOAD DATA
#############################################################################################################################################

# setwd
setwd("K:/Consulting/13_Alex_Data_Analyst/Datenanalyse_Projekte/Weitere/stadtrad")

# load data (download data from Deutsche Bahn)
mydata <- read.csv.sql("HACKATHON_BOOKING_CALL_A_BIKE.csv", sql = "select * from file where CITY_RENTAL_ZONE = '\"Hamburg\"' ", sep = ";")

#############################################################################################################################################
# PROCESS DATA
#############################################################################################################################################

# processing
mydata <- select(mydata, DATE_FROM, TRIP_LENGTH_MINUTES, START_RENTAL_ZONE_GROUP, END_RENTAL_ZONE_GROUP)
mydata <- as.data.frame(sapply(mydata, function(x) gsub("\"", "", x)))
mydata$DATE_FROM <- gsub(".0000000","",mydata$DATE_FROM)
mydata$DATE_FROM <- as.POSIXct(strptime(mydata$DATE_FROM, "%Y-%m-%d %H:%M:%S"))

# filter on june
mydata <- filter(mydata, DATE_FROM >= "2016-06-01 00:00:00" & DATE_FROM <= "2016-06-30 23:59:59")

# aggregate doubles
mydata <- transform(mydata, min = pmin(as.character(START_RENTAL_ZONE_GROUP), as.character(END_RENTAL_ZONE_GROUP)))
mydata <- transform(mydata, max = pmax(as.character(START_RENTAL_ZONE_GROUP), as.character(END_RENTAL_ZONE_GROUP)))

# get lan/lat from stations
station <- read.csv("HACKATHON_RENTAL_ZONE_CALL_A_BIKE.csv", sep = ";", quote = "", stringsAsFactors = T)
station <- as.data.frame(sapply(station, function(x) gsub("\"", "", x)))
station <- filter(station, X.CITY. == "Hamburg")
station <- select(station, X.RENTAL_ZONE_GROUP., X.RENTAL_ZONE_X_COORDINATE., X.RENTAL_ZONE_Y_COORDINATE.)
colnames(station) <- c("RENTAL_ZONE_GROUP", "RENTAL_ZONE_X_COORDINATE", "RENTAL_ZONE_Y_COORDINATE")

mydata <- merge(mydata, station, by.x = "min", by.y = "RENTAL_ZONE_GROUP", all.x = T)
mydata <- merge(mydata, station, by.x = "max", by.y = "RENTAL_ZONE_GROUP", all.x = T)
mydata <- mydata[complete.cases(mydata),]
mydata <- filter(mydata, TRIP_LENGTH_MINUTES != "")

# some more processing
mydata$start <- paste(mydata$RENTAL_ZONE_Y_COORDINATE.x, mydata$RENTAL_ZONE_X_COORDINATE.x, sep = " ")
mydata$dest <- paste(mydata$RENTAL_ZONE_Y_COORDINATE.y, mydata$RENTAL_ZONE_X_COORDINATE.y, sep = " ")
mydata$date <- as.Date(mydata$DATE_FROM)
mydata <- mydata %>% group_by(start, dest) %>% summarise(count = n())
mydata$start <- gsub(",",".",mydata$start)
mydata$dest <- gsub(",",".",mydata$dest)
mydata$start <- as.character(mydata$start)
mydata$dest <- as.character(mydata$dest)
mydata <- as.data.frame(mydata)

mydata$check <- mydata$start == mydata$dest 
mydata <- filter(mydata, check == "FALSE")
mydata <- filter(mydata, start != "0.000000000000000 0.000000000000000")
mydata <- filter(mydata, dest != "0.000000000000000 0.000000000000000")
mydata <- filter(mydata, dest != " ")
mydata <- filter(mydata, start != " ")

# take sample for testing
#mydata <- mydata[1:50,]

#############################################################################################################################################
# GET ROUTES
#############################################################################################################################################

# some processing
mydata$check <- NULL
mydata$id <- rownames(mydata)
mydata <- melt(mydata, id.vars = c("id","count"))
test <- data.frame(do.call('rbind', strsplit(as.character(mydata$value),' ',fixed=TRUE)))
mydata <- cbind(mydata,test)
mydata <- select(mydata, X1, X2, id, count)
rm(test)
colnames(mydata) <- c("lat","lon","id","count")
dt <- mydata
dt$lat <- as.numeric(as.character(dt$lat))
dt$lon <- as.numeric(as.character(dt$lon))
dt$id <- as.factor(dt$id)

# create spdf
dt <- as.data.table(dt)
lst_lines <- lapply(unique(dt$id), function(x){
  Lines(Line(dt[id == x, .(lon, lat)]), ID = x)
})
spl_lst <- SpatialLines(lst_lines)
spl_df <- SpatialLinesDataFrame(spl_lst, data.frame(mydata$count))

# get routes from cyclestreet (needs API key)
spl_df <- line2route(spl_df, "route_cyclestreet", plan = "fastest")
mydata$lat <- NULL
mydata$lon <- NULL
mydata <- mydata[!duplicated(mydata), ]
spl_df@data$count <- mydata$count
spl_df@data <- select(spl_df@data, count)

# remove rare tracks
spl_df <- spl_df[spl_df@data$count >= 5, ]

# overline overlaps
spl_df <- ms_simplify(input = spl_df, keep = 0.01)
spl_df <- overline(spl_df, attrib = "count", fun = sum)

#############################################################################################################################################
# SAVE OBJECT
#############################################################################################################################################

# save objects for leaflet map
writeOGR(obj=spl_df, dsn="sp_files", layer="june16", driver="ESRI Shapefile")

# remove objects
rm(spl_lst,mydata,dt,lst_lines, spl_df, station)
