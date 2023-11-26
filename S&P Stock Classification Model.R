# Author: Stephanie Phoon


# -The data set used in the analysis is Weekly S&P Stock Market Data. The data set recorded the weekly percentage returns for the S&P 500 stock index from the year 1990 to 2010. The data set contains 1089 observations with 9 variables. 
# -The objective of the case study is to apply the supervised machine learning techniques by developing predictive models on a classification problem which determine the weekly stock market return is positive or negative. By using 3 different predictive models, the analysis could be used to evaluate and determine the best model performance.
# -In methodology, the data set would be partitioned into train and test sets. The train data set would be used to train the predictive models while the test set is used to validate and evaluate the model performance. 

### Loading required package

# Loading package
library(ggplot2)
library(caret)
library(dplyr)
library(ISLR)
library(gridExtra)


# Data Preprocessing 

data(Weekly)
str(Weekly)
summary(Weekly)


# Descriptive Analytics 

# change the variable Year and Direction to factor "1" and "0"
df <- Weekly %>% mutate(Direction=ifelse(Direction=="Up",1,0))
df$Direction = as.factor(df$Direction)
df$Year <- as.factor(df$Year)
summary(df)
str(df)

# check the missing value
sum(is.na(df)) #0 missing value 


### Remove the continuous target variable: Today

df2 <- df %>% select(-Today) #Direction as target

# Exploratory Data Analytics 
### Graph 1: Histogram of the Independent Variables


# Graph 1: Histogram of the Independent Variables
a1 <- ggplot(Weekly, aes(x=Lag1))+
  geom_histogram(position = "identity", alpha=0.5, binwidth = 0.5)
b1 <- ggplot(Weekly, aes(x=Lag2))+
  geom_histogram(position = "identity", alpha=0.5, binwidth = 0.5)
c1 <- ggplot(Weekly, aes(x=Lag3))+
  geom_histogram(position = "identity", alpha=0.5, binwidth = 0.5)
d1 <- ggplot(Weekly, aes(x=Lag4))+
  geom_histogram(position = "identity", alpha=0.5, binwidth = 0.5)
e1 <- ggplot(Weekly, aes(x=Lag5))+
  geom_histogram(position = "identity", alpha=0.5, binwidth = 0.5)
f1 <- ggplot(Weekly, aes(x=Volume))+
  geom_histogram(position = "identity", alpha=0.5, binwidth = 0.5)+
  labs(x="Volume (billions)")
grid.arrange(a1,b1,c1,d1,e1,f1,ncol=3, nrow=2)


### Graph 2: Box plot of Independent Variables

# Graph 2: Box plot of Independent Variables
a2 <- ggplot(Weekly, aes(Lag1)) + 
  geom_boxplot()
b2 <- ggplot(Weekly, aes(Lag2)) + 
  geom_boxplot()
c2 <- ggplot(Weekly, aes(Lag3)) + 
  geom_boxplot()
d2 <- ggplot(Weekly, aes(Lag4)) + 
  geom_boxplot()
e2 <- ggplot(Weekly, aes(Lag5)) + 
  geom_boxplot()
f2 <- ggplot(Weekly, aes(Volume)) + 
  geom_boxplot()+
  labs(x="Volume (billions)")
grid.arrange(a2,b2,c2,d2,e2,f2,ncol=3, nrow=2)

### Graph 3:Bar plot of Weekly Return from Year 1990 to 2010 

# Graph 3:Bar plot of Weekly Return from Year 1990 to 2010 
ggplot(Weekly, aes(x = Year, fill = Direction)) + 
  geom_bar() +
  coord_flip()+
  labs(title = "Boxplot of Weekly Return from 1990 to 2010",
       y ="Frequency", xlab= "Year")


### Graph 4: Scatter Plot between predictors and target variable

# Graph 4: Scatter Plot between predictors and target variable
a3 <- ggplot(Weekly, aes(x=Lag1, y=Today, color=Direction))+
  geom_point()+theme(legend.position = "none")
b3 <- ggplot(Weekly, aes(x=Lag2, y=Today, color=Direction))+
  geom_point()+theme(legend.position = "none")
c3 <- ggplot(Weekly, aes(x=Lag3, y=Today, color=Direction))+
  geom_point()+theme(legend.position = "none")
d3 <- ggplot(Weekly, aes(x=Lag4, y=Today, color=Direction))+
  geom_point()+theme(legend.position = "none")
e3 <- ggplot(Weekly, aes(x=Lag5, y=Today, color=Direction))+
  geom_point()+theme(legend.position = "none")
f3 <- ggplot(Weekly, aes(x=Volume, y=Today, color=Direction))+
  geom_point()+theme(legend.position = "none")+labs(x="Volume (billions)")
grid.arrange(a3,b3,c3,d3,e3,f3,ncol=3,nrow=2)

