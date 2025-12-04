source("../preprocessing/cf_preprocessing.R")

# cosine similarity function
cosine_similarity <- function(u1, u2) {
  dot_product <- sum(u1 * u2, na.rm = T)
  u1_magnitude <- sqrt(sum(u1 * u1, na.rm = T))
  u2_magnitude <- sqrt(sum(u2 * u2, na.rm = T))
  
  # avoiding division by 0 
  if (u1_magnitude == 0 || u2_magnitude == 0) {
    return(NA)
  }
  sim <- dot_product / (u1_magnitude * u2_magnitude)
  return (sim)
}

# L2 similarity function (returns negative for distance help)
L2_similarity <- function(u1, u2) {
  dist <- sqrt(sum((u1 - u2)^2, na.rm = T))
  return (-dist)
}

# build the similarity matrix using cosine similarity
# parameters:
# - votes_mat: a matrix of votes with users as legislators and 
# - similarity: a string representing what similarity type is
build_similarity_matrix <- function(votes_mat, similarity) {
  n <- ncol(votes_mat)
  sim <- matrix(0, n, n)
  for (i in 1:n) {
    for (j in i:n) {
      if (similarity == 'cosine') {
        sim_ij <- cosine_similarity(votes_mat[, i], votes_mat[, j])
      } else if (similarity == 'L2') {
        sim_ij <- L2_similarity(votes_mat[, i], votes_mat[, j])
      } else {
        stop("only 'cosine' and 'L2' are accepted for similarity") 
      }
      sim[i, j] <- sim_ij
      sim[j, i] <- sim_ij
    }
  }
  
  # MinMax Scaling the similarity scores
  diag(sim) <- NA
  sim_scaled <- apply(sim, 2, function(x) (x - min(x, na.rm = T))
                      /(max(x, na.rm = T) - min(x, na.rm = T)))
  return (sim_scaled)
}

# does the collaborative filtering to return a prediction for how a user will vote on a bill
# parameters:
# - votes_df: the dataframe of previous votes 
# - target_user: the user (icpsr ID) we are trying to predict the vote for
# - target_rollnumber: the bill (rollnumber) we are trying to predict the user's vote for
# - similarity: the similarity metric
# - k: number for top k similar users
user_collab_filter <- function(votes_df, target_user, target_rollnumber, similarity, k) {
  if (!(target_user %in% rownames(votes_df))) {
    stop('user does not exist or has not voted on enough legislations')
  }
  
  if (!(target_rollnumber %in% colnames(votes_df))) {
    stop("target rollnumber not found in votes matrix")
  }
  
  # remove the current user's vote before building the similarity matrix
  curr_vote <- votes_df[target_user, target_rollnumber]
  votes_df_masked <- votes_df
  votes_df_masked[target_user, target_rollnumber] <- NA
  
  # we need to use the transpose so that users are the columns
  sim_matrix <- build_similarity_matrix(t(votes_df_masked), similarity)
  
  # we set the index of the sim_matrix to be based on the user icpsr IDs
  colnames(sim_matrix) <- rownames(votes_df)
  rownames(sim_matrix) <- rownames(votes_df)
  
  # only account for users who voted on this rollnumber
  bill_votes <- votes_df[, target_rollnumber]
  
  # need to rename the bill columns by user id, otherwise the indexing won't work
  names(bill_votes) <- rownames(votes_df) 
  
  # find users that votes on this bill and remove target_user also 
  valid_users <- which(!is.na(bill_votes))
  valid_user_ids <- rownames(votes_df)[valid_users]
  valid_user_ids <- valid_user_ids[valid_user_ids != target_user]
  
  # similarities for target user
  user_similarities <- sim_matrix[target_user, valid_user_ids]

  # top-k neighbors
  sorted_user_sim <- sort(user_similarities, decreasing = TRUE, na.last = NA)
  
  # if k is too big, we get an index error so this will be a way to use min k
  k <- min(k, length(sorted_user_sim))
  top_k_user_sim <- sorted_user_sim[1:k]
  
  # top-k votes
  bill_votes <- bill_votes[valid_user_ids]
  
  top_k_votes <- bill_votes[names(top_k_user_sim)]

  # weighted prediction (should not have any NA at this point, but just in case we do)
  # checking if the denominator would be 0 and returning NA if so
  div <- sum(abs(top_k_user_sim), na.rm = TRUE)
  if (div == 0) {
    return(NA)
  }
  prediction <- sum(top_k_user_sim * top_k_votes, na.rm = TRUE) / div
  return(prediction)
}

# this function builds on top of user_collab_filter and makes it more generic
# so that by passing in the values and congress and chamber, we pull the data 
# through the function and process the CF automatically for prediction
final_user_cf <- function(congress, chamber, 
                            icpsr, rollnumber, metric = 'cosine', 
                            k = 10, 
                            mat_dir = "../collaborative_filtering/matrices") {
  if (!(chamber %in% c("H", "S"))) {
    stop("use H for house and S for senate for the chamber")
  }
  
  # get the file path by concatenating the string to _cf
  mat <- file.path(
    mat_dir, 
    paste0(chamber, congress, "_cf.csv"))
  
  votes_mat <- read.csv(mat, row.names = 1, check.names = FALSE)
  pred <- user_collab_filter(votes_mat, icpsr, rollnumber, metric, k)
  return(pred)
}

