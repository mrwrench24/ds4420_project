# create the user item matrix that will be used for collaborative filtering
# - parameters:
#  - votes_df: a dataframe with the following columns
#    - icpsr: this is the voter id number
#    - rollnumber: this is the bill number
#    - vote_label: the vote label we assigned (1: yay, 0: N/A, -1: nay)

build_user_item_matrix <- function(votes_df) {
  users <- sort(unique(votes_df$icpsr))
  # items = bills
  bills <- sort(unique(votes_df$rollnumber))
  
  # initialize matrix of 0s
  mat <- matrix(0,
                nrow = length(users),
                ncol = length(bills),
                dimnames = list(users, bills))
  
  # fill matrix
  for (i in seq_len(nrow(votes_df))) {
    u <- votes_df$icpsr[i]
    b <- votes_df$rollnumber[i]
    v <- votes_df$vote_label[i]
    
    # place vote into correct cell
    mat[as.character(u), as.character(b)] <- v
  }
  
  return(mat)
}

# Return a filtered dataframe of votes with a new column for vote_label.
# This will filter out only the bills we are looking for and return the vote dataframe
# - parameters:
#   - votes_df: the vote dataframe with the following columns
#     - rollnumber: bill number
#     - cast_code: the designated vote label that VoteView uses
#   - bills: a list of bills we are looking for in the dataset

filter_votes <- function(votes_df, bills) {
  filtered_votes <- votes_df[votes_df$rollnumber %in% bills,]
  # set cast 1,2,3 as yay, 4,5,6 as nay, and 0,7,8,9 as N/A (or abstain)
  # we should never get to anywhere outside of 0-9 for cast code, but using NA for error handling
  filtered_votes$vote_label <- with(filtered_votes, 
                                          ifelse(cast_code %in% c(1, 2, 3), 1,
                                                 ifelse(cast_code %in% c(4, 5, 6), -1,
                                                        ifelse(cast_code %in% c(0, 7, 8, 9), 0, NA))))
}

house_votes <- read.csv("../data/H118_votes.csv")
senate_votes <- read.csv("../data/S118_votes.csv")

house_rc <- read.csv("../data/H118_rollcalls_CLEANSED.csv")
senate_rc <- read.csv("../data/S118_rollcalls_CLEANSED.csv")

# Bills are identified by their rollnumber
house_bills <- house_rc$rollnumber
senate_bills <- senate_rc$rollnumber

# filter vote df
house_votes <- filter_votes(house_votes, house_bills)
senate_votes <- filter_votes(senate_votes, senate_bills)

# build user-item matrix
house_matrix <- build_user_item_matrix(house_filtered_votes)
senate_matrix <- build_user_item_matrix(senate_filtered_votes)

write.csv(house_matrix, file = "house_cf_118.csv")
write.csv(senate_matrix, file = "senate_cf_118.csv")

# create the user item matrix that will be used for collaborative filtering
# - parameters:
#  - votes_df: a dataframe with the following columns
#    - icpsr: this is the voter id number
#    - rollnumber: this is the bill number
#    - vote_label: the vote label we assigned (1: yay, 0: N/A, -1: nay)

build_user_item_matrix <- function(votes_df) {
  users <- sort(unique(votes_df$icpsr))
  # items = bills
  bills <- sort(unique(votes_df$rollnumber))
  bill_count <- length(bills)
  
  # initialize matrix of 0s
  votes_mat <- matrix(NA,
                      nrow = length(users),
                      ncol = bill_count,
                      dimnames = list(users, bills))
  
  # fill matrix
  for (i in seq_len(nrow(votes_df))) {
    u <- votes_df$icpsr[i]
    b <- votes_df$rollnumber[i]
    v <- votes_df$vote_label[i]
    
    # place vote into correct cell
    votes_mat[as.character(u), as.character(b)] <- v
  }
  
  # only keep users who have voted on more than 30% of bills
  # rowSums returns a count of how many values are true in the row, 
  # where the true values are if it's not NA
  votes_per_user <- rowSums(!is.na(votes_mat))
  user_to_keep <- votes_per_user >= 0.30 * bill_count
  
  votes_mat <- votes_mat[user_to_keep, ]
  return(votes_mat)
}

# Return a filtered dataframe of votes with a new column for vote_label.
# This will filter out only the bills we are looking for and return the vote dataframe
# - parameters:
#   - votes_df: the vote dataframe with the following columns
#     - rollnumber: bill number
#     - cast_code: the designated vote label that VoteView uses
#   - bills: a list of bills we are looking for in the dataset

filter_votes <- function(votes_df, bills) {
  filtered_votes <- votes_df[votes_df$rollnumber %in% bills,]
  # set cast 1,2,3 as yay, 4,5,6 as nay, and 0,7,8,9 as N/A (or abstain)
  # we should never get to anywhere outside of 0-9 for cast code, but using NA for error handling
  filtered_votes$vote_label <- with(filtered_votes, 
                                    ifelse(cast_code %in% c(1, 2, 3), 1,
                                           ifelse(cast_code %in% c(4, 5, 6), -1,
                                                  ifelse(cast_code %in% c(0, 7, 8, 9), 0, NA))))
}

house_votes <- read.csv("../data/H118_votes.csv")
senate_votes <- read.csv("../data/S118_votes.csv")

house_rc <- read.csv("../data/H118_rollcalls_CLEANSED.csv")
senate_rc <- read.csv("../data/S118_rollcalls_CLEANSED.csv")

# Bills are identified by their rollnumber
house_bills <- house_rc$rollnumber
senate_bills <- senate_rc$rollnumber

# filter vote df
house_votes <- filter_votes(house_votes, house_bills)
senate_votes <- filter_votes(senate_votes, senate_bills)

# build user-item matrix
house_matrix <- build_user_item_matrix(house_filtered_votes)
senate_matrix <- build_user_item_matrix(senate_filtered_votes)

write.csv(house_matrix, file = "house_cf_118.csv")
write.csv(senate_matrix, file = "senate_cf_118.csv")
