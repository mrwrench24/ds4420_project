# using source, we can import functions from other files
source("./collaborative_filtering.R")

# idea:
# - randomly generate 100 points user/item combinations
# - remove them from the matrix + another 100 random points
# - try to predict the initially eliminated points
# - calculate accuracy and loss

house_votes <- read.csv("H118_cf.csv", row.names = 1, check.names = FALSE)
senate_votes <- read.csv("S118_cf.csv", row.names = 1, check.names = FALSE)

# for house118, we get MSE: 0.2617374 Accuracy: 0.76 
# for senate118, we get MSE: 0.3620201 Accuracy: 0.69

test_metrics <- function(votes_matrix, num_samples = 100) {
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
      200
    )
  }
  
  mse <- mean((preds - random_votes)^2)
  accuracy <- mean(round(preds) == random_votes)
  
  return(c(mse, accuracy))
}
