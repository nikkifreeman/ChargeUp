allocate_treatments <- function(enrolled_data, weights = c(1/3, 1/3, 1/3)){
  # Reproducibility
  # Marc, if this is just straight up whack, feel free to edit!
  seed <- sample(1:9999, size = 1) # Generate a 4 digit number to be the seed
  set.seed(seed) # set the seed
  enrolled_data$seed[enrolled_data$trt == "none"] <- seed # assign the seed to the participant
  
  
  # Check to see if there are participants that need a treatment assignment
  if(sum(enrolled_data$trt == "none") == 0){
    return(enrolled_data)
  }
  
  # Check if this is the first participant, if the first participant then assign treatment
  if(enrolled_data$trt[enrolled_data$num == 1] == "none"){
    if(enrolled_data$avail_tuesday[enrolled_data$num == 1] == "yes" & enrolled_data$avail_thursday[enrolled_data$num == 1] == "no"){
      enrolled_data$trt[enrolled_data$num == 1] <- "tuesday"
    } else if(enrolled_data$avail_tuesday[enrolled_data$num == 1] == "no" & enrolled_data$avail_thursday[enrolled_data$num == 1] == "yes"){
      enrolled_data$trt[enrolled_data$num == 1] <- "thursday"
    } else {
      enrolled_data$trt[enrolled_data$num == 1] <- sample(c("tuesday", "thursday"), 1, prob = c(0.5, 0.5))
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
    if(enrolled_data$avail_tuesday[enrolled_data$num == i] == "yes" & enrolled_data$avail_thursday[enrolled_data$num == i] == "no"){
      enrolled_data$trt[enrolled_data$num == i] <- "tuesday"
    } else if(enrolled_data$avail_tuesday[enrolled_data$num == i] == "no" & enrolled_data$avail_thursday[enrolled_data$num == i] == "yes"){
      enrolled_data$trt[enrolled_data$num == i] <- "thursday"
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
  sub_tuesday <- sub[sub$trt == "tuesday", ]
  similar_tuesday <- c(sum(sub_tuesday$age == enrolled_data$age[enrolled_data$num == i]), 
                       sum(sub_tuesday$gender == enrolled_data$gender[enrolled_data$num == i]), 
                       sum(sub_tuesday$race == enrolled_data$race[enrolled_data$num == i]))
  sub_thursday <- sub[sub$trt == "thursday", ]
  similar_thursday <- c(sum(sub_thursday$age == enrolled_data$age[enrolled_data$num == i]), 
                        sum(sub_thursday$gender == enrolled_data$gender[enrolled_data$num == i]), 
                        sum(sub_thursday$race == enrolled_data$race[enrolled_data$num == i]))
  
  # Calculate the differences between the participants in each treatment group
  D_tuesday <- (similar_tuesday + 1) - (similar_thursday )
  D_thursday <- (similar_thursday + 1) - (similar_tuesday )
  
  # Calculate the weighted sum of the squared differences
  sigma2_tuesday <- sum(weights*(D_tuesday^2))
  sigma2_thursday <- sum(weights*(D_thursday^2))
  
  # Allocate treatment
  if(sigma2_tuesday < sigma2_thursday){
    enrolled_data$trt[enrolled_data$num == i] <- "tuesday"
  } else if(sigma2_tuesday > sigma2_thursday){
    enrolled_data$trt[enrolled_data$num == i] <- "thursday"
  } else {
    enrolled_data$trt[enrolled_data$num == i] <- sample(c("tuesday", "thursday"), 1)
  }
}


convertFromDayToTrtName <- function(enrolled_data, tuesday_is_ReCharge = TRUE){
  if(tuesday_is_ReCharge == TRUE){
    enrolled_data$trt[enrolled_data$trt == "tuesday"] <- "ReCharge"
    enrolled_data$trt[enrolled_data$trt == "thursday"] <- "TakeCharge"
  } else if(tuesday_is_ReCharge == FALSE){
    enrolled_data$trt[enrolled_data$trt == "tuesday"] <- "TakeCharge"
    enrolled_data$trt[enrolled_data$trt == "thursday"] <- "ReCharge"
  }
  return(enrolled_data)
}
