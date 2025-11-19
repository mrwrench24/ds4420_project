
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

'''
Outputs an augmented version of the supplied Member Ideology file with additional data from the Congress API
for each member.
'''
def congress_api_legislators(member_path: str):
    pass

'''
Outputs an augmented version of the supplied cleansed Congressional Votes (rollcalls) file with additional data from 
the Congress API for each bill. Again, the supplied file should have already been cleansed (for example, only 30 bills listed).
'''
def congress_api_legislation(cleansed_rollcalls_path: str):
    pass