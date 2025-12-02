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
  
  # pick random indices using sample
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
    target_rollnumber <- colnames(votes_matrix)[picked_votes[i, 2]]
    # printing index because I wasn't sure how long the for loop would take
    print(i)
    
    preds[i] <- user_collab_filter(
      masked_matrix, 
      target_user, 
      target_rollnumber, 
      'cosine', 
      top_k
    )
  }
  
  mse <- mean((preds - random_votes)^2)
  accuracy <- mean(round(preds) == random_votes)
  
  return(c(mse, accuracy))
}

# produce accuracy and MSE metrics for predicted votes for a voting matrix based
# on a random rollnumber for every user
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
    target_rollnumber <- colnames(votes_matrix)[cols[i]] # the target rollnumber
    
    preds[i] <- user_collab_filter(
      masked_matrix,
      target_user,
      target_rollnumber,
      "cosine",
      top_k
    )
  }
  
  # see how good the predictionsare
  mse <- mean((preds - random_votes)^2)
  accuracy <- mean(round(preds) == random_votes)
  
  return(c(mse, accuracy))
}

# metric results from every voter (at least one rollnumber):
# - house118: 0.219 MSE and 0.767 accuracy
# - senate118: 331 MSE 0.770 accuracy

# example use:
senate_118 <- build_matrix_for_chamber(118, "S")
house_119  <- build_matrix_for_chamber(119, "H")
test_every_voter(senate_118)
test_metrics(house_119)

# helper for the prediction to see if a vote matches up
is_correct <- function(pred, actual) {
  if (is.na(pred) || is.na(actual)) return(NA)
  if (pred < 0 && actual == -1) return(TRUE)
  if (pred > 0 && actual == 1) return(TRUE)
  return(FALSE)
}

