#setup space
rm(list=ls())

#install needed packages and %notin% function
needed_packages <- c("dplyr", "purrr",  "REDCapR", "httr", "redcapAPI", "lubridate", "kableExtra", "knitr", "janitor", "tidyr", "stringr", "rvest", "RSelenium", "filesstrings")
missing_packages <- needed_packages[!(needed_packages %in% installed.packages()[,"Package"])]
if(length(missing_packages)) install.packages((missing_packages))
lapply(needed_packages, require, character.only=TRUE)
`%notin%` <- Negate(`%in%`)

#set the wd to the appropriate folder to be able to access downloads and dropbox/onedrive
currentwd <- getwd() #store the current wd to be able to reset it after the script finishes
setwd("/Users/paulcaih/") #set the working directory to someplace where you can access downloads and dropbox

eCaps <- list(
  chromeOptions = 
    list(prefs = list(
      "profile.default_content_settings.popups" = 0L,
      "download.prompt_for_download" = FALSE,
      "download.default_directory" = "/Users/paulcaih/Desktop/Barcs Webscraping"
    )
    )
)

#open session
rD <- rsDriver(chromever = "97.0.4692.71", port = 4444L, extraCapabilities = eCaps)
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
  # dog_html <- remDr$getPageSource()[[1]]
  # list_of_dogs2 <- dog_html %>% read_html() %>% html_nodes(".list-item") %>% html_text()
  # #print(dog_html) #print the dog_html output for troubleshooting
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
#dog_links <- remDr$findElements(using="class", "list-animal-photo")
# remDr$findElements(using="class", "list-animal-photo")[[1]]$clickElement()
# 
# dog_html <- remDr$getPageSource()[[1]]
# curr_dog <- read_html(dog_html) %>% html_elements("table") %>% html_table()
# curr_dog <- curr_dog[[1]]
# curr_dog <- as.data.frame(t(curr_dog))
# colnames(curr_dog) <- curr_dog[1,]
# curr_dog <- curr_dog[2,]


# 
# remDr$goBack()
# remDr$switchToFrame(adoption_frame)
# remDr$findElements(using="class", "list-animal-photo")[[2]]$clickElement()
# remDr$navigate("https://www.barcs.org/adopt-dogs/")
# Sys.sleep(3)
# adoption_frame <- remDr$findElement(using = "id", "adopt-frame")
# # remDr$switchToFrame(adoption_frame)
# # remDr$findElements(using="class", "list-animal-photo")[[1]]$clickElement()
# # remDr$goBack()
# for(i in 1:num_dogs){
#   remDr$switchToFrame(adoption_frame)
#   Sys.sleep(4)
#   # if(i == 1){
#   #   remDr$findElements(using="class", "list-animal-photo")[[i]]$clickElement()
#   # }
#   dog_html <- remDr$getPageSource()[[1]]
#   list_of_dogs2 <- dog_html %>% read_html() %>% html_nodes(".list-item") %>% html_text()
#   print(list_of_dogs2)
#   print(length(remDr$findElements(using="class", "list-animal-photo")))
#   print(i)
#   remDr$findElements(using="class", "list-animal-photo")[[i]]$clickElement()
#   Sys.sleep(4)
#   # dog_html <- remDr$getPageSource()[[1]]
#   # list_of_dogs2 <- dog_html %>% read_html() %>% html_nodes(".list-item") %>% html_text()
#   # #print(dog_html) #print the dog_html output for troubleshooting
#   curr_dog <- read_html(dog_html) %>% html_elements("table") %>% html_table()
#   print(curr_dog)
#   curr_dog <- curr_dog[[1]]
#   curr_dog <- as.data.frame(t(curr_dog))
#   colnames(curr_dog) <- curr_dog[1,]
#   curr_dog <- curr_dog[2,]
#   if(ncol(curr_dog) != ncol(dogs)){
#     for(col in colnames(dogs)){
#       if(!(col %in% colnames(curr_dog))) {
#         curr_dog[,col] <- NA
#       }
#     }
#   }
#   #add in dog name (not in table)
#   dog_name <- remDr$findElement(using = "id", value = "lbName")$getElementText()[[1]]
#   curr_dog$Name <- dog_name
#   
#   # #download photo
#   # dog_image <- remDr$findElement(using = "id", value = "imgAnimalPhoto")
#   # dog_image_url <- dog_image$getElementAttribute("src")[[1]]
#   # 
#   # download.file(dog_image_url, paste0("Downloads/", dog_name, ".jpg"))
#   
#   #,mode = "wb"
#   
#   dogs <- rbind(dogs, curr_dog)
#   #Sys.sleep(4)
#   remDr$goBack()
#   Sys.sleep(4)
#   
# }

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

