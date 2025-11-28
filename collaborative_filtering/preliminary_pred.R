# please note that we found this function to not be good at predicting votes for 
# use in CF as seen by the plots in the report and below. We intended to use it 
# to predict strong votes on a new bill based on ideological points, so that we 
# we could use them as a base for new bills before looking at other users but we 
# found it not to give good predictions 

# return 1 if voting for the bill, -1 if against
# parameters:
# - user: the user we are trying to find a vote prediction for
# - bill: the bill we are trying to find the vote for 
# - threshold: the threshold to compare the euclidean distance to
predict_vote <- function(member_df, bill_df, member_id, bill_id, threshold = 0.4) {
  member <- member_df[member_df$icpsr == member_id, ]
  bill <- bill_df[bill_df$rollnumber == bill_id, ]
  distance <- calculate_ideological_distance(member, bill)
  
  # a lower distance than threshold means they are more likely to vote for the bill
  return(distance <= threshold)
}

# plots the ideological space for the bill's nominate points vs the voters
# parameters
# - member_df: the member data from voteview
# - votes_mat: the user-item vote matrix
# - bill_df: the rollcall dataset (cleansed version)
# - bill_id: the bill number we are trying to visualize for
plot_bill_votes_nominate <- function(member_df, votes_mat, bill_df, bill_id) {
  # extract vote vector for this bill
  votes <- votes_mat[, as.character(bill_id)]
  names(votes) <- rownames(votes_mat)
  
  # attach member votes to icpsr id and use votecolor
  member_df$vote <- votes[as.character(member_df$icpsr)]
  member_df$vote_color <- ifelse(member_df$vote == 1, "Yea",
                                 ifelse(member_df$vote == -1, "Nay", "N/A"))
  
  # find the nominate_mid points
  bill_row <- bill_df[bill_df$rollnumber == bill_id, ]
  bill_point <- data.frame(
    dim1 = bill_row$nominate_mid_1,
    dim2 = bill_row$nominate_mid_2
  )
  
  ggplot(member_df, aes(x = nominate_dim1, y = nominate_dim2)) +
    geom_point(aes(color = vote_color), size = 3, alpha = 0.8) +
    geom_point(data = bill_point, aes(x = dim1, y = dim2),
               color = "blue", size = 5) +
    scale_color_manual(values = c(
      "Yea" = "green",
      "Nay" = "red",
      "Neutral" = "gray"
    )) +
    labs(
      title = paste("ideological space for bill", bill_id),
      x = "nominate_dim1",
      y = "nominate_dim2",
      color = "vote"
    )
}

# example use:
# house_member_df <- read.csv("../data/H118_members.csv", check.names = FALSE)
# house_votes_df <- read.csv("../data/H118_rollcalls_CLEANSED.csv", check.names = FALSE)

# predict_vote(house_member_df, house_votes_df, '14873', '231')

# for plotting (bill 118 in example):
# house_votes <- read.csv("house_cf_118.csv", row.names = 1, check.names = FALSE)
# plot_bill_votes_nominate(house_member_df, house_votes, house_votes_df, 118)
