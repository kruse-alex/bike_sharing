## Visualization of usage of bike sharing network in Hamburg (StadtRAD)
 + Data: http://data.deutschebahn.com/dataset/data-call-a-bike
 + Use the map here: https://alexkruse.shinyapps.io/stadtrad/
 + I also created a [Poster](https://github.com/kruse-alex/bike_sharing/blob/master/Kruse_poster-session.pdf) for useR 2017 Poster Session
 
My interactive map shows the bike sharing usage of StadtRAD, the bike sharing system in Hamburg – Germany. The data is available on the open data platform from Deutsche Bahn, the public railway company in Germany. The last new StadtRAD station was put into operation in May 2016, that is why a have chosen to display the usage of June 2016. The brighter the lines, the more bikes have been cycled along that street. 

![alt text](https://github.com/kruse-alex/bike_sharing/blob/master/bike_usage_HH.png) 
 
From data processing and spatial analysis to visualization the whole project was done in R. I have used the leaflet and shiny package to display the data interactively. The bikes themselves don’t have GPS, so the routes are estimated on a shortest route basis using the awesome cyclestreets API. The biggest challenge has been the aggregation of overlapping routes. I found the overline function from the stplanr package very helpful. It converts a series of overlaying lines and aggregates their values for overlapping segments. The raw data file from Deutsche Bahn is quite huge so I struggled to import the data into R to process it. In the end the read.csv.sql function from the sqldf package did the job.
