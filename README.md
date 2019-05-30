# Objective
The objective of the exercise is to build a binary classification model that assigns a probabiltiy of conversion of a lead to subscribe to a digital learning management product. The data is not shared in the repository for confidentiality

# Packages Required
The following packages 
  1. ROCR
  2. pROC
  3. WVPlots
  4. vtreat
  5. ggplot2

# Flow
## Data understanding 
The fields in the data are
  1. Schools organisation number
  2. Opportunities Assigned to (The person who pursued the opportunity)
  3. Opportunities District
  4. Schools.Market

Exploratory analysis is conducted to understand the dataset. Missing values for age are replaced with the median age values

## Data type conversion
The following variables are converted to the data type (factor) to make them categorical
 1. The independent varaible - Closed
 2. Opportunities Region
 3. Opportunities District
 4. Schools Market
 5.Type of Schools


## Defining the model 
The model was defined as follows, 
Closed~Opportunities.CE.Region+Schools.Type.of.School+School.LKG.Fees+School.Grade.5.Fees+School.Strength

## Test train split
K- way cross validation is used with a k value of 3 to ensure maximum utilisation of the available training data

## Evaluation of the model

For this use case, the cost of classifying a potential lead as not a lead is higher compared to classifying a lead that is less likely to convert as a potential lead. For this reason the threshold value is fixed to achieve a higher sensitivity value.
The evaluation metrics calculated for the model is listed in the below section

## Evaluation Metrics
  1. Accuracy = 78.5%
  2. sensitivity = 71.2%
  3. specificity = 97.5%
  4. Area under the curve= 0.93

## Interpretation
Based on the model summary, it is found the the variables that have significant impact on the survival of the passengers are

  1. Region
      -Chances of conversion is less in 2 specific regions (1. TN4 and RON - Rest of North region)

  2. Type of School
      -Conversion rate is significantly less in State Board schools comparted to that of the other boards

  3. School strength
      -Probability of conversion comes down as the school strength increases
