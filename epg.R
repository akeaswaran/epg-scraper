# EPG Scraper
# Author: Akshay Easwaran <akeaswaran@me.com>
# License: MIT

# Required Packages
require(RSelenium)
require(XML)
require(plyr)
require(data.table)
require(stringi)
require(scales)

rm(list=ls())

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

replaceForeignChars <- function(dat,fromto) {
    for(i in 1:nrow(fromto) ) {
        dat <- gsub(fromto$from[i],fromto$to[i],dat)
    }
    dat
}

# Team dataset
teams <- c("ATL","CHI","CLB","COL","DAL","DC","HOU","LA","MN","MTL","NE","NYC","NYRB","ORL","PHI","POR","RSL","SEA","SJ","SKC","TOR","VAN")

team_urls <- c("https://www.whoscored.com/Teams/26666/Show/USA-Atlanta-United",
               "https://www.whoscored.com/Teams/1118/Show/USA-Chicago-Fire",
               "https://www.whoscored.com/Teams/1113/Show/USA-Columbus-Crew",
               "https://www.whoscored.com/Teams/1120/Show/USA-Colorado-Rapids",
               "https://www.whoscored.com/Teams/2948/Show/USA-FC-Dallas",
               "https://www.whoscored.com/Teams/1119/Show/USA-DC-United",
               "https://www.whoscored.com/Teams/3624/Show/USA-Houston-Dynamo",
               "https://www.whoscored.com/Teams/1117/Show/USA-LA-Galaxy",
               "https://www.whoscored.com/Teams/9293/Show/USA-Minnesota-United",
               "https://www.whoscored.com/Teams/11135/Show/Canada-Montreal-Impact",
               "https://www.whoscored.com/Teams/1114/Show/USA-New-England-Rev-",
               "https://www.whoscored.com/Teams/19584/Show/USA-New-York-City-FC",
               "https://www.whoscored.com/Teams/1121/Show/USA-New-York-Red-Bulls",
               "https://www.whoscored.com/Teams/10221/Show/USA-Orlando-City",
               "https://www.whoscored.com/Teams/8586/Show/USA-Philadelphia-Union",
               "https://www.whoscored.com/Teams/11133/Show/USA-Portland-Timbers",
               "https://www.whoscored.com/Teams/2947/Show/USA-Real-Salt-Lake",
               "https://www.whoscored.com/Teams/5973/Show/USA-Seattle-Sounders-FC",
               "https://www.whoscored.com/Teams/1122/Show/USA-San-Jose-Earthquakes",
               "https://www.whoscored.com/Teams/1116/Show/USA-Sporting-Kansas-City",
               "https://www.whoscored.com/Teams/4186/Show/Canada-Toronto-FC",
               "https://www.whoscored.com/Teams/11134/Show/Canada-Vancouver-Whitecaps")

teamUrlTable <- data.frame(teams, team_urls)

