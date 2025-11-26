import csv
import pandas as pd

'''

4. Neural Network Preprocessing

This is the last step in data preprocessing for the neural network. It outputs a full, single CSV where each row
is input to the Neural Network for training.

Each row of an NN_{Chamber}_{Congress #}.csv file contains the following columns, making it a suitable
input to the planned Neural Network:
- Member Party
- Member State (PUNT)
- Member Age (PUNT)
- Member Chamber
- # Dem Cosponsors
- # Rep Cosponsors
- # Pieces Cosponsored
- # Terms in Office
- Member Voteview Dimensions (1 and 2)
- Legislation Voteview Dimensions (1 and 2)

For training, it also has to include:
- Member's Vote (For simplicity, 0 = no, 1 = yes, remove all non-votes / presents)

To keep it organized, we will also include:
- Bioguide ID for the Member
- ICPSR for the Member (Voteview Internal ID)
- The Bill #
- The Bill Description
- Member Name

'''

MEMBER_KEYS = ["party_code", "state_abbrev", "born", "chamber", "nominate_dim1", "nominate_dim2", "pieces_cosponsored", "num_congresses", "bioname"]
BILL_KEYS = ["nominate_mid_1", "nominate_mid_2", "dem_cosponsors", "rep_cosponsors", "bill_number", "vote_desc", "vote_result"]

CHAMBER_MAPPING = { "House": 0, "Senate": 1 }

# the first (left, MSB) digit
PARTY_MAPPING_1 = { "100": 0, "200": 0, "328": 1 }
# the second (right, LSB) digit
PARTY_MAPPING_2 = { "100": 0, "200": 1, "328": 1 }

# yes = 1, no = 0
VOTE_MAPPING = {
    4: 0,
    5: 0,
    6: 0,
    1: 1,
    2: 1,
    3: 1
}

def nn_dataset_merging(members_api: str, rollcalls_cleansed_api: str, votes_cleansed: str) -> pd.DataFrame:
    # 1. build a dictionary mapping members to their ICPSRs for quick access
    # FIELDS: party, state, age, chamber, dim1, dim2, pieces cosponsored, terms in office
    # AND ALSO: bioguide ID, ICPSR (key), name

    members_dict = dict()

    with open(members_api) as members_file:
        reader = csv.DictReader(members_file)

        for row in reader:
            icpsr = int(row["icpsr"])

            dict_for_member = dict()
            for key in MEMBER_KEYS:
                dict_for_member[key] = row[key]

            members_dict[icpsr] = dict_for_member

    # 2. build a dictionary mapping bills to their rollcall numbers for quick access
    # FIELDS: dim1, dim2, dem cosponsors, rep cosponsors
    # AND ALSO: bill # (like HR1234), bill description

    bill_dict = dict()

    with open(rollcalls_cleansed_api) as rollcalls_file:
        reader = csv.DictReader(rollcalls_file)

        for row in reader:
            rollnumber = row["rollnumber"]

            dict_for_bill = dict()
            for key in BILL_KEYS:
                dict_for_bill[key] = row[key]

            bill_dict[rollnumber] = dict_for_bill

    # 3. read through the actual votes. each vote will become a row. have to add the relevant information from the dictionaries.
    row_dictionaries = []
    with open(votes_cleansed) as votes_file:
        reader = csv.DictReader(votes_file)

        for row in reader:
            rollnumber = row["rollnumber"]
            # sometimes the data is a double (thanks voteview :/)
            icpsr = int(float(row["icpsr"]))

            if icpsr not in members_dict:
                print(f"Skipping icpsr {icpsr}")
                continue

            member_info = members_dict[icpsr]
            bill_info = bill_dict[rollnumber]

            merged_info = member_info | bill_info

            merged_info["vote"] = int(float(row["cast_code"]))
            merged_info["rollnumber"] = rollnumber
            merged_info["icpsr"] = icpsr

            row_dictionaries.append(merged_info)

    # build a dataframe from the dictionaries
    df = pd.DataFrame(row_dictionaries)
    return df

