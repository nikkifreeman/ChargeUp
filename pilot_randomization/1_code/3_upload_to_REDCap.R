# Load packages
library(jsonlite)

# Import today's CSV created by 2_ChargeUp_Pilot_randomization.R
incsv <- format(Sys.time(), 'ChargeUp_Pilot_randomized_%Y%m%d.csv')
redcap_r1csv <- read.csv(incsv, header = TRUE, stringsAsFactors = FALSE)

# Convert to JSON (not strictlly required but seems easier than API upload of CSV records)
redcap_r1json <- toJSON(redcap_r1csv)

# Upload randomization data into redcap
token <- Sys.getenv("rcapiChargeUpPilot")
url <- "https://rc2.redcap.unc.edu/api/"
formData <- list(
    'token' = token,
    'content' = 'record',
    'format' = 'json',
    'data' = redcap_r1json,
    'return_content' = 'ids'
)
response <- httr::POST(url, body = formData, encode = "form")
result <- httr::content(response)
print(result)
