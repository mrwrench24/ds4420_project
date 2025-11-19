import csv
from pathlib import Path

'''
Data Processing, Step 2:

Given a path to a cleansed House / Senate "rollcalls" CSV (which lists the legislation), and a path
to a "Member's Votes" CSV (which lists individual votes, and should be for the same chamber),
outputs a cleansed "Member's Votes" CSV, which will only retain votes with a rollnumber
found in the cleansed rollcall dataset.
'''
def cleanse_member_votes(cleansed_rollcalls_path: str, members_votes_path: str):
    relevant_rollnums = set()

    # getting the roll numbers we want to keep
    with open(cleansed_rollcalls_path) as cleansed_rollcalls_file:
        reader = csv.DictReader(cleansed_rollcalls_file)

        for row in reader:
            roll_number = row['rollnumber']

            relevant_rollnums.add(roll_number)

    members_input_path = Path(members_votes_path)
    members_output_path = members_input_path.with_name(members_input_path.stem + "_CLEANSED" + members_input_path.suffix)

    with open(members_votes_path) as members_votes_file, open(members_output_path, 'w') as cleansed_file:
        reader = csv.DictReader(members_votes_file)
        writer = csv.DictWriter(cleansed_file, fieldnames=reader.fieldnames)

        writer.writeheader()

        for row in reader:
            rollnumber = row['rollnumber']

            if rollnumber in relevant_rollnums:
                writer.writerow(row)

cleanse_member_votes("/Users/jakesquatrito/Downloads/S119_rollcalls_CLEANSED.csv", "/Users/jakesquatrito/Downloads/S119_votes.csv")
cleanse_member_votes("/Users/jakesquatrito/Downloads/H119_rollcalls_CLEANSED.csv", "/Users/jakesquatrito/Downloads/H119_votes.csv")
