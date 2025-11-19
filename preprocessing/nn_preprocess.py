import csv

'''

This is the last step in data preprocessing, as it outputs a full, single CSV where each row
is input to the Neural Network for training.

Extracts, from a cleansed and augmented Rollcalls dataset (one for Senate, and one for House),
an augmented "Member Ideology" dataset (for Senate and for House), and the corresponding
cleansed "Member's Votes" datasets (for Senate and for House), a "NN_{Congress_Number}.csv" file.

Each row of an NN_{Congress_Number}.csv file contains the following columns, making it a suitable
input to the planned Neural Network:
- Member Party
- Member State
- Member Age
- Member Chamber
- # Dems in Chamber
- # Reps in Chamber
- # Dem Cosponsors
- # Rep Cosponsors
- # Pieces Cosponsored
- # Terms in Office
- Member Voteview Dimensions
- Legislation Voteview Dimensions

For training, it also has to include:
- Member's Vote

To keep it organized, we will also include:
- Bioguide ID for the Member
- ICPSR for the Member (Voteview Internal ID)
- The Bill #
- The Bill Description

'''
