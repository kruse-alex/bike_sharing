#############################################################################################################################################
# PACKAGES
#############################################################################################################################################

# load packages
library(sqldf)
require(dplyr)
require(reshape2)
require(superheat)

# set locale to get weekdays in English
Sys.setlocale("LC_TIME", "C")

#############################################################################################################################################
# LOAD DATA
#############################################################################################################################################

# setwd
setwd("C:/Users/akruse/Documents/Projekte_Weitere/stadtrad/heatmap")

# load data (download data from Deutsche Bahn)
mydata = read.csv.sql("OPENDATA_BOOKING_CALL_A_BIKE.csv", sql = "select * from file where CITY_RENTAL_ZONE = '\"Hamburg\"' ", sep = ";")

#############################################################################################################################################
# PROCESS DATA
#############################################################################################################################################

# processing
mydata = select(mydata, DATE_FROM)
mydata = as.data.frame(sapply(mydata, function(x) gsub("\"", "", x)))
mydata$DATE_FROM = as.POSIXct(strptime(mydata$DATE_FROM, "%Y-%m-%d %H:%M:%S"))

# filter on 2016 (Note: full KWs needed)
mydata = filter(mydata, DATE_FROM >= "2015-12-28 00:00:00" & DATE_FROM <= "2017-01-01 23:59:59")

# time formatting day of week and KW
mydata$week = strftime(mydata$DATE_FROM,format="%W") 
mydata$week[mydata$DATE_FROM >= "2015-12-28 00:00:00" & mydata$DATE_FROM <= "2016-01-03 23:59:59"] = "00"
mydata$week[mydata$DATE_FROM >= "2016-12-26 00:00:00" & mydata$DATE_FROM <= "2017-01-01 23:59:59"] = "53"
mydata$weekday = weekdays(mydata$DATE_FROM)

# grouing
mydata = mydata %>% group_by(week, weekday) %>% summarise(count = n())

# change order of factor levels for plotting
mydata$weekday = as.factor(mydata$weekday)
mydata$weekday = factor(mydata$weekday, levels = c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"))
mydata$week= as.factor(mydata$week)
mydata$week = factor(mydata$week, levels = rev(levels(mydata$week)))

# create matrix for heatmap
mydata = acast(mydata, week~weekday, value.var="count")
mydata = as.data.frame(mydata)

#############################################################################################################################################
# CREATE SUPERHEAT
#############################################################################################################################################

# prevent scientific notation of numbers for plotting
options(scipen=999)

# save plot
png("superheat.png", height = 900, width = 800)

# plot
superheat(mydata, 
          
          # main plot
          title = "StadtRAD Usage 2016 (Calendar Heatmap)",
          row.title = "Number of Week",
          left.label.text.size = 3,
          bottom.label.text.size = 4,
          
          # y axis bar
          yr = rowSums(mydata),
          yr.axis.name = "",
          yr.plot.type = "bar",
          
          # x axis bar
          yt = colSums(mydata),
          yt.plot.type = "bar",
          yt.axis.name = "",
          
          # legend
          legend.breaks = c(4000, 8000, 12000))
dev.off()
