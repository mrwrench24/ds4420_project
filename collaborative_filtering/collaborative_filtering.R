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
# - target_user: the user we are trying to predict the vote for
# - target_bill: the bill we are trying to predict the user's vote for
# - similarity: the similarity metric
# - k: number for top k similar users
user_collab_filter <- function(votes_df, target_user, target_bill, similarity, k) {
  if (!(target_user %in% rownames(votes_df))) {
    stop('user does not exist or has not voted on enough legislations')
  }
  
  if (!(target_bill %in% colnames(votes_df))) {
    stop("target bill not found in votes matrix")
  }
  
  # we need to use the transpose so that users are the columns
  sim_matrix <- build_similarity_matrix(t(votes_df), similarity)
  
  # we set the index of the sim_matrix to be based on the user icpsr IDs
  colnames(sim_matrix) <- rownames(votes_df)
  rownames(sim_matrix) <- rownames(votes_df)
  
  # only account for users who voted on this bill
  bill_votes <- votes_df[, target_bill]
  
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
                            icpsr, bill, metric, 
                            k, 
                            mat_dir = "../collaborative_filtering") {
  
  # get the file path by concatenating the string to _cf
  mat <- file.path(
    mat_dir, 
    paste0(chamber, congress, "_cf.csv"))
  
  votes_mat <- read.csv(mat, row.names = 1, check.names = FALSE)
  pred <- user_collab_filter(votes_mat, icpsr, bill, metric, k)
  return(pred)
}

# example
final_user_cf(118, 'H', '14854','118', 'cosine', 25)
final_user_cf(118, 'S', '41301','146', 'cosine', 8)

# example use for user with icpsr id 14854 and bill 118 using specific func
# house_votes <- read.csv("H118_cf.csv", row.names = 1, check.names = FALSE)
# senate_votes <- read.csv("S118_cf.csv", row.names = 1, check.names = FALSE)
# user_collab_filter(house_votes, '14854','118', 'cosine', 200)
# user_collab_filter(senate_votes, '15021','212', 'L2', 20)

# unfortunately, the model is not perfect, and makes some mistakes because
# some voters are unpredictable on certain bills

# how did Elizabeth Warren (ICPSR 41301) vote on the Fiscal Responsibility Act 
# she voted NO
# user_collab_filter(senate_votes, '41301','146', 'cosine', 8)
# user_collab_filter(senate_votes, '41301','146', 'L2', 8)