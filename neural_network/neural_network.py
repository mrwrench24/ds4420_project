import uuid
import os

import pandas as pd
import matplotlib.pyplot as plt

from tensorflow.keras.models import Model
from tensorflow.keras.losses import binary_crossentropy
from tensorflow.keras.layers import Dense, Input
from tensorflow.keras.optimizers import Adam
from sklearn.model_selection import train_test_split

from anecdotal_analysis import anecdotal_analysis

INPUT_COLUMNS = [
    "party_code_1", "party_code_2", "chamber",
    "dem_cosponsors", "rep_cosponsors",
    "pieces_cosponsored", "num_congresses",
    # member's dimensions
    "nominate_dim1", "nominate_dim2",
    # bill's dimensions
    "nominate_mid_1", "nominate_mid_2"
]

INPUT_COLUMNS_NO_VV = [
    "party_code_1", "party_code_2", "chamber",
    "dem_cosponsors", "rep_cosponsors",
    "pieces_cosponsored", "num_congresses"
]

OUTPUT_COLUMN = "vote"

'''
Creates a model for the provided number of features (one-dimensional).
'''
def make_model(num_input_features: int) -> Model:
    inpx = Input(shape=(num_input_features,))

    hid_layer = Dense(32, activation='relu')(inpx)
    hid_layer2 = Dense(48, activation='relu')(hid_layer)
    hid_layer3 = Dense(48, activation='relu')(hid_layer2)
    hid_layer4 = Dense(32, activation='relu')(hid_layer3)

    out = Dense(1, activation='sigmoid')(hid_layer4)

    model = Model([inpx], out)

    model.compile(optimizer=Adam(learning_rate=0.0015),
                  # AKA Log loss
                  loss=binary_crossentropy,
                  # use accuracy and mse cautiously
                  metrics=['accuracy', 'mse', 'auc'])

    return model

'''
Trains a Neural Network using the information in the provided NN file paths.
The network is trained for the provided number of epochs and either uses voteview dimensions
(for lawmakers and median leg. support) or not. The dimensions / composition of the model is fixed. 

Saves the model, relevant plots, and the anecdotal analysis to a folder in ./runs/{UUID}/
'''
def run_nn(nn_file_paths: list[str], use_voteview: bool, num_epochs: int):
    run_id = str(uuid.uuid1())
    os.makedirs(f'./runs/{run_id}', exist_ok=True)
    print("Run ID: ", run_id)

    data_df = pd.DataFrame()

    for file_path in nn_file_paths:
        current_df = pd.read_csv(file_path)

        data_df = pd.concat([data_df, current_df], ignore_index=True)

    train_data, test_data = train_test_split(data_df, test_size=0.2)

    columns = INPUT_COLUMNS if use_voteview else INPUT_COLUMNS_NO_VV

    X_train = train_data[columns]
    X_test = test_data[columns]

    Y_train = train_data[OUTPUT_COLUMN]
    Y_test = test_data[OUTPUT_COLUMN]

    # always checking for some class imbalance
    print(Y_train.value_counts())
    print(Y_test.value_counts())

    model = make_model(len(columns))
    training = model.fit(X_train, Y_train, epochs=num_epochs)

    plt.plot(training.history['accuracy'], label='accuracy')
    plt.plot(training.history['mse'], label='mse')
    plt.plot(training.history['auc'], label='auc')
    plt.title("Training Metrics at Epoch")
    plt.legend()
    plt.savefig(f'./runs/{run_id}/extra_metrics.png', dpi=300)

    plt.clf()
    plt.plot(training.history['loss'], label='loss')
    plt.title("Loss (BCE / Log-Loss) at Epoch")
    plt.savefig(f'./runs/{run_id}/loss.png', dpi=300)

    score = model.evaluate(X_test, Y_test)

    with open(f'./runs/{run_id}/test_info.txt', 'w') as test_info_file:
        test_info_file.write(f"Test Binary Cross-Entropy: {score[0]}")
        test_info_file.write(f"\nTest Accuracy: {score[1]}")
        test_info_file.write(f"\nTest MSE: {score[2]}")
        test_info_file.write(f"\nTest AUC: {score[3]}")

        anecdotal_analysis(model, test_info_file, use_voteview=use_voteview)

    preds = model.predict(X_test)

    plt.clf()
    plt.hist(preds, bins=20)
    plt.title(f"Distribution of Test Predictions: Yes = {Y_test.value_counts()[1]}, Nos = {Y_test.value_counts()[0]}")
    plt.savefig(f'./runs/{run_id}/predictions_hist.png', dpi=300)

    model.save(f"./runs/{run_id}/model.keras")

run_nn([
    "../datafiles/NN_files/NN_HOUSE_107.csv",
    "../datafiles/NN_files/NN_SENATE_107.csv",
    "../datafiles/NN_files/NN_HOUSE_108.csv",
    "../datafiles/NN_files/NN_SENATE_108.csv",
    "../datafiles/NN_files/NN_HOUSE_109.csv",
    "../datafiles/NN_files/NN_SENATE_109.csv",
    "../datafiles/NN_files/NN_HOUSE_110.csv",
    "../datafiles/NN_files/NN_SENATE_110.csv",
    "../datafiles/NN_files/NN_HOUSE_111.csv",
    "../datafiles/NN_files/NN_SENATE_111.csv",
    "../datafiles/NN_files/NN_HOUSE_112.csv",
    "../datafiles/NN_files/NN_SENATE_112.csv",
    "../datafiles/NN_files/NN_HOUSE_113.csv",
    "../datafiles/NN_files/NN_SENATE_113.csv",
    "../datafiles/NN_files/NN_HOUSE_114.csv",
    "../datafiles/NN_files/NN_SENATE_114.csv",
    "../datafiles/NN_files/NN_HOUSE_115.csv",
    "../datafiles/NN_files/NN_SENATE_115.csv",
    "../datafiles/NN_files/NN_HOUSE_116.csv",
    "../datafiles/NN_files/NN_SENATE_116.csv",
    "../datafiles/NN_files/NN_HOUSE_117.csv",
    "../datafiles/NN_files/NN_SENATE_117.csv",
    "../datafiles/NN_files/NN_HOUSE_118.csv",
    "../datafiles/NN_files/NN_SENATE_118.csv",
    "../datafiles/NN_files/NN_HOUSE_119.csv",
    "../datafiles/NN_files/NN_SENATE_119.csv"
], use_voteview=True, num_epochs=5)

