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
  
  # initialize matrix of NAs to see who didn't vote/NA
  votes_mat <- matrix(NA,
                      nrow = length(users),
                      ncol = bill_count,
                      dimnames = list(users, bills))
  
  # fill matrix
  for (i in seq_len(nrow(votes_df))) {
    u <- as.character(votes_df$icpsr[i])
    b <- as.character(votes_df$rollnumber[i])
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
  return(filtered_votes)
}


# lets the user pass in a congress and chamber and retrieve the data back
# parameters:
# - congress: which congress # we want to look for
# - chamber_code: H for house, S for senate
# - data_dir: the directory where the data is stored
# had to make use of paste0 for this function which concats strings together
load_chamber_data <- function(congress, chamber_code, data_dir = "../data") {
  if (!(chamber_code %in% c("H", "S"))) {
    stop("use S for senate and H for house")
  }
  
  votes_path <- file.path(
    data_dir,
    paste0(chamber_code, congress, "_votes.csv")
  )
  
  rc_path <- file.path(
    data_dir,
    paste0(chamber_code, congress, "_rollcalls_CLEANSED.csv")
  )
  
  votes <- read.csv(votes_path, stringsAsFactors = FALSE)
  rollcalls <- read.csv(rc_path, stringsAsFactors = FALSE)
  
  list(
    votes = votes,
    rollcalls = rollcalls
  )
}

# builds the user-item matrix for each chamber based on congress and chamber
# parameters:
# - congress: which congress # we want to look for
# - chamber: H for house, S for senate
build_matrix_for_chamber <- function(congress, chamber, output_dir = "../collaborative_filtering/") {
  if (!(chamber %in% c("H", "S"))) {
    stop("use S for senate and H for house")
  }
  
  data <- load_chamber_data(congress, chamber)
  bills <- data$rollcalls$rollnumber
  filtered_votes <- filter_votes(data$votes, bills)
  mat <- build_user_item_matrix(filtered_votes)
  
  # save the matrix to the respective file
  output_file <- file.path(
    output_dir,
    paste0(chamber, congress, "_cf", ".csv")
  )
  write.csv(mat, output_file, row.names = TRUE)
  return (mat)
}

# example use case below (for house 118 and senate 118 -- note that these will 
# need to be cleansed using the python preprocessing files beforehand)
# this will automatically save it to H118_cf.csv for example
# including uncommented lines for reproducability of files
senate_111 <- build_matrix_for_chamber(111, "S")
house_111 <- build_matrix_for_chamber(111, "H")
house_118  <- build_matrix_for_chamber(118, "H")
senate_118 <- build_matrix_for_chamber(118, "S")
house_119  <- build_matrix_for_chamber(119, "H")
senate_119 <- build_matrix_for_chamber(119, "S")
