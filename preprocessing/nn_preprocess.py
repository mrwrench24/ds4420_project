import csv
import pandas as pd

'''

4. Neural Network Preprocessing

This is the last step in data preprocessing for the neural network. It outputs a full, single CSV where each row
is input to the Neural Network for training.

Each row of an NN_{Chamber}_{Congress #}.csv file contains the following columns, making it a suitable
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
- Member Voteview Dimensions (1 and 2)
- Legislation Voteview Dimensions (1 and 2)

For training, it also has to include:
- Member's Vote

To keep it organized, we will also include:
- Bioguide ID for the Member
- ICPSR for the Member (Voteview Internal ID)
- The Bill #
- The Bill Description
- Member Name

'''

MEMBER_KEYS = ["party_code", "state_icpsr", "born", "chamber", "nominate_dim1", "nominate_dim2", "pieces_cosponsored", "num_congresses", "bioname"]
BILL_KEYS = ["nominate_mid_1", "nominate_mid_2", "dem_cosponsors", "rep_cosponsors", "bill_number", "vote_desc", "vote_result"]

def nn_preprocess(members_api: str, rollcalls_cleansed_api: str, votes_cleansed: str, output_path: str):
    # 1. build a dictionary mapping members to their ICPSRs for quick access
    # FIELDS: party, state, age, chamber, dim1, dim2, pieces cosponsored, terms in office
    # AND ALSO: bioguide ID, ICPSR (key), name

    members_dict = dict()

    with open(members_api) as members_file:
        reader = csv.DictReader(members_file)

        for row in reader:
            icpsr = row["icpsr"]

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
    with open(votes_cleansed) as votes_file, open(output_path, 'w') as output_file:
        reader = csv.DictReader(votes_file)
        writer = csv.DictWriter(output_file, MEMBER_KEYS + BILL_KEYS + ["vote", "rollnumber", "icpsr"])

        writer.writeheader()

        for row in reader:
            rollnumber = row["rollnumber"]
            icpsr = row["icpsr"]

            member_info = members_dict[icpsr]
            bill_info = bill_dict[rollnumber]

            merged_info = member_info | bill_info

            merged_info["vote"] = row["cast_code"]
            merged_info["rollnumber"] = rollnumber
            merged_info["icpsr"] = icpsr

            row_dictionaries.append(merged_info)

    # build a dataframe from the dictionaries
    df = pd.DataFrame(row_dictionaries)

    print(df.head())


    # 4. typical ML preprocessing

    pass

nn_preprocess(
    "/Users/jakesquatrito/Desktop/ds4420_project/datafiles/H119_members_API.csv",
    "/Users/jakesquatrito/Desktop/ds4420_project/datafiles/H119_rollcalls_CLEANSED_API.csv",
"/Users/jakesquatrito/Desktop/ds4420_project/datafiles/H119_votes_CLEANSED.csv",
    "/Users/jakesquatrito/Desktop/ds4420_project/datafiles/NN_HOUSE_119.csv"
)

nn_preprocess(
    "/Users/jakesquatrito/Desktop/ds4420_project/datafiles/S119_members_API.csv",
    "/Users/jakesquatrito/Desktop/ds4420_project/datafiles/S119_rollcalls_CLEANSED_API.csv",
"/Users/jakesquatrito/Desktop/ds4420_project/datafiles/S119_votes_CLEANSED.csv",
    "/Users/jakesquatrito/Desktop/ds4420_project/datafiles/NN_SENATE_119.csv"
)