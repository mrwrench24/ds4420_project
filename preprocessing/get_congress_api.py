import csv
from pathlib import Path

'''

Data Processing, Step 3:

Part of the project uses the congress.gov API to fetch more information
about legislators and legislation.

From legislators, we learn the # of pieces they have cosponsored and the # of terms they have in office.

From legislation, we learn the # of Democratic and # Republican cosponsors.

To get information about a legislator, we just use their Bioguide ID.

To get information about legislature, we use their bill type and number.

The information for legislators will be output in "{members_path}_API.csv". The information for legislation
will be output in "{cleansed_rollcalls_path}_API.csv".
'''

API_URL = "https://api.congress.gov/v3"

'''
Outputs an augmented version of the supplied Member Ideology file with additional data from the Congress API
for each member.
'''
def congress_api_legislators(member_path: str):
    pass

'''
Returns (bill_type, bill_number) from the given bill number String from VoteView.
'''
def split_bill_num_str(bill_num_str: str):
    # figuring out bill type (letters) and number (numbers)
    # Luckily all bills are of the form "{letter(s)}{number(s)}"
    i = 0
    while i < len(bill_num_str) and bill_num_str[i].isalpha():
        i += 1

    bill_type = bill_num_str[:i]
    bill_num = bill_num_str[i:]

    return bill_type, bill_num

'''
Outputs an augmented version of the supplied cleansed Congressional Votes (rollcalls) file with additional data from 
the Congress API for each bill. Again, the supplied file should have already been cleansed (for example, only 30 bills listed).
'''
def congress_api_legislation(cleansed_rollcalls_path: str, congress_num: int):
    rollcalls_input_path = Path(cleansed_rollcalls_path)
    rollcalls_output_path = rollcalls_input_path.with_name(rollcalls_input_path.suffix + "_API" + rollcalls_input_path.suffix)

    # API endpoint is "/bill/{congress}/{billType}/{billNumber}/cosponsors
    with open(cleansed_rollcalls_path) as f:
        reader = csv.DictReader(f)
        writer = csv.DictWriter(rollcalls_output_path, reader.fieldnames)

        writer.writeheader()

        for row in reader:
            bill_num_str = row['bill_number']
            bill_type, bill_num = split_bill_num_str(bill_num_str)

            endpoint_url = f"{API_URL}/{congress_num}/{bill_type}/{bill_num}/cosponsors"
            # make the API request

            # count number of cosponsors with "party" = "D"
            # count number of cosponsors with "party" = "R"

            # write this back to the file? write to a new file? ??

print(congress_api_legislation("/Users/jakesquatrito/Downloads/S119_rollcalls_CLEANSED.csv", 119))