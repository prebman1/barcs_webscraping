#setup space
rm(list=ls())

#install needed packages and %notin% function
needed_packages <- c("dplyr", "purrr",  "REDCapR", "httr", "redcapAPI", "lubridate", "kableExtra", "knitr", "janitor", "tidyr", "stringr", "rvest", "devtools", "filesstrings")
missing_packages <- needed_packages[!(needed_packages %in% installed.packages()[,"Package"])]
if(length(missing_packages)) install.packages((missing_packages))
lapply(needed_packages, require, character.only=TRUE)
`%notin%` <- Negate(`%in%`)

install_version("RSelenium", version = "1.7.0", repos = "http://cran.us.r-project.org")
library(RSelenium)

#set the wd to the appropriate folder to be able to access downloads and dropbox/onedrive
# currentwd <- getwd() #store the current wd to be able to reset it after the script finishes
# setwd("/Users/paulcaih/") #set the working directory to someplace where you can access downloads and dropbox

#open session
rD <- rsDriver()
remDr <- rD$client

#### Login ####
#navigate to conncentric login page
remDr$navigate("https://www.barcs.org/adopt-dogs/")
Sys.sleep(3)
adoption_frame <- remDr$findElement(using = "id", "adopt-frame")

#remDr$findElement(using = "class", value = "remodal-close")
#find number of dogs on page
remDr$switchToFrame(adoption_frame)
dog_blocks <- remDr$findElements(using = "class", value = "list-item")
num_dogs <- as.double(length(dog_blocks))
curr_page_html <- remDr$getPageSource()[[1]]
dog_urls <- curr_page_html %>% 
  read_html() %>% 
  html_nodes(".list-animal-photo-block") %>% 
  html_elements("a") %>%
  html_attr("href")

dogs <- as.data.frame(matrix(nrow = 0, ncol = 13))
colnames(dogs) <- c('Animal ID', 'Species', 'Breed', 'Age', 'Gender', 'Size', 'Color', 'Spayed/Neutered', 'Declawed', 'Housetrained', 'Location', 'Intake Date', 'Name')

for(i in 1:length(dog_urls)){
  url <- list_of_dogs1[i]
  
  remDr$navigate(paste0("https://ws.petango.com/webservices/adoptablesearch/", url))
  Sys.sleep(3)
  dog_html <- remDr$getPageSource()[[1]]
  curr_dog <- read_html(dog_html) %>% html_elements("table") %>% html_table()
  curr_dog <- curr_dog[[1]]
  curr_dog <- as.data.frame(t(curr_dog))
  colnames(curr_dog) <- curr_dog[1,]
  curr_dog <- curr_dog[2,]
  if(ncol(curr_dog) != ncol(dogs)){
    for(col in colnames(dogs)){
      if(!(col %in% colnames(curr_dog))) {
        curr_dog[,col] <- NA
      }
    }
  }
  #add in dog name (not in table)
  dog_name <- remDr$findElement(using = "id", value = "lbName")$getElementText()[[1]]
  curr_dog$Name <- dog_name
  
  dogs <- rbind(dogs, curr_dog)
}

remDr$close()
rD$server$stop()

#clean up the names from the downloaded data
dogs <- dogs %>% clean_names()

#add in date and time
dogs$scrape_date <- Sys.Date()
dogs$scrape_time <- Sys.time()

#convert intake date to date format
dogs$intake_date <- as.Date(dogs$intake_date, format = "%m/%d/%Y")

#calculate length of time since intake
dogs$days_since_intake <- dogs$scrape_date

dogs$days_since_intake <- dogs$scrape_date - dogs$intake_date
dogs$days_since_intake <- as.numeric(dogs$days_since_intake)

dogs$age_years <- str_extract(dogs$age, "[0-9][0-9]* year")
dogs$age_years <- str_remove(dogs$age_years, " year")

dogs$age_years[is.na(dogs$age_years) & grepl("month", dogs$age)]<- 0
dogs$age_years <- as.numeric(dogs$age_years)

dogs$color_primary <- sapply(str_split(dogs$color, "/"), `[`,1)

#write.csv(dogs, paste0("OneDrive/Documents/Barcs Webscraping/Output/dogs_download_", format(Sys.Date(), "%Y_%m_%d"), ".csv"), row.names = FALSE)
