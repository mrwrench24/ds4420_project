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
  
  # we need to use the transpose so that users are the columns
  sim_matrix <- build_similarity_matrix(t(votes_df), similarity)
  
  # we set the index of the sim_matrix to be based on the user icpsr IDs
  colnames(sim_matrix) <- rownames(votes_df)
  rownames(sim_matrix) <- rownames(votes_df)
  
  # only account for users who voted on this bill
  bill_votes <- votes_df[, target_bill]
  
  # need to rename the bill columns by user id, otherwise the indexing won't work
  names(bill_votes) <- rownames(votes_df) 
  
  # find users that votes on this bill and remove target_user
  valid_users <- which(!is.na(bill_votes))
  valid_users <- valid_users[valid_users != target_user]
  
  # mark self-similarity as NA to avoid accounting for it
  # similarities for target user
  user_similarities <- sim_matrix[target_user, ]
  user_similarities[target_user] <- NA
  user_similarities <- user_similarities[valid_users]

  # top-k neighbors
  sorted_user_sim <- sort(user_similarities, decreasing = TRUE)
  top_k_user_sim <- sorted_user_sim[1:k]
  
  # top-k votes
  bill_votes <- bill_votes[valid_users]

  top_k_votes <- bill_votes[names(top_k_user_sim)]

  # weighted prediction (should not have any NA at this point, but just in case we do)
  prediction <- sum(top_k_user_sim * top_k_votes, na.rm = TRUE) /
    sum(abs(top_k_user_sim), na.rm = TRUE)
  return(prediction)
}

# find distance between bill nominate points and user ideal points
calculate_ideological_distance <- function(user, bill) {
  user_pos <- c(user$nominate_dim1, user$nominate_dim2)
  bill_pos <- c(bill$nominate_mid_1, bill$nominate_mid_2)
  
  # euclidean distance
  distance <- sqrt(sum((user_pos - bill_pos)^2))
  return(distance)
}

# *********************
# FIGURE OUT THRESHOLD WE WANT
# *********************

# return 1 if voting for the bill, -1 if against
# parameters:
# - user: the user we are trying to find a vote prediction for
# - bill: the bill we are trying to find the vote for 
# - threshold: the threshold to compare the euclidean distance to
predict_vote <- function(member_df, bill_df, member_id, bill_id, threshold = 0.4) {
  member <- member_df[member_df$icpsr == member_id, ]
  bill <- bill_df[bill_df$rollnumber == bill_id, ]
  distance <- calculate_ideological_distance(member, bill)
  
  effective_threshold <- sqrt(bill$nominate_spread_1^2 + bill$nominate_spread_2^2)
  effective_threshold <- threshold * (1 + spread_magnitude)
  
  print(effective_threshold)
  print(distance <= effective_threshold)
  print(distance)
  # a lower distance than threshold means they are more likely to vote for the bill
  return(distance <= threshold)
}

house_member_df <- read.csv("../data/H118_members.csv", check.names = FALSE)
house_votes_df <- read.csv("../data/H118_rollcalls_CLEANSED.csv", check.names = FALSE)

house_votes <- read.csv("house_cf_118.csv", row.names = 1, check.names = FALSE)
senate_votes <- read.csv("senate_cf_118.csv", row.names = 1, check.names = FALSE)


# example use for user with icpsr id 14854 and bill 118
# user_collab_filter(house_votes, '14854','118', 'cosine', 200)
# user_collab_filter(senate_votes, '15021','212', 'L2', 20)