# example
final_user_cf(118, 'H', '14854','118', 'cosine', 25)
final_user_cf(118, 'S', '41301','146', 'cosine', 8)

# example use for user with icpsr id 14854 and rollnumber 118 using specific func
# house_votes <- read.csv("H118_cf.csv", row.names = 1, check.names = FALSE)
# senate_votes <- read.csv("S118_cf.csv", row.names = 1, check.names = FALSE)
# user_collab_filter(house_votes, '14854','118', 'cosine', 200)
# user_collab_filter(senate_votes, '15021','212', 'L2', 20)

# unfortunately, the model is not perfect, and makes some mistakes because
# some voters are unpredictable on certain rollnumbers

# how did Elizabeth Warren (ICPSR 41301) vote on the Fiscal Responsibility Act 
# she voted NO
# user_collab_filter(senate_votes, '41301','146', 'cosine', 8)
# user_collab_filter(senate_votes, '41301','146', 'L2', 8)

# -----------------
# COMBINED SECTION
# ----------------
# add a way to combine matrices from multiple congresses together

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
combine_congress_matrices <- function(congresses, chamber, output_dir = "../collaborative_filtering/matrices") {
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
          # we won't have any more than one matrix that has a vote for (row, col) since the rollnumber names are now split by congress
          if (!is.na(expanded_mats[[k]][i, j])) {
            combined[i, j] <- expanded_mats[[k]][i, j]
          }
        }
      }
    }
  }
  # update with user means
  combined <- replace_with_mean(combined)
  
  # write the combined matrix to a csv for future use
  combined_filename <- file.path(output_dir, paste0(
    chamber,
    paste(congresses, collapse = "_"), # Initially used separate, but that didn't work, so using collapse
    "_cf.csv"
  ))
  
  write.csv(combined, combined_filename, row.names = TRUE)
  
  return (combined)
}

# will predict the vote for the user based on multiple congresses
# if a prediction (output) is < 0, then it is likely a Nay, if > 0, it is a YEA
# parameters:
# - target_user (string): the icpsr ID of the user we are trying to predict the vote from
# - target_chamber_rollnumber (string): the bill rollnumber of the legislation we are trying to predict the vote for
# - target_congress (number): the congress # we are looking at legislations from
# - chamber (string): the chamber we are looking at. "H" for house, "S" for senate
# - congresses (list of numbers): the congresses we are looking at for the rollnumber
# - similarity (string): the similarity metric that we want to use
# - top_k (number): the number of most similar users we want to consider
combined_user_cf <- function(
    target_user,
    target_chamber_rollnumber,
    target_congress,
    chamber,
    congresses,
    similarity = "cosine",
    top_k = 10
) {
  if (!(chamber %in% c("H", "S"))) {
    stop("use S for senate and H for house")
  }
  if (!(target_congress %in% congresses)) {
    stop("the target congress must be included in the congresses list")
  }
  
  if (length(congresses) >= 2) {
    # use the combined matrix from all the congresses
    combined_matrix <- combine_congress_matrices(congresses, chamber)
    
    # find the bill id based on how it's represented in the combine matrix
    chamber_rollnumber_id <- paste0(target_congress, "_", target_chamber_rollnumber)
  } else {
    congress <- congresses[1] # there is only one congress, so we get the first one
    combined_matrix <- build_matrix_for_chamber(congress ,chamber)
    combined_matrix <- replace_with_mean(combined_matrix)
    chamber_rollnumber_id <- target_chamber_rollnumber # the rollnumber id doesn't change when we only have one congress
  }
  
  # find the prediction for the user
  result <- user_collab_filter(combined_matrix, target_user, chamber_rollnumber_id,
                               similarity, top_k)
  
  return(result)
}

# example use for some anecdotal results
# Big Beautiful Bill HR1 in 119 House
# Murkowski (icpsr 40300) - she was a swing YES
final_user_cf(119, 'S', '40300', '372', 'L2', 10)
# Susan Collins (icpsr 49703) - she was a swing NO (it gets this wrong)
final_user_cf(119, 'S', '49703', '372', 'L2', 10)

# Fiscal Responsibility Act / Govt. Shutdown of 2023 - HR3746 for the 118th Congress
# Elizabeth Warren (icpsr 41301) and Matt Gaetz (21719) were both no’s.
final_user_cf(118, 'S', '41301', '146', 'cosine', 8)
final_user_cf(118, 'H', '21719', '242', 'cosine', 10)

# Affordable Care Act - HR3590 for the 111th Congress
# Mitch McConnel Strong NO
final_user_cf(111, 'S', '14921', '396', 'cosine', 8)

# Sen. Ben Nelson - Swing YES
final_user_cf(111, 'S', '40103', '396', 'cosine', 8)

# Sen. Olympia Snowe - Swing NO
final_user_cf(111, 'S', '14661', '396', 'cosine', 8)


# use combined 118 and 119 to predice Warren's vote on HR3746 -- rollnumber: 146
final_user_cf(118, 'S', '41301', '146', 'cosine', 8)
combined_user_cf('41301', '146', 118, "S", c(118, 119))

# we handle cases like this so that we replace NA votes with means for combined matrices
# for members who have already voted for more than 30% of all bills in the two congresses
final_user_cf(119, 'S', '21502', '92', 'cosine', 8)
combined_user_cf('21502', '92', 119, "S", c(118, 119))