loadWSDataFrame <- function(driver, tableCssSelector, buttonCssSelector) {
    print('Building data frame from WhoScored...')

    # wait a little bit in the interim
    Sys.sleep(0.5)
    webElem <- driver$findElement("css", "body")
    webElem$sendKeysToElement(list(key = "down_arrow"))
    webElem$sendKeysToElement(list(key = "down_arrow"))
    Sys.sleep(0.5)

    # Find the right tab
    webElem <- driver$findElement(using = "css", buttonCssSelector)

    # ~~ some waiting logic here ~~
    tempPassTableHTML <- driver$findElement(using = 'id', value = tableCssSelector)
    webElem$clickElement()
    while (webElem$getElementAttribute('class') != "selected") {
        print("waiting for tab click, reclicking after 1 second...")
        # move the page just to possibly trigger the load
        webElem$sendKeysToElement(list(key = "down_arrow"))
        webElem$sendKeysToElement(list(key = "down_arrow"))
        webElem$clickElement()
        Sys.sleep(1)
    }

    while (grepl("is-updating", tempPassTableHTML$getElementAttribute("outerHTML"))) {
        print("waiting for page load...")
        #  move the page just to possibly trigger the load
        webElem$sendKeysToElement(list(key = "down_arrow"))
        webElem$sendKeysToElement(list(key = "down_arrow"))
        Sys.sleep(1)
    }

    Sys.sleep(1)
    # Scrape table html into R data frame
    tempPassTableTxt <- tempPassTableHTML$getElementAttribute("outerHTML")[[1]]
    producedFrame <- readHTMLTable(tempPassTableTxt, header=TRUE, as.data.frame=TRUE)[['top-player-stats-summary-grid']]

    # WhoScored's player data often contains more than we need.
    # Strip out the position, age, etc and only put the player's actual name back in the table.
    y <- strsplit(as.character(producedFrame$Player), " ")
    producedFrame$Player <- lapply(y, function(x) {
        # Check if the player has a second last name (IE: the third element when string splitting is NOT his age - EX: Leando Gonzalez Pirez)
        if (!grepl("[-]?[0-9]+[.]?[0-9]*|[-]?[0-9]+[L]?|[-]?[0-9]+[.]?[0-9]*[eE][0-9]+", x[3]) && x[3] != 'NA') {
            paste(x[1],x[2],x[3])
        } else if (!grepl("[-]?[0-9]+[.]?[0-9]*|[-]?[0-9]+[L]?|[-]?[0-9]+[.]?[0-9]*[eE][0-9]+", x[2]) && x[2] != 'NA') {
            paste(x[1],x[2])
        } else {
            paste(x[1])
        }
    })

    # Fix character encoding issues and replace foreign chars
    producedFrame$Player <- as.character(replaceForeignChars(iconv(as.character(producedFrame$Player), from="UTF-8", to="ISO-8859-1"), fromto))

    # Find sum of appearances
    app <- strsplit(as.character(producedFrame$Apps), "\\(")
    producedFrame$Apps <- lapply(app, function(a) {
        if (length(a) > 1) {
            sum <- as.numeric(a[1]) + as.numeric(gsub(")", "", a[2]))
            paste(sum)
        } else {
            paste(a[1])
        }
    })

    producedFrame$TotalPossibleMinutes <- as.numeric(as.character(producedFrame$Apps)) * 96
    producedFrame
}

buildASATables <- function(remDr) {
    print('Building ASA tables...')
    # Go to ASA's Team xGoals sheet
    remDr$navigate("http://www.americansocceranalysis.com/team-xg-2017/")

    # Scrape Team xGoals table html into R data frame
    xGoalsTblHTML <- remDr$findElement(using = "css", "#block-yui_3_17_2_35_1488824086586_9407 > div > table")
    xGoalsTxt <- xGoalsTblHTML$getElementAttribute("outerHTML")[[1]]
    xGoalsTable <<- readHTMLTable(xGoalsTxt, header=TRUE, as.data.frame=TRUE)[[1]]

    # -------

    # Go to ASA's Player xGoals sheet
    remDr$navigate("http://www.americansocceranalysis.com/player-xg-2017/")

    # Scrape Player xGoals table html into R data frame
    xGoalsPlyrTblHTML <- remDr$findElement(using = "css", "#block-yui_3_17_2_23_1488824086586_3871 > div > table")
    xGoalsPlyrTxt <- xGoalsPlyrTblHTML$getElementAttribute("outerHTML")[[1]]
    xGoalsPlyrTable <<- readHTMLTable(xGoalsPlyrTxt, header=TRUE, as.data.frame=TRUE)[[1]]
    xGoalsPlyrTable[['Touch%']] <<- as.numeric(gsub("%", "", xGoalsPlyrTable[['Touch%']]))

    # -------

    # Go to ASA's most recent Player Salaries sheet
    remDr$navigate("http://www.americansocceranalysis.com/april-15-2017/")

    # Scrape player salaries table into R data frame
    plyrSalariesHTML <- remDr$findElement(using = "css", "#block-yui_3_17_2_3_1493151916250_3677 > div > table")
    plyrSalariesTxt <- plyrSalariesHTML$getElementAttribute("outerHTML")[[1]]
    plyrSalariesTable <<- readHTMLTable(plyrSalariesTxt, header=TRUE, as.data.frame=TRUE)[[1]]

    # -------

    # Do some minor cleanup - replace team names with Abbrev and add full name to player table; clean up salaries
    xGoalsTable$Team <<- mapvalues(xGoalsTable$Team,
                                  from=c("Atlanta United","Chicago","Columbus","Colorado","FC Dallas","DC United","Houston","L.A. Galaxy","Minnesota United","Montreal","New England","New York City FC","New York","Orlando City","Philadelphia","Portland","Salt Lake","Seattle","San Jose","Kansas City","Toronto","Vancouver"),
                                  to=teams)
    xGoalsPlyrTable$FullName <<- paste(xGoalsPlyrTable$First,xGoalsPlyrTable$Last)
    plyrSalariesTable$FullName <<- paste(plyrSalariesTable$First,plyrSalariesTable$Last)
    plyrSalariesTable$TotalSalary <<- as.numeric(gsub("\\$","", gsub(",","", gsub(",","", gsub(",","", plyrSalariesTable$`Base Salary`))))) + as.numeric(gsub("\\$","", gsub(",","", gsub(",","", gsub(",","", plyrSalariesTable$`Guaranteed Compensation`)))))
}

