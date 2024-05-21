allocate_treatments <- function(enrolled_data, weights = c(1/3, 1/3, 1/3)){
  # Reproducibility
  # Every participant will have a different seed. The seeds are (record_id*5 + 3)
  enrolled_data$record_id <- as.numeric(enrolled_data$record_id)
  enrolled_data <- enrolled_data %>% mutate(seed = record_id*5 + 3)
  
  
  # Check to see if there are participants that need a treatment assignment
  if(sum(enrolled_data$trt == "none") == 0){
    return(enrolled_data)
  }
  
  # Check if this is the first participant, if the first participant then assign treatment
  if(enrolled_data$trt[enrolled_data$num == 1] == "none"){
    set.seed(enrolled_data$seed[enrolled_data$num == 1]) # Set the seed for reproducibility
    if(enrolled_data$avail_monday[enrolled_data$num == 1] == "yes" & enrolled_data$avail_wednesday[enrolled_data$num == 1] == "no"){
      enrolled_data$trt[enrolled_data$num == 1] <- "monday"
    } else if(enrolled_data$avail_monday[enrolled_data$num == 1] == "no" & enrolled_data$avail_wednesday[enrolled_data$num == 1] == "yes"){
      enrolled_data$trt[enrolled_data$num == 1] <- "wednesday"
    } else {
      enrolled_data$trt[enrolled_data$num == 1] <- sample(c("monday", "wednesday"), 1, prob = c(0.5, 0.5))
    }
  }
  
  # Check to see if there are any participants left that need a treatment assignment
  if(sum(enrolled_data$trt == "none") == 0){
    return(enrolled_data)
  } else {
    nums_need_treat <- enrolled_data$num[enrolled_data$trt == "none"]
    nums_need_treat <- sort(nums_need_treat)
  }
  
  # Assign treatment to the remaining participant(s)
  for(i in nums_need_treat){
    set.seed(enrolled_data$seed[enrolled_data$num == i])
    if(enrolled_data$avail_monday[enrolled_data$num == i] == "yes" & enrolled_data$avail_wednesday[enrolled_data$num == i] == "no"){
      enrolled_data$trt[enrolled_data$num == i] <- "monday"
    } else if(enrolled_data$avail_monday[enrolled_data$num == i] == "no" & enrolled_data$avail_wednesday[enrolled_data$num == i] == "yes"){
      enrolled_data$trt[enrolled_data$num == i] <- "wednesday"
    } else {
      enrolled_data$trt[enrolled_data$num == i] <- getTrt_minimization(enrolled_data, i, weights)
    }
  }
  return(enrolled_data)
}


getTrt_minimization <- function(enrolled_data, i, weights){
  # Get a subset of the data up to the ith participant
  sub <- enrolled_data[enrolled_data$num < i, ]
  
  # Calculate the number of participants with features like the ith participant in each of the treatment groups 
  sub_monday <- sub[sub$trt == "monday", ]
  similar_monday <- c(sum(sub_monday$age == enrolled_data$age[enrolled_data$num == i]), 
                       sum(sub_monday$gender == enrolled_data$gender[enrolled_data$num == i]), 
                       sum(sub_monday$race == enrolled_data$race[enrolled_data$num == i]))
  sub_wednesday <- sub[sub$trt == "wednesday", ]
  similar_wednesday <- c(sum(sub_wednesday$age == enrolled_data$age[enrolled_data$num == i]), 
                        sum(sub_wednesday$gender == enrolled_data$gender[enrolled_data$num == i]), 
                        sum(sub_wednesday$race == enrolled_data$race[enrolled_data$num == i]))
  
  # Calculate the differences between the participants in each treatment group
  D_monday <- (similar_monday + 1) - (similar_wednesday )
  D_wednesday <- (similar_wednesday + 1) - (similar_monday )
  
  # Calculate the weighted sum of the squared differences
  sigma2_monday <- sum(weights*(D_monday^2))
  sigma2_wednesday <- sum(weights*(D_wednesday^2))
  
  # Allocate treatment
  if(sigma2_monday < sigma2_wednesday){
    enrolled_data$trt[enrolled_data$num == i] <- "monday"
  } else if(sigma2_monday > sigma2_wednesday){
    enrolled_data$trt[enrolled_data$num == i] <- "wednesday"
  } else {
    enrolled_data$trt[enrolled_data$num == i] <- sample(c("monday", "wednesday"), 1)
  }
}


convertFromDayToTrtName <- function(enrolled_data, monday_is_ReCharge = TRUE){
  if(monday_is_ReCharge == TRUE){
    enrolled_data$trt[enrolled_data$trt == "monday"] <- "ReCharge"
    enrolled_data$trt[enrolled_data$trt == "wednesday"] <- "TakeCharge"
  } else if(monday_is_ReCharge == FALSE){
    enrolled_data$trt[enrolled_data$trt == "monday"] <- "TakeCharge"
    enrolled_data$trt[enrolled_data$trt == "wednesday"] <- "ReCharge"
  }
  return(enrolled_data)
}
