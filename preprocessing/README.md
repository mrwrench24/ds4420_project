# Neural Network: Pre-Processing Overview

The neural network requires "Member Ideology", "Congressional Votes", and "Members' Votes"
datasets from a specific chamber and Congress. We collect extra data from each piece
of legislation and each legislator using the congress.gov API. 

Preprocessing follows these steps:

1. Cleanse Bills - not all of the bills in a "Congressional Votes" dataset will be relevant. 
There are specific types of bills we want to predict. cleanse_bills.py is used to remove these irrelvant bills.

2. Cleanse Member Votes - like before, the Members' Votes dataset contains many votes on procedural motions / 
other pieces of business not relevant to our project. cleanse_member_votes.py removes these irrelvant bills
by referencing a cleansed bills file and determining which votes to keep.

3. Get Congress API - This should be run on the cleansed bills as well as the corresponding "Member Ideology" 
dataset (same chamber / Congress). It will augment each dataset. Bills will now contain the number of 
Democratic and Republican cosponsors. Legislators will now include the number of terms in office and the
number of pieces of legislation that they cosponsored.

4. Neural Network Preprocessing - Put the final touches on the dataset. Combines the relevant members, rollcalls,
and votes dataset to create a single .csv where each row is a complete, singular input to the neural network. Also performs
typical preprocessing - one-hot encoding, scaling, etc. 