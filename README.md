# DS4420: Final Project

## "Predicting Congress"

#### Congress is, inherently, unpredictable.
435 members of the U.S. House and 100 members of the U.S. Senate are responsible for creating the laws of this country.
Though members as individual members have limited powers, as a group, their power is immense.

### The decisions made by Congress have powerful and lasting implications.
#### In many cases, these decisions are made narrowly.
After the 2020 Elections, the Democratic party controlled the tied U.S. Senate, with then Vice President Kamala Harris casting tiebreaking votes.
As such, the vote of every Democratic Senator was needed to pass legislation pushed by the party.

Take the example of the "Build Back Better" Act, a spending package proposed by President Biden. It passed the house
in the end of 2021 but never reached the Senate after Sen. Joe Manchin, a Democrat from West Virginia, stated he
could not support the bill.

The bill was ultimately reimagined as the "Inflation Reduction Act" in 2022, which passed the House by 13 votes -
and only passed the Senate after a tiebreaking vote.

### Being able to predict Congressional actions would be very valuable.
Trying to model the votes of lawmakers could allow us to understand their value systems and political alignments
more clearly. An explainable model could help inform citizens on a lawmaker's positions by focusing on their
actions rather than their rhetoric.

These predictions would also have financial implications as well. 
Actions taken by Congress can move markets. 
Prediction Markets would also, of course, reward making accurate predictions.

## Our Project: Predicting Congress
As many votes taken by lawmakers are public record, there are _lots_ of existing datasets focused on Congressional votes.
We will leverage this existing data to make informed predictions on how lawmakers are expected to vote on a piece of legislation.

### Part 1: Neural Network

The neural network will capture the "contextual" part of the prediction. It will accept features like party, sponsorship,
party majorities, etc. It will output a prediction between 0 and 1 for a legislator's vote on a relevant bill.

### Part 2: User-User Collaborative Filtering

We will seek to compare the existing votes of legislators to predict whether they will vote on a piece of legislation. There is 
an option to use cosine similarity or L2, but we use cosine similarity as the default metric with a default k = 10 (most similar users).
It will output a number between -1 and 1, where a negative number represents a no vote and a positive number represents a yes vote.
