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

    model.compile(optimizer=Adam(learning_rate=0.001),
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
    print(f"Collins Prob: {model.predict(collins)}")


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

    print(Y_train.value_counts())
    print(Y_test.value_counts())

    model = make_model()

    model.fit(X_train, Y_train, epochs=40)

    score = model.evaluate(X_test, Y_test)
    print(score)

    anecdotal_analysis(model)

run_nn(["../datafiles/NN_HOUSE_119.csv", "../datafiles/NN_SENATE_119.csv"])