write.csv(dogs, paste0("OneDrive/Documents/Barcs Webscraping/Output/dogs_download_", format(Sys.Date(), "%Y_%m_%d"), ".csv"), row.names = FALSE)

######### End of getting data ##################

ggplot(data = dogs, aes(y = gender, x = days_since_intake, color = gender)) +
  geom_violin() +
  geom_point()

dogs_no_fosters <- dogs %>% filter(location != "Foster Home")

ggplot(data = dogs_no_fosters, aes(y = days_since_intake, x = age_years)) +
  geom_point() +
  #geom_smooth(method = "lm") +
  geom_label(aes(label = name))

ggplot(data = dogs, aes(y = color_primary, x = days_since_intake, color = color_primary)) +
  geom_point()

ggplot(data = dogs, aes(y = size, x = days_since_intake, color = size)) +
  geom_violin() +
  geom_point()

ggplot(data = dogs, aes(y = location, x = days_since_intake, color = location)) +
  geom_violin() +
  geom_point()

sapply(c("size", "gender", "age_years", "color_primary"), function(x){lm(days_since_intake ~ x, data = dogs)})
summary(lm(days_since_intake ~ size, data = dogs))
summary(lm(days_since_intake ~ gender, data = dogs))
summary(lm(days_since_intake ~ age_years, data = dogs))
summary(lm(days_since_intake ~ color_primary, data = dogs))

summary(lm(days_since_intake ~ size + gender + age_years, data = dogs))

t.test(days_since_intake ~ gender, data = dogs)

remDr$click(dog_links[1])



dog_links <- read_html(dogs_page) %>% html_elements("a") %>% html_attr("href")

email <- "prebman1@jhmi.edu"
remDr$findElement(using = "id", "email")$sendKeysToElement(list(email))
remDr$findElement(using = "class", "button")$clickElement()

#wait for there to be a password element before moving on
webElem <-NULL
while(is.null(webElem)){
  webElem <- tryCatch({remDr$findElement(using = 'id', value = "password")},
                      error = function(e){NULL})
  #loop until element with id password is found on the page
}

password <- "yej%^%cpR6@t8M9TnA"
remDr$findElement(using = "id", "password")$sendKeysToElement(list(password))
remDr$findElement(using = "class", "button")$clickElement()