# -From Graph 1, shows that all histograms are normally distributed except for the variable 'Volume'.
# -The box plots of Lag 1 to Lag 5 have approximately similar distributions, including interquartile range, mean, and median. 
# -It shows that the histogram and box plot of 'Volume' has many outliers and are positively skewed. To obtain a normal distribution, Log transformation would be taken for this 'Volume' variable. 
# -Graph 3 illustrates the Weekly Stock Market Return from the years 1990 to 2010. Based on the graph, shows that the stock market return is approximately similar from the years 1990 to 2010 and contains a higher proportion of positive returns for every year.
# -The scatter plot depicts that there are no apparent relationships between the predictors and the target variable. It appears as two clusters, with positive return located above 0 and below 0 that is indicates a negative return. The points of variables: Lag1, Lag2, Lag3, Lag4, and Lag5 are similar that are centered at the range [-5,5]; whereas the points of Volume are mainly clustered at the lower volume of shared traded and scattered over the graph. 

### Transform the variable Volume, Log(Volume)

df2$Volume <- log(df2$Volume)


### Graph 5: Histogram of Log(Volume)

# Graph 5: Histogram of Log(Volume)
ggplot(df2,aes(x=Volume))+
  geom_histogram(binwidth = 0.1, position = "identity")+
  labs(title="Histogram of Log(Volume)")

# Predictive Modeling and Data Insights

## Data Splitting 

set.seed(100)
# Split data into training and test sets
inTrain <- createDataPartition(df2$Direction, p = 0.7, list = FALSE) #70% training and 30% testing

## Obtain Train and Test Sets
df2_train <- df2[ inTrain, ]
df2_test  <- df2[-inTrain, ]


### Data Splitting for test set   

Xtest1 <- df2_test[,-8] 
Ytest1 <- df2_test[,8]



## Model 1: Random Forest (Bagging) 

set.seed(100)
library(randomForest)
rfbag1 <- randomForest(Direction~., data = df2_train, importance=T)
rfbag1

# -The random forest model with the bagging method is developed with 500 trees and the number of try variables to each split is 2 which means each time the model has to consider 2 variables for splitting out of 7 independent variables. 
# -The OOB estimate of the error rate is 44.69% which is considered quite high.


### Validate & Evaluate the model performance with test data set 

set.seed(100)
predict_testRFbag1 <- predict(rfbag1, newdata = Xtest1)
table2rfbag1 <- table(predict_testRFbag1, Ytest1)
confusionMatrix(table2rfbag1, positive = "1")

#Relative Importance of Predictors 
importance(rfbag1)
varImpPlot(rfbag1)

## Model 2: Random Forest (Gradient Boosting Machine)

set.seed(100)
library(gbm)

#R gbm with distribution = "adaboost" can be used for 0-1 classification problem
modelGBM=gbm(as.character(Direction)~.,data=df2_train,n.trees=500,
             distribution='adaboost',interaction.depth=6,shrinkage=0.1)
#set the interaction depth to six, which allows for sixth order interactions

#Relative Importance of Predictors 
summary(modelGBM)

### Validate & Evaluate the model performance with test data set  

pgbm=predict(modelGBM,newdata=Xtest1,n.trees = 500,type='response')
pgbm[pgbm>0.5]=1
pgbm[pgbm<=0.5]=0
confusionMatrix(as.factor(Ytest1),as.factor(pgbm), positive = "1")

# -The Model 2: Gradient Boosting Machine has higher accuracy and balanced accuracy compared to Model 1: Random Forest with Bagging. 

## Model 3: Logistic Regression 

set.seed(100)
# Training model
logistic_model <- glm(Direction ~ ., data = df2_train, family = "binomial")

# Summary
summary(logistic_model)

### Validate & Evaluate the model performance with test data set 

# Predict test data based on model
predict_reg <- predict(logistic_model, Xtest1, type = "response")

# Changing probabilities
predict_reg <- ifelse(predict_reg >0.5, 1, 0)

# Evaluating model accuracy

# using confusion matrix
conf <- table(predict_reg,Ytest1)
confusionMatrix(conf, positive= "1")  
# or 
missing_classerr <- mean(predict_reg != Ytest1)
print(paste('Accuracy =', 1 - missing_classerr))

library(ROCR)
library(caTools)

# Area Under the Curve - AUC
ROCPred <- prediction(predict_reg, Ytest1) 
ROCPer <- performance(ROCPred, measure = "tpr", 
                      x.measure = "fpr")

auc <- performance(ROCPred, measure = "auc")
auc <- auc@y.values[[1]]
auc

# -In this case study, there is a total of 3 predictive models are used: Random Forest with Bagging method, Random Forest with Gradient Boosting Machine, and Logistic Regression to classify the Weekly S&P Stock Market Return.
# -Based on the measure of Balanced Accuracy, the best model performance is Gradient Boosting Machine, followed by Logistic Regression and Random Forest with Bagging. The higher the balanced accuracy, the better the model fit. 

