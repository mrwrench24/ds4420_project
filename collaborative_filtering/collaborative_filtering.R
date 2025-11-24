# cosine similarity function
cosine_similarity <- function(u1, u2) {
  dot_product <- sum(u1 * u2)
  u1_magnitude <- sqrt(sum(u1 * u1))
  u2_magnitude <- sqrt(sum(u2 * u2))
  sim <- dot_product / (u1_magnitude * u2_magnitude)
  return (sim)
}

# L2 similarity function
L2_similarity <- function(u1, u2) {
  dist <- sqrt(sum((u1 - u2)^2))
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
      } else {
        sim_ij <- L2_similarity(votes_mat[, i], votes_mat[, j])
      }
      sim[i, j] <- sim_ij
      sim[j, i] <- sim_ij
    }
  }
  sim
}
