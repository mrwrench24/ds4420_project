import pandas as pd

from tensorflow.keras.models import Model
from tensorflow.keras.losses import binary_crossentropy
from tensorflow.keras.layers import Dense, Input
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.metrics import BinaryCrossentropy

from sklearn.model_selection import train_test_split

import numpy as np

# trying to have them in the same order as described in the nn_preprocess blurb

INPUT_COLUMNS = [
    "party_code_1", "party_code_2", "chamber",
    "dem_cosponsors", "rep_cosponsors",
    "pieces_cosponsored", "num_congresses",
    # member's dimensions
    "nominate_dim1", "nominate_dim2",
    # bill's dimensions
    "nominate_mid_1", "nominate_mid_2"
]

OUTPUT_COLUMN = "vote"

def make_model() -> Model:
    inpx = Input(shape=(11,))

    hid_layer = Dense(32, activation='relu')(inpx)
    hid_layer2 = Dense(48, activation='relu')(hid_layer)
    hid_layer3 = Dense(48, activation='relu')(hid_layer2)
    hid_layer4 = Dense(32, activation='relu')(hid_layer3)

    out = Dense(1, activation='sigmoid')(hid_layer4)

    model = Model([inpx], out)

    model.compile(optimizer=Adam(learning_rate=0.0008),
                  loss=binary_crossentropy,
                  # accuracy is probably not the best, but i want to see how it does? for now?
                  metrics=[
                      'accuracy'
                  ])

    return model

'''
Print out a few votes to see *what* the model is actually outputting for them.
'''
def anecdotal_analysis(model):
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

    print(f"Murkowski Prob: {model.predict(murkowski)}")
    # a note - voteview assigns their own probabilities to votes.
    # so even though the collins probability is usually around 90% even though she
    # voted no, it seems like, statistically, it was a surprise.
    # this was a vote that i just chose on my own - so sometimes there will be surprises!
    # i'd want to make sure that democrats aren't predicted as voting on it...
    print(f"Collins Prob: {model.predict(collins)}")

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
    print(f"AOC Prob: {model.predict(aoc)}")

    print("----------------")

    # the biggest thing from the 118th congress was the debt ceiling - HR3746, roll number 146
    # this was something where the "far left" and the "far right" were joined in opposition
    # Sen. Warren (icpsr 41301) was a no and Rep. Matt Gaetz (21719) were nos
    # Gaetz is also interesting to include because he was not in 119th Congress

    # Warren = (-0.744, -0.37), 0.0561733333 cosponsor, 0.125 congress
    # FRA = (0.548, 0.836), 0.0 0.0
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

    print(f"Warren Prob: {model.predict(warren)}")
    print(f"Gaetz Prob: {model.predict(gaetz)}")


def run_nn(nn_file_paths: list[str]):
    data_df = pd.DataFrame()

    for file_path in nn_file_paths:
        current_df = pd.read_csv(file_path)

        data_df = pd.concat([data_df, current_df], ignore_index=True)

    train_data, test_data = train_test_split(data_df, test_size=0.2)

    X_train = train_data[INPUT_COLUMNS]
    X_test = test_data[INPUT_COLUMNS]

    Y_train = train_data[OUTPUT_COLUMN]
    Y_test = test_data[OUTPUT_COLUMN]

    # always checking for some class imbalance
    print(Y_train.value_counts())
    print(Y_test.value_counts())

    model = make_model()

    model.fit(X_train, Y_train, epochs=250)

    score = model.evaluate(X_test, Y_test)
    print(f"Test Binary Cross-Entropy: {score[0]}")
    print(f"Test Accuracy: {score[1]}")

    anecdotal_analysis(model)

run_nn([
    "../datafiles/NN_HOUSE_118.csv",
    "../datafiles/NN_SENATE_118.csv",
    "../datafiles/NN_HOUSE_119.csv",
    "../datafiles/NN_SENATE_119.csv"
])