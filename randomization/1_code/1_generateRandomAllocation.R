# Randomized allocation assignments for stage 1 non-responders randomized to 
# a stage 2 intervention
# Author: Nikki Freeman
# Date created: 18 December 2023
# Last modified: 18 December 2023
# Parent directory is ChargeUp
# Protocol for allocation sequence generation: 
# ADA Pathway/Documents/General/Data Collection/Randomization allocation/Randomization allocation procedure.docx

# Load libraries ---------------------------------------------------------------
library(tidyverse)
library(blockrand)

# Load the seeds ---------------------------------------------------------------
seeds <- read_csv("./randomization/0_resources/seed_demo.csv") # Read in the seeds from a file (dev, pilot, prod)

# Set the parameters -----------------------------------------------------------
# Sample size
n_target <- 200 # Targeted enrollment
n_cushion <- 50 # Extra allocations in case we enroll more than we anticipated
n <- n_target + n_cushion # Total number of allocations
# Block sizes 
blockSizes <- c(2, 4, 6)/2 # Divide by two because the function multiplies by 2 
# Levels of treatments to be randomized
trtLevels <- c("ReCharge^", "TakeCharge^") 

# Generate the random allocation -----------------------------------------------
for(i in 1:nrow(seeds)){
  # Set the seed
  set.seed(seeds$seed[i])
  
  # Generate the block randomization for the targeted enrollment
  allocations_target <- blockrand::blockrand(n = n_target, num.levels = 2, 
                                             levels = trtLevels, 
                                             block.sizes = blockSizes)
  
  # Generate the block randomization for the extra allocations (if we overshoot target enrollment)
  allocations_cushion <- blockrand::blockrand(n = n_cushion, num.levels = 2, 
                                              levels = trtLevels, 
                                              block.sizes = blockSizes)
  
  allocations_cushion <- allocations_cushion %>% mutate(id = id + n_target)
  
  # Combine the two allocation dataframes into one 
  allocations <- bind_rows(allocations_target, allocations_cushion)
  
  # Save the allocations ----------------------------------------------------------
  outdir <- "./randomization/2_pipeline/"
  outfile <- paste0("1_randomAllocation_", seeds$file[i], ".csv")
  write_csv(allocations, paste0(outdir, outfile))
}


