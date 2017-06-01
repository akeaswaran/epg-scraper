# EPG Scraper

A web-scraper built with R used to calculate Expected Points Generated for MLS teams using data from WhoScored.com and American Soccer Analysis.

## Methodology

I developed EPG to better measure how much a soccer player contributes to their team. Read more [here](https://akeaswaran.me/epg/).

## Setup

* [Install R](https://www.r-project.org), and clone this repo.

* [Install RStudio](https://www.rstudio.com) for an easy-to-use dev environment for R scripts.

* Install [Firefox](https://www.mozilla.org/en-US/firefox/) if necessary. I haven't tested this script with any other webdrivers.

## Running EPG Scraper

Open up a new Terminal window, `cd` into this repo, and run `java -Dwebdriver.gecko.driver=geckodriver -jar selenium-server-standalone-3.4.0.jar`.

Open the script in RStudio. Enter and run each of the following commands in the command-line window to install the required dependencies.

    install.packages("RSelenium")
    install.packages("XML")
    install.packages("plyr")
    install.packages("data.tabl"e)
    install.packages("stringi")
    install.packages("scales")


Make sure you have set the current working directory to the repo's directory via `Session > Set Working Directory... > To Source File Location`, and hit the Source button in the top-right of the Source window on the left-hand side of the RStudio window. This will run the entire script and cache the methods so you can use them from the command line.

## Scraper Methods

`retrieveAllTeamEPGs(shouldMergeCSVs = FALSE)`: Creates EPG files for all teams and stores them under `/teams`. Calls `mergeCSVs` to collate the CSV files if `shouldMergeCSVs` is true. Uses `retrieveTeamsEPG()` under the hood.

`retrieveSingleTeamEPG(team)`: Takes in a team abbreviation from the `teams` list in the script, creates an EPG data frame for the team, and stores it as a CSV file under `teams/team.csv`.

`retrieveTeamsEPG(teams)`: Takes in a vector of team abbreviations from the `teams` list in the script, creates the EPG frames for those teams, and stores them as individual CSV files under `/teams`.

`mergeCSVs()`: Merges all CSV files under `/teams` into one big file for the entire league, which is saved in the working directory as `mls-epg.csv`.

`comparePoints(team)`: Calculates the sum of the EPGs for all of a specific team's players and prints a comparison between EPG/EPG per game and Points/PPG to the console.

`compareLeagueTable()`: Consolidates EPG sums for each club and league standings in one data frame, which is saved as `mls-epg-comparisons.csv` in the working directory.

## Example Outputs

[Here's an example CSV file for Atlanta United produced by `retrieveSingleTeamEPG('ATL')`](https://github.com/akeaswaran/epg-scraper/blob/master/teams/ATL.csv). CSV files for other teams can be found in the [`/teams` folder](https://github.com/akeaswaran/epg-scraper/blob/master/teams).

[Here's an example CSV output for the entire league using `retrieveAllTeamEPGs(shouldMergeCSVs = TRUE)`](https://github.com/akeaswaran/epg-scraper/blob/master/mls-epg.csv).

## License

See [LICENSE](https://github.com/akeaswaran/epg-scraper/blob/master/LICENSE) for more details.
