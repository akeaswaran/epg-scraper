# EPG Calculator
# Author: Akshay Easwaran <akeaswaran@me.com>
# License: MIT

# Required Pacakges
require(RSelenium)
require(XML)
require(plyr)
require(data.table)
require(stringi)

# Data set and method to convert foreign chars into normal English ones (from StackOverflow)
fromto <- read.table(text="
from to
 š s
 œ oe
 ž z
 ß ss
 þ y
 à a
 á a
 â a
 ã a
 ä a
 å a
 æ ae
 ç c
 è e
 é e
 ê e
 ë e
 ì i
 í i
 î i
 ï i
 ð d
 ñ n
 ò o
 ó o
 ô o
 õ o
 ö o
 ø oe
 ù u
 ú u
 û u
 ü u
 ý y
 ÿ y
 ğ g",header=TRUE)

replaceforeignchars <- function(dat,fromto) {
    for(i in 1:nrow(fromto) ) {
        dat <- gsub(fromto$from[i],fromto$to[i],dat)
    }
    dat
}

appendToFrame<-function(dt, elems)
{
    n<-attr(dt, 'rowcount')
    if (is.null(n))
        n<-nrow(dt)
    if (n==nrow(dt))
    {
        tmp<-elems[1]
        tmp[[1]]<-rep(NA,n)
        dt<-rbindlist(list(dt, tmp), fill=TRUE, use.names=TRUE)
        setattr(dt,'rowcount', n)
    }
    pos<-as.integer(match(names(elems), colnames(dt)))
    for (j in seq_along(pos))
    {
        set(dt, i=as.integer(n+1), pos[[j]], elems[[j]])
    }
    setattr(dt,'rowcount',n+1)
    return(dt)
}

# start Selenium server with any of the following (change the browser name to what's specified):
# browsername: firefox; java -Dwebdriver.gecko.driver=geckodriver -jar selenium-server-standalone-3.4.0.jar
# browsername: chrome; java -Dwebdriver.chrome.driver=chromedriver -jar selenium-server-standalone-3.4.0.jar

# connect to selenium server 
remDr <- remoteDriver(remoteServerAddr = "localhost" 
                      , port = 4444
                      , browserName = "firefox"
)
remDr$open()

team_urls <- c("https://www.whoscored.com/Teams/26666/Show/USA-Atlanta-United",
               "https://www.whoscored.com/Teams/26666/Show/USA-Chicago-Fire",
               "https://www.whoscored.com/Teams/1120/Show/USA-Colorado-Rapids",
               "https://www.whoscored.com/Teams/1113/Show/USA-Columbus-Crew",
               "https://www.whoscored.com/Teams/1119/Show/USA-DC-United",
               "https://www.whoscored.com/Teams/2948/Show/USA-FC-Dallas",
               "https://www.whoscored.com/Teams/3624/Show/USA-Houston-Dynamo",
               "https://www.whoscored.com/Teams/1116/Show/USA-Sporting-Kansas-City",
               "https://www.whoscored.com/Teams/1117/Show/USA-LA-Galaxy",
               "https://www.whoscored.com/Teams/9293/Show/USA-Minnesota-United",
               "https://www.whoscored.com/Teams/11135/Show/Canada-Montreal-Impact",
               "https://www.whoscored.com/Teams/1114/Show/USA-New-England-Rev-",
               "https://www.whoscored.com/Teams/1121/Show/USA-New-York-Red-Bulls",
               "https://www.whoscored.com/Teams/19584/Show/USA-New-York-City-FC",
               "https://www.whoscored.com/Teams/10221/Show/USA-Orlando-City",
               "https://www.whoscored.com/Teams/8586/Show/USA-Philadelphia-Union",
               "https://www.whoscored.com/Teams/11133/Show/USA-Portland-Timbers",
               "https://www.whoscored.com/Teams/2947/Show/USA-Real-Salt-Lake",
               "https://www.whoscored.com/Teams/1122/Show/USA-San-Jose-Earthquakes",
               "https://www.whoscored.com/Teams/5973/Show/USA-Seattle-Sounders-FC",
               "https://www.whoscored.com/Teams/4186/Show/Canada-Toronto-FC",
               "https://www.whoscored.com/Teams/11134/Show/Canada-Vancouver-Whitecaps")

# iterate through the team urls to retreive the data
# lapply(team_urls, function(url) {
#     # navigate to WhoScored
#     remDr$navigate(url)
# 
#     # Find "Passing" tab and click
#     webElem <- remDr$findElement(using = "css", "li.in-squad-detailed-view:nth-child(4) > a:nth-child(1)")
#     webElem$clickElement()
# 
#     # Scrape passing table html into R data frame
#     tempPassTableHTML <- remDr$findElement(using = 'id', value = "statistics-table-passing")
#     tempPassTableTxt <- tempPassTableHTML$getElementAttribute("outerHTML")[[1]]
#     passTable <- appendToFrame(passTable, readHTMLTable(tempPassTableTxt, header=TRUE, as.data.frame=TRUE)[[1]])
# })

# navigate to WhoScored
remDr$navigate("https://www.whoscored.com/Teams/26666/Show/USA-Atlanta-United")

# Find "Passing" tab and click
webElem <- remDr$findElement(using = "css", "li.in-squad-detailed-view:nth-child(4) > a:nth-child(1)")
webElem$clickElement()

# Scrape passing table html into R data frame
tempPassTableHTML <- remDr$findElement(using = 'id', value = "statistics-table-passing")
tempPassTableTxt <- tempPassTableHTML$getElementAttribute("outerHTML")[[1]]
passTable <- readHTMLTable(tempPassTableTxt, header=TRUE, as.data.frame=TRUE)[[1]]
# passTable <- appendToFrame(passTable, readHTMLTable(tempPassTableTxt, header=TRUE, as.data.frame=TRUE)[[1]])


# WhoScored's player data often contains more than we need. 
# Strip out the position, age, etc and only put the player's actual name back in the table.
y <- strsplit(as.character(passTable$Player), " ")
passTable$Player <- lapply(y, function(x) { 
    # Check if the player has a second last name (IE: the third element when string splitting is NOT his age - EX: Leando Gonzalez Pirez)
    if (!grepl("[-]?[0-9]+[.]?[0-9]*|[-]?[0-9]+[L]?|[-]?[0-9]+[.]?[0-9]*[eE][0-9]+", x[3]))
        paste(x[1],x[2],x[3])
    else
        paste(x[1],x[2])
})

# Fix character encoding issues and replace foreign chars
passTable$Player <- replaceforeignchars(iconv(as.character(passTable$Player), from="UTF-8", to="ISO-8859-1"), fromto)


# -------

# Go to ASA's Team xGoals sheet
remDr$navigate("http://www.americansocceranalysis.com/team-xg-2017/")

# Scrape Team xGoals table html into R data frame
xGoalsTblHTML <- remDr$findElement(using = "css", "#block-yui_3_17_2_35_1488824086586_9407 > div > table")
xGoalsTxt <- xGoalsTblHTML$getElementAttribute("outerHTML")[[1]]
xGoalsTable <- readHTMLTable(xGoalsTxt, header=TRUE, as.data.frame=TRUE)[[1]]

# -------

# Go to ASA's Player xGoals sheet
remDr$navigate("http://www.americansocceranalysis.com/player-xg-2017/")

# Scrape Player xGoals table html into R data frame
xGoalsPlyrTblHTML <- remDr$findElement(using = "css", "#block-yui_3_17_2_23_1488824086586_3871 > div > table")
xGoalsPlyrTxt <- xGoalsPlyrTblHTML$getElementAttribute("outerHTML")[[1]]
xGoalsPlyrTable <- readHTMLTable(xGoalsPlyrTxt, header=TRUE, as.data.frame=TRUE)[[1]]

# close the Selenium connection to clean up
remDr$close()

# -------

# Do some minor cleanup - replace team names with Abbrev and add full name to player table
xGoalsTable$Team <- mapvalues(xGoalsTable$Team, 
                                   from=c("Atlanta United","Chicago","Columbus","Colorado","FC Dallas","DC United","Houston","L.A. Galaxy","Minnesota United","Montreal","New England","New York City FC","New York","Orlando City","Philadelphia","Portland","Salt Lake","Seattle","San Jose","Kansas City","Toronto","Vancouver"),
                                   to=c("ATL","CHI","CLB","COL","DAL","DC","HOU","LA","MN","MTL","NE","NYC","NYRB","ORL","PHI","POR","RSL","SEA","SJ","SKC","TOR","VAN"))
xGoalsPlyrTable$FullName <- paste(xGoalsPlyrTable$First,xGoalsPlyrTable$Last)

# For every player, we want to:
    # 1. Get the necessary stats for them: xGoals and xAssists, etc
    # 2. Get necessary team stats (map team abbrev to team name)
    # 3. Plug stats into formula
    # 4. Add Player name and formula result to table
# After completion, we need to display table

# Formulas: 
# PCxG=(PxG/TxG)+(((PSPxG/100) * PPxG)/TSPxG)
# EPG=[(3 * 0.483)+(1 * 0.281)] * PCxG

# Do inner joins on tables to get a fully combined table with all necessary data in one place
dt1 <- data.table(xGoalsPlyrTable, key = "Team") 
dt2 <- data.table(xGoalsTable, key = "Team")
dt3 <- data.table(passTable, key = "Player")
innerJoinOnTeamTable <- dt1[dt2]
innerJoinOnPassTable <- data.table(innerJoinOnTeamTable, key="FullName")[dt3]

# Do calculation
xGProportion <- (as.numeric(as.character(innerJoinOnPassTable[['xG+xAp96']])) / as.numeric(as.character(innerJoinOnPassTable[['xGF/g']])))
plyrSuccessfulPassTotal <- (as.numeric(as.character(innerJoinOnPassTable[['PS%']])) / 100) * as.numeric(as.character(innerJoinOnPassTable[['AvgP']]))
teamSumSuccessfulPasses <- sum(plyrSuccessfulPassTotal)
successfulPassProp <- (plyrSuccessfulPassTotal / teamSumSuccessfulPasses)
PCxG <- xGProportion + successfulPassProp
EPG <- ((3 * 0.483)+(1 * 0.281)) * PCxG

# Produce resulting data frame (Sorted by EPG)
epgFrame = data.frame(innerJoinOnPassTable$FullName, innerJoinOnPassTable[['xG+xAp96']], innerJoinOnPassTable[['xGF/g']], innerJoinOnPassTable[['PS%']], innerJoinOnPassTable[['AvgP']], teamSumSuccessfulPasses, PCxG, EPG)[order(-EPG),] 

# Optional: automatically display data frame after creation
# View(epgFrame)

