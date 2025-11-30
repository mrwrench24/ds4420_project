import keras
import numpy as np

'''
Provide tuples of lawmaker names and the corresponding vector for them and 
prints out predictions for each. 
'''
def make_print_predictions(lawmakers: list[tuple[str, np.array]], model: keras.Model):
    for lawmaker, vector in lawmakers:
        pred = model.predict(vector, verbose=0)
        print(f"{lawmaker} Prob: {pred}")

'''
Print out a few votes to see *what* the model is actually outputting for them.
'''
def anecdotal_analysis(model: keras.Model, use_voteview: bool):
    lawmakers: list[tuple[str, np.array]] = []

    # -- 1. Big Beautiful Bill --
    # Lisa Murkowski (icpsr: 40300) and Susan Collins (icpsr: 49703) on the Big Beautiful Bill (HR1)
    # BBB nominate = -0.258, 0.966, 0 cosponsors of both
    # Murkowski = 0.203, -0.304, 0.0471866666 cosponsor, 0.3 congresses, voted YES (1)
    # Collins = 0.124, -0.505, 0.087 cosponsor, 0.35 congresses, voted NO (0)
    # both have party code = 0, 1
    murkowski = np.array([
        0.0, 1.0, 1.0, 0.0, 0.0, 0.0471866666,
        0.3, 0.203, -0.304, -0.258, 0.966
    ]).reshape(1, -1)

    lawmakers.append(("Lisa Murkowski (Swing YES)", murkowski))

    collins = np.array([
        0.0, 1.0, 1.0, 0.0, 0.0, 0.087,
        0.35, 0.124, -0.505, -0.258, 0.966
    ]).reshape(1, -1)

    lawmakers.append(("Susan Collins (Swing NO)", collins))

    # also want to make sure strong democrats have very very low chance of voting yes
    # voteview dimensions for bill are a bit different - they're the median value
    # of support within that chamber
    aoc = np.array([
        0.0, 0.0, 0.0, 0.0, 0.0, 0.02082666,
        0.075, -0.327, -0.945, -0.159, 0.987
    ]).reshape(1, -1)

    lawmakers.append(("AOC (Strong NO)", aoc))

    # -- 2. Fiscal Responsibilty Act --
    # the biggest thing from the 118th congress was the debt ceiling - HR3746, roll number 146
    # this was something where the "far left" and the "far right" were joined in opposition
    # Sen. Warren (icpsr 41301) was a no and Rep. Matt Gaetz (21719) were nos

    # Warren = (-0.744, -0.37), 0.0561733333 cosponsor, 0.125 congress
    # FRA = (0.548, 0.836), 0.0 0.0
    warren = np.array([
        0.0, 0.0, 1.0, 0.0, 0.0, 0.0561733333,
        0.125, -0.744, -0.37, 0.548, 0.836
    ]).reshape(1, -1)
    lawmakers.append(("Warren (NO)", warren))

    # Gaetz = (0.593, -0.643), 0.02302666 cosponsor, 0.075 congresses
    # FRA = (0.277, -0.228), 0.0 0.0
    gaetz = np.array([
        0.0, 1.0, 0.0, 0.0, 0.0, 0.02302666,
        0.075, 0.593, -0.643, 0.277, -0.228
    ]).reshape(1, -1)
    lawmakers.append(("Gaetz (NO)", gaetz))

    # -- 3. Affordable Care Act --
    # anchors - nancy pelosi a strong yes, mitch mcconnell a strong no
    pelosi = np.array([
        0.0, 0.0, 0.0, 0.0691588785046729, 0.005607476635514020,
        0.06732, 0.275, -0.489, -0.179, 0.003, -0.259
    ]).reshape(1, -1)
    lawmakers.append(("Pelosi (Strong YES)", pelosi))

    mcconnell = np.array([
        0.0, 1.0, 1.0, 0.0691588785046729, 0.005607476635514020,
        0.03762666666666670, 0.3, 0.402, 0.017, 0.003, -0.259
    ]).reshape(1, -1)
    lawmakers.append(("McConnell (Strong NO)", mcconnell))

    # Swing vote YES - Ben Nelson of Nebraska
    nelson = np.array([
        0.0, 0.0, 1.0, 0.0691588785046729, 0.005607476635514020,
        0.015013333333333300, 0.1, -0.03, 0.588, 0.003, -0.259
    ]).reshape(1, -1)
    lawmakers.append(("Nelson (Swing YES)", nelson))

    # Swing vote NO - Olympia Snowe
    snowe = np.array([
        0.0, 1.0, 1.0, 0.0691588785046729, 0.005607476635514020,
        0.07018666666666670, 0.375, 0.091, -0.548, 0.003, -0.259
    ]).reshape(1, -1)
    lawmakers.append(("Snowe (Swing NO)", snowe))

    # remove the last 4 inputs from each lawmaker if not using Voteview
    if not use_voteview:
        for i, (name, vector) in enumerate(lawmakers):
            lawmakers[i] = (name, vector[:, :7])

    make_print_predictions(lawmakers, model)