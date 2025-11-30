# using source, we can import functions from other files
source("./collaborative_filtering.R")
source("../preprocessing/cf_preprocessing.R")

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

# combining multiple chambers (using 119 and 118 as my example)
house_118  <- build_matrix_for_chamber(118, "H")
house_119 <- build_matrix_for_chamber(119, "H")

all_rows <- union(rownames(house_118), rownames(house_119))
all_cols <- union(colnames(house_118), colnames(house_119))

# expands a matrix to have all of the rows and the columns passed in as params
# and fills in values for rows and columns that it has
expand_matrix <- function(mat, all_rows, all_cols) {
  # initialize the matrix with NA because that's what we express no vote as
  new_mat <- matrix(NA, nrow = length(all_rows), ncol = length(all_cols),
                    dimnames = list(all_rows, all_cols))
  # add the existing values
  common_rows <- intersect(rownames(mat), all_rows)
  common_cols <- intersect(colnames(mat), all_cols)
  new_mat[common_rows, common_cols] <- mat[common_rows, common_cols]
  return(new_mat)
}

house_118_mat <- expand_matrix(house_118, all_rows, all_cols)
house_119_mat <- expand_matrix(house_119, all_rows, all_cols)

# make the combined matrix
# seq_along is like using range in python but for the length of all rows
combined <- mat1_exp
# find the rows
for (i in seq_along(all_rows)) {
  # iterate through the columns
  for (j in seq_along(all_cols)) {
    # either they voted on the bill in house 118 or house 119, because bill columns should be different
    if (!is.na(house_118_mat[i, j])) {
      combined[i, j] <- house_118_mat[i, j]
    }
    if (!is.na(house_119_mat[i, j])) {
      combined[i, j] <- mat2_exp[i, j]
    }
  }
}