def nn_preprocess(members_api: str, rollcalls_cleansed_api: str, votes_cleansed: str, output_path: str):
    # does the first three steps, which are essentially just bouncing in between the
    # datasets to build a dataframe with each row containing the relevant member + legislative information
    merged_df = nn_dataset_merging(members_api, rollcalls_cleansed_api, votes_cleansed)

    # 4. typical ML preprocessing
    '''
    Categorical Variables - using custom mappings to ensure consistency across
    generated datasets. All categories may not always be present but we need to ensure encodings
    are always the same.
    
    - Chamber: House = 0. Senate = 1.
    - Party Code: 100 = Democrat = [0, 0]. 200 = Republican = [0, 1]. 328 = Independent = [1, 0].
    - Vote: 1, 2, 3 = yes = 1, 4, 5, 6 = nay = 0, 7, 8, 9, and 0 = no vote and should be removed 
    
    - State: I'm punting on this for now, but we can add it back in if we want to add more to the model.
    I don't know of a methodologically sound way to do this that doesn't GREATLY increase the complexity of the model 
    overall. I thought about using election results and just binning them based on the margin for the D/R but
    that requires either 1.) we are bound to one election's results (and it misses changing nature of country)
    or 2.) requires a lot more data to be collected.
    '''
    merged_df = merged_df[merged_df["chamber"].isin(CHAMBER_MAPPING)]
    merged_df["chamber"] = merged_df["chamber"].map(CHAMBER_MAPPING).astype(int)

    merged_df["party_code_1"] = merged_df["party_code"].map(PARTY_MAPPING_1).astype(int)
    merged_df["party_code_2"] = merged_df["party_code"].map(PARTY_MAPPING_2).astype(int)

    # remove non-votes, then replace
    merged_df = merged_df[~merged_df["vote"].isin([0, 7, 8, 9])]
    merged_df["vote"] = merged_df["vote"].map(VOTE_MAPPING).astype(int)

    print(merged_df.head())
    print(merged_df["vote"].unique())

    # should be only 0, 1
    # print(merged_df["vote"].unique())

    '''
    Scaling - Since we will be working with different Congress/Chamber combos, it is good 
    to enforce specific minimum and maximum values for each feature (based on what we know to be reasonable
    min/max for them) to ensure consistency across datasets.
    
     - Age - there are reasonable minimums and maximums we can put in place
     -   Again I'm going to punt on this to make sure it is done correctly, if at all.
     - # of Cosponsors - min = 0, max = 535 (or something like that)
     - # cosponsored - min = 0, no reasonable maximum
     - Terms / Num Congresses - min = 0, reasonable max = 40 (implies 80 years in Congress)
     - Voteview dimensions - go from -1 to 1 (already scaled)
    '''

    # # min = 1900, making you 100 years old in 2000. max = 2000, making you 25 in 2025, eligible to be in the House.
    # merged_df["born"] = (merged_df["born"] - 1900) / (2000 - 1900)

    # roughly 535 House Members + Senators combined
    merged_df["dem_cosponsors"] = merged_df["dem_cosponsors"].astype(int) / 535
    merged_df["rep_cosponsors"] = merged_df["rep_cosponsors"].astype(int) / 535

    # looks like a "high" number of cosponsored pieces would be ~40-50k, so we will say the max is ~75k.
    # the min still is 0.
    merged_df["pieces_cosponsored"] = merged_df["pieces_cosponsored"].astype(int) / 75000

    # terms - min is 0, reasonable max = 40.
    merged_df["num_congresses"] = merged_df["num_congresses"].astype(int) / 40

    # and lastly, just removing irrelvant columns we don't need anymore
    merged_df.drop("party_code", axis=1, inplace=True)
    # may add back
    merged_df.drop("born", axis=1, inplace=True)

    merged_df.to_csv(output_path, index=False)

nn_preprocess(
    "/Users/jakesquatrito/Desktop/ds4420_project/datafiles/H119_members_API.csv",
    "/Users/jakesquatrito/Desktop/ds4420_project/datafiles/H119_rollcalls_CLEANSED_API.csv",
"/Users/jakesquatrito/Desktop/ds4420_project/datafiles/H119_votes_CLEANSED.csv",
    "../datafiles/NN_FILES/NN_HOUSE_119.csv"
)

nn_preprocess(
    "/Users/jakesquatrito/Desktop/ds4420_project/datafiles/S119_members_API.csv",
    "/Users/jakesquatrito/Desktop/ds4420_project/datafiles/S119_rollcalls_CLEANSED_API.csv",
"/Users/jakesquatrito/Desktop/ds4420_project/datafiles/S119_votes_CLEANSED.csv",
    "../datafiles/NN_files/NN_SENATE_119.csv"
)