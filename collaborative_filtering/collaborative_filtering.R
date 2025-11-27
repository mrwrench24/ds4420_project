# cosine similarity function
cosine_similarity <- function(u1, u2) {
  dot_product <- sum(u1 * u2, na.rm = T)
  u1_magnitude <- sqrt(sum(u1 * u1, na.rm = T))
  u2_magnitude <- sqrt(sum(u2 * u2, na.rm = T))
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

# ***************************
# DO WE NEED TO CENTER DATA?? AND SHOULD WE CHANGE VOTES PARAM
# ***************************

# does the collaborative filtering to return a prediction for how a user will vote on a bill
# parameters:
# - votes_df: the dataframe of previous votes 
# - target_user: the user we are trying to predict the vote for
# - target_bill: the bill we are trying to predict the user's vote for
# - similarity: the similarity metric
# - k: number for top k similar users
user_collab_filter <- function(votes_df, target_user, target_bill, similarity = 'cosine', k = 5) {
  if (!(target_user %in% rownames(votes_df))) {
    stop('user does not exist or has not voted on enough legislations')
  }
  
  # we need to use the transpose so that users are the columns
  sim_matrix <- build_similarity_matrix(t(votes_df), similarity)
  
  # we set the index of the sim_matrix to be based on the user icpsr IDs
  colnames(sim_matrix) <- rownames(votes_df)
  rownames(sim_matrix) <- rownames(votes_df)
  
  # only account for users who voted on this bill
  bill_votes <- votes_df[, target_bill]
  valid_users <- which(!is.na(bill_votes))
  valid_users <- valid_users[valid_users != target_user]

  # mark self-similarity as NA to avoid accounting for it
  # similarities for target user
  user_similarities <- sim_matrix[target_user, ]
  user_similarities[target_user] <- NA
  user_similarities <- user_similarities[valid_users]
  sorted_user_sim <- sort(user_similarities, decreasing=TRUE)
  
  # top-k neighbors
  sorted_users <- sort(user_similarities, decreasing = TRUE)
  top_k_users <- sorted_users[1:k]
  
  # top-k votes
  bill_votes <- bill_votes[valid_users]
  top_k_votes <- bill_votes[top_k_users]
  print(top_k_votes)
  
  # weighted prediction
  prediction <- sum(top_k_users * top_k_votes, na.rm = TRUE) /
    sum(abs(top_k_users), na.rm = TRUE)
  return(prediction)
}

house_votes <- read.csv("house_cf_118.csv", row.names = 1)
senate_votes <- read.csv("senate_cf_118.csv", row.names = 1)

house_cosine_sim <- build_similarity_matrix(t(house_votes), 'cosine')
senate_cosine_sim <- build_similarity_matrix(t(senate_votes), 'cosine')

house_l2_sim <- build_similarity_matrix(t(house_votes), 'L2')
senate_l2_sim <- build_similarity_matrix(t(senate_votes), 'L2')
