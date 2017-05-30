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

Open the script in RStudio, and hit the Source button in the top-right of the Source window on the left-hand side of the RStudio window. This will run the entire script.

[Here's an example CSV output for Atlanta United](https://github.com/akeaswaran/epg-scraper/blob/master/epg.csv).

## License

See [LICENSE](https://github.com/akeaswaran/epg-scraper/blob/master/LICENSE) for more details.
