import numpy as np

'''
Print out a few votes to see *what* the model is actually outputting for them.
'''
def anecdotal_analysis(model):
    print("------- Big Beautiful Bill ---------")
    # Lisa Murkowski (icpsr: 40300) and Susan Collins (icpsr: 49703) on the Big Beautiful Bill (HR1)
    # BBB nominate = -0.258, 0.966, 0 cosponsors of both
    # Murkowski = 0.203, -0.304, 0.0471866666 cosponsor, 0.3 congresses, voted YES (1)
    # Collins = 0.124, -0.505, 0.087 cosponsor, 0.35 congresses, voted NO (0)
    # both have party code = 0, 1
    murkowski = np.array([
        0.0, 1.0, 1.0, 0.0, 0.0, 0.0471866666,
        0.3, 0.203, -0.304, -0.258, 0.966
    ]).reshape(1, -1)

    collins = np.array([
        0.0, 1.0, 1.0, 0.0, 0.0, 0.087,
        0.35, 0.124, -0.505, -0.258, 0.966
    ]).reshape(1, -1)

    print(f"Murkowski Prob: {model.predict(murkowski, verbose=0)}")
    # a note - voteview assigns their own probabilities to votes.
    # so even though the collins probability is usually around 90% even though she
    # voted no, it seems like, statistically, it was a surprise.
    # this was a vote that i just chose on my own - so sometimes there will be surprises!
    # i'd want to make sure that democrats aren't predicted as voting on it...
    print(f"Collins Prob: {model.predict(collins, verbose=0)}")

    # AOC: icpsr 21949, voted no, party code = 0,0, house member
    # cosponsored = 0.02082666, congresses = 0.075
    # nominate = (-0.327, -0.945)
    # here, the BBB dims are (-0.159, 0.987)
    aoc = np.array([
        0.0, 0.0, 0.0, 0.0, 0.0, 0.02082666,
        0.075, -0.327, -0.945, -0.159, 0.987
    ]).reshape(1, -1)

    # giving no chance that AOC would vote for the bill
    # so the model is allowed to go "all in" - not just wavering etc.
    print(f"AOC Prob: {model.predict(aoc, verbose=0)}")

    # the biggest thing from the 118th congress was the debt ceiling - HR3746, roll number 146
    # this was something where the "far left" and the "far right" were joined in opposition
    # Sen. Warren (icpsr 41301) was a no and Rep. Matt Gaetz (21719) were nos
    # Gaetz is also interesting to include because he was not in 119th Congress

    # Warren = (-0.744, -0.37), 0.0561733333 cosponsor, 0.125 congress
    # FRA = (0.548, 0.836), 0.0 0.0
    print("------- Fiscal Responsibility Act / Govt. Shutdown Fight of 2023 ---------")
    warren = np.array([
        0.0, 0.0, 1.0, 0.0, 0.0, 0.0561733333,
        0.125, -0.744, -0.37, 0.548, 0.836
    ]).reshape(1, -1)

    # Gaetz = (0.593, -0.643), 0.02302666 cosponsor, 0.075 congresses
    # FRA = (0.277, -0.228), 0.0 0.0
    gaetz = np.array([
        0.0, 1.0, 0.0, 0.0, 0.0, 0.02302666,
        0.075, 0.593, -0.643, 0.277, -0.228
    ]).reshape(1, -1)

    print(f"Warren Prob: {model.predict(warren, verbose=0)}")
    print(f"Gaetz Prob: {model.predict(gaetz, verbose=0)}")

    print("-------------------------")