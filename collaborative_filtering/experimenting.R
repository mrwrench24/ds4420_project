# using source, we can import functions from other files
source("./collaborative_filtering.R")
source("../preprocessing/cf_preprocessing.R")

# idea:
# - randomly generate 100 points user/item combinations
# - remove them from the matrix + another 100 random points
# - try to predict the initially eliminated points
# - calculate accuracy and loss

# for house119, we get MSE: 0.187 Accuracy: 0.89
# for senate118, we get MSE: 0.227 Accuracy: 0.83
# this obviously varies because we are doing true random but ranges between 
# 70-85% for accuracy and around 0.2-0.35 for loss

# produce accuracy and MSE metrics for predicted votes for a voting matrix based on a random number of samples
# parameters
# - votes_matrix: the user-item matrix we are using to mask and predict from
# - num_samples: the number of samples we want to predict and get metrics from
# - top_k: the number of top users we want to compare the user with
test_metrics <- function(votes_matrix, num_samples = 100, top_k = 10) {
  # don't want to include NA votes in 100 sumples
  # which function returns positions of elements and we want it in an array
  valid_cells <- which(!is.na(votes_matrix), arr.ind = TRUE)
  
  # ***********************
  # check if using sample is okay
  # **********************
  picked_indices <- sample(nrow(valid_cells), num_samples, replace = FALSE)
  picked_votes <- valid_cells[picked_indices, ]
  
  rows <- picked_votes[,1]
  cols <- picked_votes[,2]
  random_votes <- votes_matrix[cbind(rows, cols)]
  
  print(data.frame(row = rows, col = cols, value = random_votes))
  
  # remove the votes from the original matrix
  remaining_cells <- valid_cells[-picked_indices, ]
  remove_indices <- sample(nrow(remaining_cells), num_samples, replace = FALSE)
  remove_votes <- remaining_cells[remove_indices, ]
  
  # copy of the matrix to remove the votes
  masked_matrix <- votes_matrix
  masked_matrix[cbind(picked_votes[,1], picked_votes[,2])] <- NA
  masked_matrix[cbind(remove_votes[,1], remove_votes[,2])] <- NA
  
  preds <- numeric(num_samples)
  
  for (i in 1:num_samples) {
    target_user <- rownames(votes_matrix)[picked_votes[i, 1]]
    target_bill <- colnames(votes_matrix)[picked_votes[i, 2]]
    # printing index because I wasn't sure how long the for loop would take
    print(i)
    
    preds[i] <- user_collab_filter(
      masked_matrix, 
      target_user, 
      target_bill, 
      'cosine', 
      top_k
    )
  }
  
  mse <- mean((preds - random_votes)^2)
  accuracy <- mean(round(preds) == random_votes)
  
  return(c(mse, accuracy))
}

# produce accuracy and MSE metrics for predicted votes for a voting matrix based
# on a random bill for every user
# parameters
# - votes_matrix: the user-item matrix we are using to mask and predict from
# - top_k: the number of top users we want to compare the user with
test_every_voter <- function(votes_matrix, top_k = 10) {
  n_rows <- nrow(votes_matrix)
  
  # pick a non-NA vote for every user
  rows <- numeric()
  cols <- numeric()
  
  for (r in 1:n_rows) {
    valid_cols <- which(!is.na(votes_matrix[r, ]))
    picked_cols <- valid_cols[sample(length(valid_cols), 1)]
    # add each row and new column choices to the rows and cols list
    rows <- c(rows, r)
    cols <- c(cols, picked_cols)
  }
  
  # pick random votes from the combination
  random_votes <- votes_matrix[cbind(rows, cols)]
  print(data.frame(row = rows, col = cols, value = random_votes))
  
  # copy of the matrix to remove the votes
  masked_matrix <- votes_matrix
  masked_matrix[cbind(rows, cols)] <- NA
  
  # predictions
  preds <- numeric(length(rows))
  for (i in seq_along(rows)) {
    target_user <- rownames(votes_matrix)[rows[i]] # the target icpsr
    target_bill <- colnames(votes_matrix)[cols[i]] # the target rollnumber
    
    preds[i] <- user_collab_filter(
      masked_matrix,
      target_user,
      target_bill,
      "cosine",
      top_k
    )
  }
  
  # see how good the predictionsare
  mse <- mean((preds - random_votes)^2)
  accuracy <- mean(round(preds) == random_votes)
  
  return(c(mse, accuracy))
}

# metric results from every voter (at least one bill):
# - house118: 0.219 MSE and 0.767 accuracy
# - senate118: 331 MSE 0.770 accuracy

# example use:
senate_118 <- build_matrix_for_chamber(118, "S")
house_119  <- build_matrix_for_chamber(119, "H")
test_every_voter(senate_118)
test_metrics(house_119)
