import csv
from pathlib import Path

'''
Data Processing, Step 1:

This code will cleanse a "rollcalls" CSV from VoteView.

The VoteView data, as is, includes votes / data on many procedural motions, and
the goal of the project is not to make predictions on these.

While they are still important, we are focused on final votes - they are more impactful
and more data is available for them.

Provide a path to a senate and house bill from the same Congress. 

Cleansing a rollcall dataset will:
- Remove rows from the Senate data where the "vote result" is not one of certain allowed types
- Remove rows from the House data where the "vote question" is not one of certain allowed types or the
bill's number is not found in the Senate data
'''

SENATE_ALLOWED_RESULTS = ["Bill Defeated", "Bill Passed", "Joint Resolution Defeated", "Joint Resolution Passed"]
HOUSE_ALLOWED_QUESTIONS = ["On Agreeing to the Resolution", "On Agreeing to the Resolution, as Amended",
                           "On Motion to Suspend the Rules and Agree", "On Motion to Suspend the Rules and Agree to the Conference Report",
                           "On Motion to Suspend the Rules and Agree to the Resolution, as Amended",
                           "On Motion to Suspend the Rules and Agree, as Amended",
                           "On Motion to Suspend the Rules and Concur in the Senate Amendment",
                           "On Motion to Suspend the Rules and Pass",
                           "On Motion to Suspend the Rules and Pass, as Amended", "On Passage"]

def cleanse_bills(rollcalls_senate_path: str, rollcalls_house_path: str):
    senate_input_path = Path(rollcalls_senate_path)
    # appends the CLEANSED suffix
    senate_output_path = senate_input_path.with_name(senate_input_path.stem + "_CLEANSED" + senate_input_path.suffix)

    senate_bill_numbers = set()

    with open(rollcalls_senate_path) as rollcalls_file, open(senate_output_path, "w") as cleansed_file:
        reader = csv.DictReader(rollcalls_file)
        writer = csv.DictWriter(cleansed_file, fieldnames=reader.fieldnames)

        # dict writer will not write the names unless we tell it to
        writer.writeheader()

        for row in reader:
            result = row['vote_result']

            if result in SENATE_ALLOWED_RESULTS:
                writer.writerow(row)
                senate_bill_numbers.add(row['bill_number'])

    house_input_path = Path(rollcalls_house_path)
    house_output_path = house_input_path.with_name(house_input_path.stem + "_CLEANSED" + house_input_path.suffix)

    with open(house_input_path) as house_file, open(house_output_path, "w") as cleansed_file:
        reader = csv.DictReader(house_file)
        writer = csv.DictWriter(cleansed_file, fieldnames=reader.fieldnames)

        writer.writeheader()

        for row in reader:
            question = row['vote_question']
            bill_number = row['bill_number']

            if question in HOUSE_ALLOWED_QUESTIONS and bill_number in senate_bill_numbers:
                writer.writerow(row)

cleanse_bills("data/S119_rollcalls.csv", "data/H119_rollcalls.csv")