populateTeamEPG <- function(remDr, teamAbbrev) {
    print(paste0('Calculating EPG for ', teamAbbrev, '...'))
    teamUrl <- teamUrlTable$team_urls[which(teamUrlTable$teams == teamAbbrev)]

    # navigate to WhoScored
    print(paste0('Navigating to ', teamUrl, '...'))
    remDr$navigate(as.character(teamUrl))

    # Scrape passing stats for the team from WhoScored
    print(paste0('Scraping pass stats for ', teamAbbrev, '...'))
    passTable <- loadWSDataFrame(remDr, "statistics-table-passing", "li.in-squad-detailed-view:nth-child(4) > a:nth-child(1)")

    # Scrape defenesive stats for the team from WhoScored
    print(paste0('Scraping def stats for ', teamAbbrev, '...'))
    defTable <- loadWSDataFrame(remDr, "statistics-table-defensive", "li.in-squad-detailed-view:nth-child(2) > a:nth-child(1)")

    print(paste0('Running calculations for ', teamAbbrev, '...'))
    # For every player, we want to:
    # 1. Get the necessary stats for them: xGoals and xAssists, etc
    # 2. Get necessary team stats (map team abbrev to team name)
    # 3. Plug stats into formula
    # 4. Add Player name and formula result to table
    # After completion, we need to display table

    # Formulas:
    # OCxG = ((PxG / TxG) + (((PSPxG / 100) * PPxG) / TSPxG) + (TPxG / 100)) recaled btwn 0 to 1
    # DCxG = ((Mean of all categories - Avg Player Mean) / Avg Player Mean) rescaled btwn 0 to 1
    # PCxG = abs((OCxG + DCxG) * (Min / TPM))
    # EPG=[(3 * 0.483)+(1 * 0.281)] * PCxG

    # Do inner joins on tables to get a fully combined table with all necessary data in one place
    dt1 <- data.table(xGoalsPlyrTable, key = "Team")
    dt2 <- data.table(xGoalsTable, key = "Team")
    dt3 <- data.table(passTable, key = "Player")
    dt4 <- data.table(defTable, key = "Player")
    dt5 <- data.table(plyrSalariesTable, key = "FullName")
    innerJoinOnTeamTable <- dt1[dt2]
    innerJoinOnPassTable <- data.table(innerJoinOnTeamTable, key="FullName")[dt3]
    innerJoinOnDefTable <- innerJoinOnPassTable[dt4]
    joinOnSalariesTable <- dt5[innerJoinOnDefTable]

    # Do OCxG calculation
    xGProportion <- (as.numeric(as.character(joinOnSalariesTable[['xG+xAp96']])) / as.numeric(as.character(joinOnSalariesTable[['xGF/g']])))
    xGProportion[is.na(xGProportion)] <- 0

    plyrSuccessfulPassTotal <- (as.numeric(as.character(joinOnSalariesTable[['PS%']])) / 100) * as.numeric(as.character(joinOnSalariesTable[['AvgP']]))
    plyrSuccessfulPassTotal[is.na(plyrSuccessfulPassTotal)] <- 0

    teamSumSuccessfulPasses <- sum(plyrSuccessfulPassTotal)
    successfulPassProp <- (plyrSuccessfulPassTotal / teamSumSuccessfulPasses)

    touchPercent <- (as.numeric(joinOnSalariesTable[['Touch%']])) / 100
    touchPercent[is.na(touchPercent)] <- 0

    OF <- as.numeric(as.character(joinOnSalariesTable[['G+A']])) / as.numeric(as.character(joinOnSalariesTable[['GF']]))
    OF[is.na(OF)] <- 0

    OCxG <- (xGProportion + successfulPassProp + touchPercent + OF)
    OCxG <- rescale(OCxG, c(0,1))

    # Do DCxG calculation
    tklProp <- (as.numeric(joinOnSalariesTable[['Tackles']]) / sum(as.numeric(joinOnSalariesTable[['Tackles']])))
    intProp <- (as.numeric(joinOnSalariesTable[['Inter']]) / sum(as.numeric(joinOnSalariesTable[['Inter']])))
    offProp <- (as.numeric(joinOnSalariesTable[['Offsides']]) / sum(as.numeric(joinOnSalariesTable[['Offsides']])))
    clrProp <- (as.numeric(joinOnSalariesTable[['Clear']]) / sum(as.numeric(joinOnSalariesTable[['Clear']])))
    blkProp <- (as.numeric(joinOnSalariesTable[['Blocks']]) / sum(as.numeric(joinOnSalariesTable[['Blocks']])))
    ownGoalWeight <- (as.numeric(joinOnSalariesTable[['OwnG']]) * -0.1)
    plyrAvgRat <- ((as.numeric(joinOnSalariesTable[['Tackles']])) + as.numeric(joinOnSalariesTable[['Inter']]) + as.numeric(joinOnSalariesTable[['Offsides']]) + as.numeric(joinOnSalariesTable[['Clear']]) + as.numeric(joinOnSalariesTable[['Blocks']])) / 5
    sumAvgPlyrRat <- ((sum(as.numeric(joinOnSalariesTable[['Tackles']])) / length(as.numeric(joinOnSalariesTable[['Tackles']]) + sum(as.numeric(joinOnSalariesTable[['Offsides']])) / length(as.numeric(joinOnSalariesTable[['Offsides']])) + sum(as.numeric(joinOnSalariesTable[['Clear']])) / length(as.numeric(joinOnSalariesTable[['Clear']])) + sum(as.numeric(joinOnSalariesTable[['Inter']])) / length(as.numeric(joinOnSalariesTable[['Inter']])) + sum(as.numeric(joinOnSalariesTable[['Blocks']])) / length(as.numeric(joinOnSalariesTable[['Blocks']])))) / 5)
    DCxG <- rescale(((plyrAvgRat - sumAvgPlyrRat) / sumAvgPlyrRat), c(0,1))

    # Calculate weight for play time
    appWeight <- (as.numeric(as.character(joinOnSalariesTable$Min)) / (as.numeric(as.character(joinOnSalariesTable$TotalPossibleMinutes))))

    # Calculate PCxG and EPG
    PCxG <- (OCxG + DCxG) * appWeight
    EPG <- ((3 * 0.483)+(1 * 0.281)) * PCxG

    # Produce final data frame (Sorted by EPG)
    epgFrame = data.frame(joinOnSalariesTable$FullName, joinOnSalariesTable$Team, joinOnSalariesTable$TotalSalary, joinOnSalariesTable$Min, as.numeric(joinOnSalariesTable$Apps), joinOnSalariesTable$TotalPossibleMinutes, appWeight, joinOnSalariesTable[['xGp96']], OCxG, DCxG, PCxG, EPG)[order(-EPG),]
    colnames(epgFrame) <- c("Full Name","Team", "Salary ($)", "Total Minutes","Appearances", "Total Possible Minutes", "Appearance Weight","xGoals", "Offensive Contribution to Team", "Defensive Contribution to Team", "Total Expected Player Contribution to Team", "EPG")

    print(paste0('Returning completed frame for ', teamAbbrev, '.'))
    epgFrame
}

