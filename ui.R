# load packages
require(leaflet)
require(shinythemes)

# ui
shinyUI(
  bootstrapPage(theme = shinytheme("cyborg"),
                navbarPage(title="StadtRAD Hamburg",
                           tabPanel("Karte",
                                    div(class="outer",includeCSS("style.css"),
                                        
                                        tags$style(type = "text/css", ".outer {position: fixed; top: 50px; left: 0; right: 0; bottom: 0; overflow: hidden; padding: 0}"),
                                        
                                        tags$head(tags$style(HTML('#controls {background-color: rgba(0,0,0,0.45);}'))),
                                        
                                        leafletOutput("stadtrad.map", width = "100%", height = "100%"),
                                        absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                                      draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                                                      width = 330, height = "auto",

                                                      p("Diese interaktive Karte zeigt die Nutzung des Hamburger Fahrradleihsystems StadtRAD im Juni 2016. Die Karte hat folgende Funktionen:"),
                                                      HTML("<ul><li>Man kann hinein- oder herauszoomen</li>
                                                                <li>Die Linien zeigen die Fahrten zwischen den Leihstationen. Klickt man auf eine Linie, erhält man die Anzahl der Fahrten für diesen Streckenabschnitt</li>
                                                                <li>Klickt man auf eine Station, erhält man weitere Informationen</li></ul>"),
                                                      br(),
                                                      checkboxInput("show", "Stationen anzeigen?", TRUE)
                                                      
                                        )
                                    )),
                                    tabPanel("About",
                                            sidebarPanel(
                                              HTML('<p style="text-align:justify"><strong>Code:</strong> Diese Web-App wurde mit <a href="http://shiny.rstudio.com/", target="_blank">Shiny</a> gebaut. Den Code für die Shiny-App findet man <a href="https://github.com/kruse-alex/bike_sharing", target="_blank">hier</a>.<p style="text-align:justify">
                                                   <strong>Daten:</strong> Die Daten kommen von der <a href="http://data.deutschebahn.com/", target="_blank">Deutschen Bahn</a>. Die Karte berücksichtigt alle Fahrten zwischen dem 01.06.16 und 30.06.16. Auf der Karte werden nur Streckenabschnitte mit mindestens fünf Fahrten abgebildet.</p>'),
                                              value="about")
                                            )
                           )
                )
  )