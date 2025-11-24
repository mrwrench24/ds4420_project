# cosine similarity function
cosine_similarity <- function(u1, u2) {
  dot_product <- sum(u1 * u2, na.rm = T)
  u1_magnitude <- sqrt(sum(u1 * u1, na.rm = T))
  u2_magnitude <- sqrt(sum(u2 * u2, na.rm = T))
  sim <- dot_product / (u1_magnitude * u2_magnitude)
  return (sim)
}

# L2 similarity function
L2_similarity <- function(u1, u2) {
  dist <- sqrt(sum((u1 - u2)^2, na.rm = T))
  return (dist)
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
  return (sim)
}

house_votes <- read.csv("house_cf_118.csv", row.names = 1)
senate_votes <- read.csv("senate_cf_118.csv", row.names = 1)

house_cosine_sim <- build_similarity_matrix(house_votes, 'cosine')
senate_cosine_sim <- build_similarity_matrix(senate_votes, 'cosine')

house_l2_sim <- build_similarity_matrix(house_votes, 'L2')
senate_l2_sim <- build_similarity_matrix(senate_votes, 'L2')

# MinMax Scaling the similarity scores
diag(sim_scores) = NA
house_sim_l2_scaled <- apply(house_l2_sim, 2, function(x) (x - min(x, na.rm = T))/(max(x, na.rm = T) - min(x, na.rm = T)))
senate_sim_l2_scaled <- apply(senate_l2_sim, 2, function(x) (x - min(x, na.rm = T))/(max(x, na.rm = T) - min(x, na.rm = T)))
house_sim_cos_scaled <- apply(house_cosine_sim, 2, function(x) (x - min(x, na.rm = T))/(max(x, na.rm = T) - min(x, na.rm = T)))
senate_sim_cos_scaled <- apply(senate_cosine_sim, 2, function(x) (x - min(x, na.rm = T))/(max(x, na.rm = T) - min(x, na.rm = T)))
