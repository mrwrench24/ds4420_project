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

# for house118, we get MSE: 0.276 Accuracy: 0.73
# for senate118, we get MSE: 0.227 Accuracy: 0.83
# this obviously varies because we are doing true random but ranges between 
# 70-85% for accuracy and around 0.2-0.35 for loss

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
      8
    )
  }
  
  mse <- mean((preds - random_votes)^2)
  accuracy <- mean(round(preds) == random_votes)
  
  return(c(mse, accuracy))
}

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

# this function build a combined matrix for multiple congresses for one chamber
# we dont support combining house and senate chamber since the members will be different
# parameters:
# - congresses: a list of numbers (as strings) for congresses 
# - chamber: the chamber code "H" for house and "S" for senate
combine_congress_matrices <- function(congresses, chamber) {
  if (!(chamber %in% c("H", "S"))) {
    stop("use S for senate and H for house")
  }
  matrices <- list()
  
  # put all of the individual matrices into a bigger one with each index in a bigger list
  for (i in seq_along(congresses)) {
    curr <- congresses[i]
    mat <- build_matrix_for_chamber(curr, chamber)
    colnames(mat) <- paste0(curr, "_", colnames(mat))
    matrices[[i]] <- mat
  }
  
  all_rows <- rownames(matrices[[1]])
  all_cols <- colnames(matrices[[1]])
  
  # if more than 1 matrix exists, we need to combine them with unique columns 
  # and rows (to account for some voters being in multiple congresses)
  if (length(matrices) > 1) {
    for (i in 2:length(matrices)) {
      all_rows <- union(all_rows, rownames(matrices[[i]]))
      all_cols <- union(all_cols, colnames(matrices[[i]]))
    }
  }
  
  # expans each individual matrix from congresses to include all rows and cols
  expanded_mats <- list()
  for (i in seq_along(matrices)) {
    expanded_mats[[i]] <- expand_matrix(matrices[[i]], all_rows, all_cols)
  }
  
  # make the combined matrix
  # seq_along is like using range in python but for the length of all rows
  combined <- expanded_mats[[1]]
  
  # only expand combined if more than 1 matrix exists
  if (length(expanded_mats) > 1) {
    for (k in 2:length(expanded_mats)) {
      # find the rows
      for (i in seq_along(all_rows)) {
        # find the columns
        for (j in seq_along(all_cols)) {
          # if the row/col exists in one matrix, we add it
          # we won't have any more than one matrix that has a vote for (row, col) since the bill names are now split by congress
          if (!is.na(expanded_mats[[k]][i, j])) {
            combined[i, j] <- expanded_mats[[k]][i, j]
          }
        }
      }
    }
  }
  
  return (combined)
}

# will predict the vote for the user based on multiple congresses
# parameters:
# - target_user (string): the icpsr ID of the user we are trying to predict the vote from
# - target_bill (string): the bill rollnumber of the legislation we are trying to predict the vote for
# - target_congress (number): the congress # we are looking at legislations from
# - chamber (string): the chamber we are looking at. "H" for house, "S" for senate
# - congresses (list of numbers): the congresses we are looking at for the bill
combined_user_cf <- function(
    target_user,
    target_bill,
    target_congress,
    chamber,
    congresses,
    similarity = "cosine",
    top_k = 8
) {
  if (!(chamber %in% c("H", "S"))) {
    stop("use S for senate and H for house")
  }
  if (!(target_congress %in% congresses)) {
    stop("the target congress must be included in the congresses list")
  }
  
  if (length(congresses >= 2)) {
    # use the combined matrix from all the congresses
    combined_matrix <- combine_congress_matrices(congresses, chamber)
    
    # find the bill id based on how it's represented in the combine matrix
    full_bill_id <- paste0(target_congress, "_", target_bill)
  } else {
    congress <- congresses[1] # there is only one congress, so we get the first one
    combined_matrix <- build_matrix_for_chamber(congress ,chamber)
    full_bill_id <- target_bill # the bill id doesn't change when we only have one congress
  }
  
  # find the prediction
  result <- user_collab_filter(combined_matrix, target_user, full_bill_id,
                               similarity, top_k)
  
  return(result)
}

