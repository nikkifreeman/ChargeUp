##############################
# title: "ChargeUp Pilot Randomization"
# author: "Nikki Freeman and Marc Peterson"
# date: "28 March 2024"
# output:
#   html_document:
#     df_print: paged
##############################

# Load packages
library(tidyverse)

# Load functions
source("pilot_randomization_fnxs.R")

# Import today's CSV created by 1_ChargeUp_Pilot_data_prep.py
incsv <- format(Sys.time(), 'ChargeUp_Pilot_to_randomize_%Y%m%d.csv')
enrolled_pilot_to_randomize <- read.csv(incsv, header = TRUE, stringsAsFactors = FALSE)
enrolled_pilot_to_randomize[is.na(enrolled_pilot_to_randomize)] <- ""


# Excecute the treatment allocation code
enrolled_pilot_randomized <- allocate_treatments(enrolled_pilot_to_randomize, weights = c(1/3, 1/3, 1/3))

enrolled_pilot_randomized %>%
  mutate(randomization_r1date = replace(randomization_r1date, randomization_r1date == "", format(Sys.time(), '%Y-%m-%d'))) %>%
  mutate(randomization_r1date = replace_na(randomization_r1date, format(Sys.time(), '%Y-%m-%d'))) -> enrolled_pilot_randomized


# Write CSV to be loaded into REDCap
# Note: in REDCap, 1=ReCharge and 2=TakeCharge.
#       and per Angela 2024-07-15, "Monday = TakeCharge, Wednesday = ReCharge"
enrolled_pilot_randomized %>%
  filter(randomization_r1date == format(Sys.time(), '%Y-%m-%d')) %>%
  select(record_id, seed, trt, randomization_r1date) %>%
  mutate(randomization_r1 = case_when(trt == "monday" ~ 2,
                                      trt == "wednesday" ~ 1
  )
  , .after = "record_id") %>%
  rename(randomization_r1seed = seed) %>%
  mutate(randomization_r1date = replace(randomization_r1date, randomization_r1date == "", format(Sys.time(), '%Y-%m-%d'))) %>%
  #  add_column(randomization_r1date = format(Sys.time(), '%Y-%m-%d')) %>%
  #  add_column(randomization_r1_complete = 2) %>%
  select(-trt) -> redcap_r1

csvredcap <- format(Sys.time(), 'ChargeUp_Pilot_randomized_%Y%m%d.csv')
write.csv(redcap_r1, csvredcap, row.names=FALSE)


print("dates of randomization")
enrolled_pilot_randomized %>% group_by(randomization_r1date) %>% count()

# Are the treatment arms balanced?
print("Are the treatment arms balanced?")
enrolled_pilot_randomized %>% group_by(trt) %>% count()

# Are the balancing covariates balanced?
print("Are the covariates balanced?")
enrolled_pilot_randomized %>% group_by(trt) %>%
  count(age) %>%
  pivot_wider(names_from = trt, values_from = n) 

enrolled_pilot_randomized %>% group_by(trt) %>%
  count(gender) %>%
  pivot_wider(names_from = trt, values_from = n)

enrolled_pilot_randomized %>% group_by(trt) %>%
  count(race) %>%
  pivot_wider(names_from = trt, values_from = n)