# output a table with results for different k values for congresses
test_predictions <- function(congresses,
                             chamber,
                             mat_dir = "../collaborative_filtering/matrices",
                             output_dir = "../collaborative_filtering/results") {
  if (!(chamber %in% c("H", "S"))) stop("use 'H' for house or 'S' for senate")
  
  # choose ks depending on chamber
  # we chose these values based on our test results, but they may not be optimal
  if (chamber == "S") {
    ks <- c(5, 8, 10, 15)
  } else {
    ks <- c(8, 15, 20)
  }
  
  # using seed to have a reproducable random
  set.seed(42)
  
  results_list <- list()
  
  # build column names for solo eval and combined eval
  per_congress_colnames <- c()
  for (k in ks) {
    per_congress_colnames <- c(per_congress_colnames, paste0("pred_solo_k", k))
  }
  combined_colnames <- paste0("pred_combined_k", ks)
  
  # sample 50 rows per conggress
  sampled_entries <- list()
  
  # first for loop does individual evaluation
  for (c in congresses) {
    mat <- build_matrix_for_chamber(c, chamber)
    
    # find the row and columns indices for valid cells
    valid_cells <- which(!is.na(mat), arr.ind = TRUE)
    if (nrow(valid_cells) < 50) {
      stop(paste("Not enough non-NA votes in congress", c, "to sample 50"))
    }
    
    picked_cols <- valid_cells[sample(nrow(valid_cells), 50, replace = FALSE), ]
    df <- data.frame(icpsr = rownames(mat)[picked_cols[, 1]],
                     rollnumber = colnames(mat)[picked_cols[, 2]],
                     congress = as.character(c),
                     actual = mat[picked_cols])
    
    sampled_entries[[as.character(c)]] <- df
  }
  
  # combine all sampled rows together into targets
  targets <- sampled_entries[[1]]
  for (i in 2:length(sampled_entries)) {
    targets <- rbind(targets, sampled_entries[[i]])
  }
  
  rownames(targets) <- NULL
  
  # initialize prediction columns for the table
  for (col in per_congress_colnames) {
    targets[[col]] <- NA
  }
  
  for (col in combined_colnames) {
    targets[[col]] <- NA
  }
  
  # find the prediction for each congress and save it to respective solo column
  for (c in congresses) {
    congress <- as.character(c)
    idxs <- which(targets$congress == congress)
    votes_mat <- build_matrix_for_chamber(c, chamber)
    masked_mat <- votes_mat
    
    # find the user and item that the matrix should be NA for (to predict)
    for (i in idxs) {
      user <- targets$icpsr[i]
      item <- targets$rollnumber[i]
      masked_mat[user, item] <- NA
    }
    
    for (k in ks) {
      colname <- paste0("pred_solo_k", k)
      
      for (i in idxs) {
        user <- targets$icpsr[i]
        roll <- targets$rollnumber[i]
        # we could change this to use L2 but they gave pretty similar answers
        pred <- user_collab_filter(masked_mat, user, roll, "cosine", k)
        targets[[colname]][i] <- pred
      }
    }
  }
  
  # second part does combined congress evaluation
  combined_mat <- combine_congress_matrices(congresses, chamber)
  
  # combined predictions
  for (i in seq_len(nrow(targets))) {
    user <- targets$icpsr[i]
    roll <- targets$rollnumber[i]
    congress <- targets$congress[i]
    combined_col <- paste0(congress, "_", roll)
    
    # mask to-pred votes in the combined matrix
    masked_combined <- combined_mat
    masked_combined[user, combined_col] <- NA
    
    for (k in ks) {
      pred <- user_collab_filter(masked_combined, user, combined_col, "cosine", k)
      targets[[paste0("pred_combined_k", k)]][i] <- pred
    }
  }
  
  # find if the values are correct
  targets$correct_pred_single <- NA
  targets$correct_pred_combined <- NA
  
  # for every target prediction, fidn if the solo and the combined are true
  # at least one correct prediction would make it true
  for (i in seq_len(nrow(targets))) {
    actual <- targets$actual[i]
    congress <- targets$congress[i]
    
    # solo prediction values
    single_preds <- rep(NA, length(ks))
    for (j in seq_along(ks)) {
      k <- ks[j]
      single_preds[j] <- targets[[paste0("pred_solo_k", k)]][i]
    }
    
    # combined prediction values
    combined_preds <- rep(NA, length(ks))
    for (j in seq_along(ks)) {
      k <- ks[j]
      combined_preds[j] <- targets[[paste0("pred_combined_k", k)]][i]
    }
    
    # check solo prediction 
    # ideally we shouldn't get any NA predictons, but adding this just in case that does happen
    if (all(is.na(single_preds))) {
      targets$correct_pred_single[i] <- NA
    } else {
      correct_flags <- c()
      
      for (j in seq_along(single_preds)) {
        p <- single_preds[j]
        if (!is.na(p)) {
          correct_flags[j] <- is_correct(p, actual)
        } else {
          correct_flags[j] <- NA
        }
      }
      
      # checks to see if at least one of the values is true
      targets$correct_pred_single[i] <- any(correct_flags)
    }
    
    # check for combined values. same process as above
    if (all(is.na(combined_preds))) {
      targets$correct_pred_combined[i] <- NA
    } else {
      correct_flags <- c()
      
      for (j in seq_along(combined_preds)) {
        p <- combined_preds[j]
        if (!is.na(p)) {
          correct_flags[j] <- is_correct(p, actual)
        } else {
          correct_flags[j] <- NA
        }
      }
      
      targets$correct_pred_combined[i] <- any(correct_flags)
    }
  }
  
  # output columns should have user, rollnumber, congress#, 
  output <- c(
    "icpsr", "rollnumber", "congress",
    per_congress_colnames,
    combined_colnames,
    "correct_pred_single",
    "correct_pred_combined"
  )
  
  out_df <- targets[, output]
  
  output_file <- file.path(output_dir, paste0(chamber, "_test_predictions.csv"))
  write.csv(out_df, file = output_file, row.names = FALSE)
}

