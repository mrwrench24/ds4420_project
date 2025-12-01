import csv
import requests
from pathlib import Path
from tqdm import tqdm

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
API_KEY = "FgDW4PImyNFJlEtXkh4fF2etdofA6vxoR7U7agzd"

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

    return bill_type.lower(), bill_num

'''
Outputs an augmented version of the supplied Member Ideology file with additional data from the Congress API
for each member.
'''
def congress_api_legislators(member_path: str, congress_num: int):
    member_input_path = Path(member_path)
    member_output_path = member_input_path.with_name(member_input_path.stem + "_API" + member_input_path.suffix)

    # endpoint is /memeber/{bioguideId}
    with open(member_path) as member_input_file, open(member_output_path, 'w') as member_output_file:
        reader = csv.DictReader(member_input_file)
        writer = csv.DictWriter(member_output_file, fieldnames=reader.fieldnames + ["pieces_cosponsored", "num_congresses"])

        writer.writeheader()

        for row in tqdm(reader):
            member_bioguide = row["bioguide_id"]

            endpoint_url = f"{API_URL}/member/{member_bioguide}"
            params = {
                "format": "json",
                "api_key": API_KEY
            }

            response = requests.get(endpoint_url, params=params)
            response.raise_for_status()

            data = response.json()

            if "member" not in data:
                print(f"WARNING: Skipping for {row}")
                continue

            member_terms = data["member"]["terms"]

            # the api returns "terms" as each congress they have served in
            num_congresses = len([t for t in member_terms if t["congress"] < congress_num])
            num_cosponsored = data["member"]["cosponsoredLegislation"]["count"]

            api_row = dict(row)
            api_row["pieces_cosponsored"] = num_cosponsored
            api_row["num_congresses"] = num_congresses

            writer.writerow(api_row)

'''
Outputs an augmented version of the supplied cleansed Congressional Votes (rollcalls) file with additional data from 
the Congress API for each bill. Again, the supplied file should have already been cleansed (for example, only 30 bills listed).
'''
def congress_api_legislation(cleansed_rollcalls_path: str, congress_num: int):
    rollcalls_input_path = Path(cleansed_rollcalls_path)
    rollcalls_output_path = rollcalls_input_path.with_name(rollcalls_input_path.stem + "_API" + rollcalls_input_path.suffix)

    # API endpoint is "/bill/{congress}/{billType}/{billNumber}/cosponsors
    with open(cleansed_rollcalls_path) as cleansed_rollcalls_file, open(rollcalls_output_path, "w") as rollcalls_output_file:
        reader = csv.DictReader(cleansed_rollcalls_file)
        writer = csv.DictWriter(rollcalls_output_file, reader.fieldnames + ["dem_cosponsors", "rep_cosponsors"])

        writer.writeheader()

        for row in tqdm(reader):
            bill_num_str = row['bill_number']
            bill_type, bill_num = split_bill_num_str(bill_num_str)

            endpoint_url = f"{API_URL}/bill/{congress_num}/{bill_type}/{bill_num}/cosponsors"
            params = {
                "format": "json",
                "api_key": API_KEY,
                # the results are paginated. we don't need that
                "limit": 999
            }

            response = requests.get(endpoint_url, params=params)
            response.raise_for_status()

            data = response.json()

            cosponsors = data["cosponsors"]
            rep_cosponsors = 0
            dem_cosponsors = 0

            for cosponsor in cosponsors:
                if cosponsor["party"] == "D":
                    dem_cosponsors += 1

                if cosponsor["party"] == "R":
                    rep_cosponsors += 1

            api_row = dict(row)
            api_row["dem_cosponsors"] = dem_cosponsors
            api_row["rep_cosponsors"] = rep_cosponsors

            writer.writerow(api_row)

# congress_api_legislation("/Users/jakesquatrito/Downloads/H118_rollcalls_CLEANSED.csv", 118)
# congress_api_legislation("/Users/jakesquatrito/Downloads/S118_rollcalls_CLEANSED.csv", 118)
#
# congress_api_legislators("/Users/jakesquatrito/Downloads/H118_members.csv", 118)
# congress_api_legislators("/Users/jakesquatrito/Downloads/S118_members.csv", 118)