#### Download Pooled Testing Data ####
school_ids <- c('d18ee889-647f-4192-a394-c99ac676beeb',
                'c083d41b-53e1-4e3f-b749-7a25be584969',
                '42ed8a8e-5f76-403f-8b75-74190079b41b',
                '912b82c9-f541-461c-bdcc-e0850053b18a',
                '215c4d3b-85c8-41c0-912d-3255ab2da78b',
                '848808ef-7448-443b-92b1-96e48ec2b1ea',
                '9a8feef2-b24d-463a-b1e7-62f51b2d69ea',
                '9f41a3e0-4c08-4f95-80ee-0c7cb3778626',
                '76932898-c805-4ad6-b623-5bc0caa3fb36',
                '11452ebe-7ec2-4345-b58f-8a67bc1327ec',
                '28e851ff-206f-445e-8e3d-1cd8c20da64e',
                '3cb8ff9a-e372-4fce-b6a5-86ded88d9f80',
                'ff4b0d8f-2cc4-4e80-b676-872b70c665e8',
                'a527d10c-0c1e-434c-8a93-4acc7db3d999',
                'bc375ae5-c3d7-4598-9498-77c84d43b47b',
                '2b60d6db-6703-4f59-b662-9f0f8e6b342a',
                'b8dbd491-d7a0-4d39-aaef-dc06771ea132',
                '063b76d7-c428-4af7-8ace-7b953522c247',
                'c6e18e07-2da9-46a4-8609-b6664eeddb53',
                '23c3c84b-23aa-4c40-b272-0711c73c3d46',
                'b50a486f-f7a6-4559-bdb7-9de1940be73a',
                'fed03cdd-2755-4f75-b081-af12d3e7f68e',
                '38b1c66c-c1ae-40ed-92b8-cd5ec3a39fa3',
                '83f7b142-e7ed-4a81-8994-30f8707e1975',
                '78a377d2-4e83-49ce-ae1f-5502ada71f88',
                '553cd053-dbf7-4d9b-8807-173a1be77448',
                '1f8f7ce1-4cc9-47c5-a444-af8e70fd18d5',
                'c1ab8000-a242-43d0-aefe-45a174a27ac9',
                '2aca726b-f6c4-4107-8128-ed44ded69948')

#before you download the files, get the list of all the files that are currently in the downloads folder
current_downloads <- list.files("/Users/paulcaih/Downloads/")

for(i in 1:length(school_ids)){
  pool_download_url <- paste0("https://testcenter.concentricbyginkgo.com/", school_ids[i], "/champion/pooled-tests.csv?")
  remDr$navigate(pool_download_url)
}
Sys.sleep(10)
#### Move Pooled Data to Appropriate Folder ####
# we will first get a list of all the files we want to copy.
# then we will prepare the folders where we want to put the files by moving any existing files to archive
# then we will first copy the files we want to Emily's folder and then move them to Paul's folder

##prep list of downloaded files
#get the file names for the pooled samples that were downloaded
downloaded_files <- list.files("/Users/paulcaih/Downloads/") #list all files in the downloads folder
downloaded_files <- downloaded_files[downloaded_files %notin% current_downloads] #only select those files that weren't in downloads when you started the script
#concat the directory with the file names
downloaded_files_paths <- paste0("/Users/paulcaih/Downloads/", downloaded_files)

#only select files that have some data (files without any data were creating issues for Emily's code for cleaning in STATA)
download_files_data <- lapply(downloaded_files_paths, read.csv) #read each csv
files_to_keep <- sapply(download_files_data, nrow) > 0 #create a string of logicals for if each csv has at least 1 row of data
downloaded_files_paths <- downloaded_files_paths[files_to_keep] #use the string of logicals to remove anything that doesn't have any data

### prep Paul's destination folder to be able to copy files

#find the list of downloaded pooled data in the folder that you want to replace
current_pooled_downloads <- list.files("Dropbox/School Surveillance Project - CAIH/16. Data Analysis/School Testing Brief Report/Data/Total Tests and Positive Pools/Pooled Samples")
current_pooled_downloads <- current_pooled_downloads[!grepl("ARCHIVE", current_pooled_downloads)] #remove the archive folder from the list

#if there are currently any files in the destination folder, move them to an archive
if(length(current_pooled_downloads) > 0) {
  #find the date of those downloads
  current_pooled_downloads_date <- str_extract(current_pooled_downloads[1], "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]")
  
  #concat the path with the names of the current downloads
  current_pooled_downloads <- paste0("/Users/paulcaih/Dropbox/School Surveillance Project - CAIH/16. Data Analysis/School Testing Brief Report/Data/Total Tests and Positive Pools/Pooled Samples/", current_pooled_downloads)
  
  #create a new folder in the archive for the previous pooled downloads and move them to that folder
  dir.create(paste0("/Users/paulcaih/Dropbox/School Surveillance Project - CAIH/16. Data Analysis/School Testing Brief Report/Data/Total Tests and Positive Pools/Pooled Samples/ARCHIVE/", current_pooled_downloads_date))
  file.move(current_pooled_downloads, paste0("/Users/paulcaih/Dropbox/School Surveillance Project - CAIH/16. Data Analysis/School Testing Brief Report/Data/Total Tests and Positive Pools/Pooled Samples/ARCHIVE/", current_pooled_downloads_date), overwrite = TRUE)      
}

