# EPG Scraper

A web-scraper built with R used to calculate Expected Points Generated for MLS teams using data from WhoScored.com and American Soccer Analysis

## Methodology

I developed EPG to better measure how much a soccer player contributes to their team. Read more [here](https://akeaswaran.me/epg/).

## Setup

* [Install R](https://www.r-project.org), and clone this repo. Make sure you have Firefox or Chrome installed.

* [Install RStudio](https://www.rstudio.com) for an easy-to-use dev environment for R scripts.

## Running EPG Scraper

Open up a new Terminal window, `cd` into this repo, and run `java -Dwebdriver.gecko.driver=geckodriver -jar selenium-server-standalone-3.4.0.jar` if you want to use Firefox, or `java -Dwebdriver.chrome.driver=chromedriver -jar selenium-server-standalone-3.4.0.jar`.
Make sure you change the browser name in the script to whatever browser you choose.

Open the script in RStudio, make sure you have set the current working directory to the repo's directory via `Session > Set Working Directory... > To Source File Location`, and hit the Source button in the top-right of the Source window on the left-hand side of the RStudio window. This will run the entire script and cache the methods so you can use them from the command line.

## Main Methods

`retrieveAllTeamEPGs()`: Creates EPG files for all teams, stores them under teams/team.csv, and collates them into one big file, which will be saved in the working directory as `mls-epg.csv`

`buildSingleTeamEPG(team)`: takes in a team abbreviation from the `teams` list in the script, creates the EPG file for it, and stores it as a CSV file under teams/team.csv

## Example Output

[Here's an example CSV output for Atlanta United using `buildSingleTeamEPG('ATL')`](https://github.com/akeaswaran/epg-scraper/blob/master/teams/ATL.csv).

## License

See [LICENSE](https://github.com/akeaswaran/epg-scraper/blob/master/LICENSE) for more details.
