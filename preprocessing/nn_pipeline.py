from preprocessing.cleanse_bills import cleanse_bills
from preprocessing.cleanse_member_votes import cleanse_member_votes
from preprocessing.get_congress_api import congress_api_legislation, congress_api_legislators
from preprocessing.nn_preprocess import nn_preprocess

'''
Download the 6 relevant files for a Congress and run the pipeline. You'll get the NN files output
in datafiles/NN_files.

This will take a while primarily because of the Congress API.
'''
def nn_pipeline(congress_num: int):
    # Part 1: cleanse bills
    print("Part 1: Cleansing Bills")
    rollcalls_senate_path = f"../datafiles/S{congress_num}_rollcalls.csv"
    rollcalls_house_path = f"../datafiles/H{congress_num}_rollcalls.csv"

    cleanse_bills(rollcalls_senate_path, rollcalls_house_path)

    # Part 2: Cleanse member votes (the long file of individual votes)
    print("Part 2: Cleanse Member Votes")
    cleansed_senate_rollcalls = f"../datafiles/S{congress_num}_rollcalls_CLEANSED.csv"
    cleansed_house_rollcalls = f"../datafiles/H{congress_num}_rollcalls_CLEANSED.csv"

    senate_votes = f"../datafiles/S{congress_num}_votes.csv"
    house_votes = f"../datafiles/H{congress_num}_votes.csv"

    cleanse_member_votes(cleansed_senate_rollcalls, senate_votes)
    cleanse_member_votes(cleansed_house_rollcalls, house_votes)

    # Part 3: Congress API (on cleansed leg. + members)
    print("Part 3: Congress API")
    print("This part takes the longest.")

    congress_api_legislation(cleansed_senate_rollcalls, congress_num)
    print("Senate Leg. Done")
    congress_api_legislation(cleansed_house_rollcalls, congress_num)
    print("House Leg. Done")

    senate_members = f"../datafiles/S{congress_num}_members.csv"
    house_members = f"../datafiles/H{congress_num}_members.csv"

    congress_api_legislators(senate_members, congress_num)
    print("Senate Members Done")
    congress_api_legislators(house_members, congress_num)
    print("House Members Done")

    senate_members_api = f"../datafiles/S{congress_num}_members_API.csv"
    house_members_api = f"../datafiles/H{congress_num}_members_API.csv"

    sen_roll_cleanse_api = f"../datafiles/S{congress_num}_rollcalls_CLEANSED_API.csv"
    house_roll_cleanse_api = f"../datafiles/H{congress_num}_rollcalls_CLEANSED_API.csv"

    sen_votes_cleansed = f"../datafiles/S{congress_num}_votes_CLEANSED.csv"
    house_votes_cleansed = f"../datafiles/H{congress_num}_votes_CLEANSED.csv"

    # Part 4: NN Preprocess
    print("Part 4: NN Preprocess")
    nn_preprocess(senate_members_api, sen_roll_cleanse_api, sen_votes_cleansed, f"../datafiles/NN_files/NN_SENATE_{congress_num}.csv")
    nn_preprocess(house_members_api, house_roll_cleanse_api, house_votes_cleansed,f"../datafiles/NN_files/NN_HOUSE_{congress_num}.csv")

# print("starting 107")
# nn_pipeline(107)
# print("starting 108")
# nn_pipeline(108)
# print("starting 109")
# nn_pipeline(109)