### prep Emily's destination folder and copy folders there

#create folders for Emily in Ondedrive
#check if the folder (named after the date) currently exists. This will allow us to run the script more than once a day
emily_new_folder_name <- paste0("/Users/paulcaih/OneDrive - Johns Hopkins/My files/Project SafeSchools - Implementation/18. Testing Data Downloads/Pooled/", format(Sys.Date(), "%b_%d_%y"))
emily_folder_already_exists <- dir.exists(emily_new_folder_name)

if(emily_folder_already_exists){
  #if it exists, create a new folder in the ARCHIVE with the date and time and move the files in that folder to the new folder.
  archive_folder_name <- paste0("/Users/paulcaih/OneDrive - Johns Hopkins/My files/Project SafeSchools - Implementation/18. Testing Data Downloads/Pooled/0. Archive/", format(Sys.Date(), "%b_%d_%y"))
  
  #if the archive folder name already exists, then add a number to the end of the name to create an additional folder in the archive
  file_num <- 0
  while(file.exists(archive_folder_name)){
    file_num <- file_num + 1
    archive_folder_name <- paste0("/Users/paulcaih/OneDrive - Johns Hopkins/My files/Project SafeSchools - Implementation/18. Testing Data Downloads/Pooled/0. Archive/", format(Sys.Date(), "%b_%d_%y"), " ", file_num)
  }
  
  dir.create(archive_folder_name)
  
  #if there are any files in the folder where we want to move the new files, move them to the archive folder
  current_pooled_csvs_to_move_emily <- list.files(emily_new_folder_name)
  if(length(current_pooled_csvs_to_move_emily) > 0 ){
    current_pooled_csvs_to_move_emily <- paste0(emily_new_folder_name, "/",current_pooled_csvs_to_move_emily)
    file.move(current_pooled_csvs_to_move_emily, archive_folder_name)
  }
  
  file.copy(downloaded_files_paths, emily_new_folder_name)
  
} else {
  dir.create(emily_new_folder_name)
  file.copy(downloaded_files_paths, emily_new_folder_name)
}


#move the new downloads into the Paul's folder where you want to save them
file.move(downloaded_files_paths, "/Users/paulcaih/Dropbox/School Surveillance Project - CAIH/16. Data Analysis/School Testing Brief Report/Data/Total Tests and Positive Pools/Pooled Samples")

# ------------------------------------------------------------------------------------------------------

#### Download Binax Test Data ####
for(i in 1:length(school_ids)){
  pool_download_url <- paste0("https://testcenter.concentricbyginkgo.com/", school_ids[i], "/champion/test-information.csv?sort_by=created_at&sort_direction=desc&page=1")
  remDr$navigate(pool_download_url)
}
Sys.sleep(10)
#### Move Binax Test Data ####
#get the file names for the binax files that were just downloaded
downloaded_binax_files <- list.files("/Users/paulcaih/Downloads/")
downloaded_binax_files <- downloaded_binax_files[downloaded_binax_files %notin% current_downloads]
#concat the directory with the file names
downloaded_binax_files_paths <- paste0("/Users/paulcaih/Downloads/", downloaded_binax_files)

#only select files that have some data
downloaded_binax_data <- lapply(downloaded_binax_files_paths, read.csv) #read each csv
binax_files_to_keep <- sapply(downloaded_binax_data, nrow) > 0 #create a string of logicals for if each csv has at least 1 row of data
downloaded_binax_files_paths <- downloaded_binax_files_paths[binax_files_to_keep]

