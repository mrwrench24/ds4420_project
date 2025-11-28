import streamlit as st
import pandas as pd
import altair as alt

# no data right now, but we can add this later
data = pd.DataFrame({
    'member_id': [1, 2, 3, 4, 5],
    'bill_id': [101, 102, 103, 104, 105],
    'predicted_vote': ['Yea', 'Nay', 'Yea', 'Nay', 'Yea'],
})

# streamlit tabs
tabs = st.tabs(["Landing Page", "Results Table"])

# Landing page
with tabs[0]:
    st.title("Predicting Legislators' Votes Using Neural Networks")
    st.markdown("""
                This project aims to predict how legislators will vote on bills using neural networks. We
                extract features for bills and members from VoteView, which include party, ideological points, and other
                relevant information. Additional data is taken from Congress.gov API to enhance our model as well.""")
    st.markdown("""
                The model is trained on historical voting data, and we evaluate its performance using accuracy metrics.
                The results are visualized in the subsequent tab.""")
    st.markdown("""
                This is a collaboration between Jake Squatrito and Armina Parvaresh Rizi for DS 4420 Final Project.""")

# Interactive results table
with tabs[1]:
    st.subheader("Results Visualization")

    # table with results
    st.dataframe(data)