retrieveSingleTeamEPG <- function(team) {
    print(paste0('Getting EPGs for ', team, '...'))

    # connect to selenium server
    print('Connecting to selenium server...')
    remoteDr <- remoteDriver(remoteServerAddr = "localhost"
                             , port = 4444
                             , browserName = "firefox"
    )
    remoteDr$open()

    # Build the player, team, and salary data sets from ASA
    if (!exists("xGoalsTable") || !exists("xGoalsPlyrTable") || !exists("plyrSalariesTable")) {
        buildASATables(remoteDr)
    }

    frame <- populateTeamEPG(remoteDr, team)

    # close the Selenium connection to clean up since we're done scraping
    print('Closing Selenium connection...')
    remoteDr$quit()

    # Check if '/teams' exists in the current path - if not, create it
    if (!dir.exists(file.path(".", "teams"))) {
        print('Creating /teams directory...')
        dir.create(file.path(".", "teams"))
    }

    # Write the frame to csv
    fileName <- paste0('teams/', team, '.csv')
    print(paste0('Writing frame to file ', fileName))
    write.csv(frame, file = fileName)

    print('Done!')
}

# Get subset of teams' EPGs
retrieveTeamsEPG <- function(teamList) {
    # print(paste0('Getting EPGs for ', teamList, '...'))

    # connect to selenium server
    print('Connecting to selenium server...')
    remoteDr <- remoteDriver(remoteServerAddr = "localhost"
                             , port = 4444
                             , browserName = "firefox"
    )
    remoteDr$open()

    # Build the player, team, and salary data sets from ASA
    if (!exists("xGoalsTable") || !exists("xGoalsPlyrTable") || !exists("plyrSalariesTable")) {
        buildASATables(remoteDr)
    }


    # Check if '/teams' exists in the current path - if not, create it
    if (!dir.exists(file.path(".", "teams"))) {
        print('Creating /teams directory...')
        dir.create(file.path(".", "teams"))
    }

    # Build the EPG frame for each team specified
    lapply(teamList, function(team) {
        frame <- populateTeamEPG(remoteDr, team)
        fileName <- paste0('teams/', team, '.csv')
        print(paste0('Writing frame to file ', fileName))
        write.csv(frame, file = fileName)
    })

    # close the Selenium connection to clean up since we're done scraping
    print('Closing Selenium connection...')
    remoteDr$quit()

    print('Done!')
}

# Get all teams' EPGs
retrieveAllTeamEPGs <- function(shouldMergeCSVs = FALSE) {
    retrieveTeamsEPG(teams)

    if (shouldMergeCSVs) {
        mergeCSVs()
    }
}

# Collate all csvs
mergeCSVs <- function() {
    fileList <- list.files(path = "teams", full.names = TRUE)
    if (length(fileList) > 0) {
        print('Non-zero amount of files found, stitching them together...')
        dataFrameList <- lapply(fileList, read.csv)
        total <- do.call("rbind", dataFrameList)
        total <- total[order(-total$EPG),]
        colnames(total) <- c("X","Full Name","Team", "Salary ($)", "Total Minutes","Appearances", "Total Possible Minutes", "Appearance Weight","xGoals", "Offensive Contribution to Team", "Defensive Contribution to Team", "Total Expected Player Contribution to Team", "EPG")

        print('Writing team array\'s data to file mls-epg.csv...')
        write.csv(total, 'mls-epg.csv')
    }

    print('Done!')
}