## Prep Paul's destination folder

#find the list of downloaded binax data in the folder that you want to replace
current_binax_downloads <- list.files("/Users/paulcaih/Dropbox/School Surveillance Project - CAIH/16. Data Analysis/School Testing Brief Report/Data/BinaxNow Test Data")
current_binax_downloads <- current_binax_downloads[!grepl("ARCHIVE", current_binax_downloads)]

#if there are any binax files in the current folder, move them to an archive folder
if(length(current_binax_downloads) > 0){
  #find the date of those downloads
  current_binax_downloads_date <- str_extract(current_binax_downloads[1], "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]")
  
  #concat the path with the names of the current downloads
  current_binax_downloads <- paste0("/Users/paulcaih/Dropbox/School Surveillance Project - CAIH/16. Data Analysis/School Testing Brief Report/Data/BinaxNow Test Data/", current_binax_downloads)
  
  #create a new folder in the archive for the previous pooled downloads and move them to that folder
  dir.create(paste0("/Users/paulcaih/Dropbox/School Surveillance Project - CAIH/16. Data Analysis/School Testing Brief Report/Data/BinaxNow Test Data/ARCHIVE/", current_binax_downloads_date))
  file.move(current_binax_downloads, paste0("/Users/paulcaih/Dropbox/School Surveillance Project - CAIH/16. Data Analysis/School Testing Brief Report/Data/BinaxNow Test Data/ARCHIVE/", current_binax_downloads_date), overwrite = TRUE)
}

#create folders for Emily in Ondedrive
#check if the folder (named after the date) currently exists. This will allow us to run the script more than once a day
emily_new_folder_name <- paste0("/Users/paulcaih/OneDrive - Johns Hopkins/My files/Project SafeSchools - Implementation/18. Testing Data Downloads/Antigen/", format(Sys.Date(), "%b_%d_%y"))
emily_folder_already_exists <- dir.exists(emily_new_folder_name)

if(emily_folder_already_exists){
  #if it exists, create a new folder in the ARCHIVE with the date and time and move the files in that folder to the new folder.
  archive_folder_name <- paste0("/Users/paulcaih/OneDrive - Johns Hopkins/My files/Project SafeSchools - Implementation/18. Testing Data Downloads/Antigen/0. Archive/", format(Sys.Date(), "%b_%d_%y"))
  
  #if the archive folder name already exists, then add a number to the end of the name to create an additional folder in the archive
  file_num <- 0
  while(file.exists(archive_folder_name)){
    file_num <- file_num + 1
    archive_folder_name <- paste0("/Users/paulcaih/OneDrive - Johns Hopkins/My files/Project SafeSchools - Implementation/18. Testing Data Downloads/Antigen/0. Archive/", format(Sys.Date(), "%b_%d_%y"), " ", file_num)
  }
  
  dir.create(archive_folder_name)
  
  #if there are any files in the folder where we want to move the new files, move them to the archive folder
  current_pooled_csvs_to_move_emily <- list.files(emily_new_folder_name)
  if(length(current_pooled_csvs_to_move_emily) > 0 ){
    current_pooled_csvs_to_move_emily <- paste0(emily_new_folder_name, "/",current_pooled_csvs_to_move_emily)
    file.move(current_pooled_csvs_to_move_emily, archive_folder_name)
  }
  
  #move the newly downloaded
  file.copy(downloaded_binax_files_paths, emily_new_folder_name)
  
} else {
  dir.create(emily_new_folder_name)
  file.copy(downloaded_binax_files_paths, emily_new_folder_name)
}




#move the new downloades into the folder where you want to save them
file.move(downloaded_binax_files_paths, "/Users/paulcaih/Dropbox/School Surveillance Project - CAIH/16. Data Analysis/School Testing Brief Report/Data/BinaxNow Test Data")

#close session at end
remDr$close()
rD$server$stop()

#set wd back to current wd
setwd(currentwd)
