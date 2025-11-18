import csv
from pathlib import Path

'''
This code will cleanse a "rollcalls" CSV from VoteView.

The VoteView data, as is, includes votes / data on many procedural motions, and
the goal of the project is not to make predictions on these.

While they are still important, we are focused on final votes - they are more impactful
and more data is available for them.

Cleansing a rollcall dataset will:
- Remove rows where the "vote_result" is not "Bill Defeated", "Bill Passed",
"Joint Resolution Defeated", or "Joint Resolution Passed".
- Given, as an argument, the file "/folder/to/senate118_rollcalls.csv",
the cleansed legislative data will be written to "/folder/to/senate118_rollcalls_CLEANSED.csv".
'''

ALLOWED_RESULTS = ["Bill Defeated", "Bill Passed", "Joint Resolution Defeated", "Joint Resolution Passed"]

def cleanse_bills(rollcalls_path: str):
    input_path = Path(rollcalls_path)
    # appends the CLEANSED suffix
    output_path = input_path.with_name(input_path.stem + "_CLEANSED" + input_path.suffix)

    with open(rollcalls_path) as rollcalls_file, open(output_path, "w") as cleansed_file:
        reader = csv.DictReader(rollcalls_file)
        writer = csv.DictWriter(cleansed_file, fieldnames=reader.fieldnames)

        # dict writer will not write the names unless we tell it to
        writer.writeheader()

        for row in reader:
            result = row['vote_result']

            if result in ALLOWED_RESULTS:
                writer.writerow(row)

cleanse_bills("/Users/jakesquatrito/Downloads/S118_rollcalls.csv")