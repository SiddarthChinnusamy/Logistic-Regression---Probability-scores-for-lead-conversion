## Setting working directory
setwd("D:/Xseed Max sales data")

## Importing necessary libraries
library(ggplot2)
require(openxlsx)
library(data.table)
library(dplyr)
library(Amelia)
library(outliers)
library(vtreat)
library(ROCR)
library(WVPlots)

## Reading input data
year1c<-read.xlsx("2D MAX data.xlsx")
year2c<-read.xlsx("3A MAX Data.xlsx")
year2uc<-read.xlsx("3A MAX S21.xlsx")

## Understanding the data
x<-colnames(year1c)
y<-colnames(year2c)
z<-colnames(year2uc)

## Combining Year 2 data
year2c1<-data.frame()
year2c1<-year2c[ ,!colnames(year2c) %in% c("Opportunities.MAX.Amount","Opportunities.MAX.Kids","Opportunities.Type.of.Inventory")]
head(year2c1)

year2uc1<-data.frame()
year2uc1<-year2uc[ ,!colnames(year2uc)%in% c("Opportunities.Lost.Reason")]
head(year2uc1)

year2<-rbind(year2c1,year2uc1)
head(year2)
nrow(year2)

#Missing Values
missmap(year2)

# Taking only rows with all values
year2<-na.omit(year2)
missmap(year2)
unique(year2$Schools.Type.of.School)

# Changing column names
setnames(year2,"Schools.Kids.Strength.Nu-G8","School.Strength")

#Substituting values marked 0 as NA and replacing with average valuesfor LKG fee
year2$School.LKG.Fees[year2$School.LKG.Fees=="0"]<-NA

is.na(year2$School.LKG.Fees)
year2<-year2 %>%
  group_by(Schools.Type.of.School,Opportunities.CE.Region)%>%
  mutate(School.LKG.Fees=ifelse(is.na(School.LKG.Fees),mean(School.LKG.Fees,na.rm=TRUE),School.LKG.Fees))
  
#Substituting values marked 0 as NA and replacing with average values for std.5 Fee
year2$School.Grade.5.Fees[year2$School.Grade.5.Fees=="0"]<-NA

year2<-year2 %>%
  group_by(Schools.Type.of.School,Opportunities.CE.Region)%>%
  mutate(School.Grade.5.Fees=ifelse(is.na(School.Grade.5.Fees),mean(School.Grade.5.Fees,na.rm=TRUE),School.Grade.5.Fees))
  year2$School.Grade.5.Fees<-scale(year2$School.Grede.5.Fees)
  
#Substituting values marked 0 as NA and replacing with average values for std.5 Fee
year2$School.Strength[year2$School.Strength=="0"]<-NA

year2<-year2 %>%
  group_by(Schools.Type.of.School,Opportunities.CE.Region)%>%
  mutate(School.Strength=ifelse(is.na(School.Strength),mean(School.Strength,na.rm=TRUE),School.Strength))
  year2$School.Strength<-scale(year2$School.Strength)
  

# checking for outliers
year2<-year2[year2$School.LKG.Fees!="5002200",]
nrow(year2)

# Baseline Accuracy
table(year2$Closed)
print(258/(718+258))


## Logistic regression model to assign a probability of conversion for a new lead
# Changing data types
sapply(year2,class)
year2$Opportunities.Assigned.To<-as.factor(year2$Opportunities.Assigned.To)
year2$Opportunities.District<-as.factor(year2$Opportunities.District)
year2$Schools.Market<-as.factor(year2$Schools.Market)
year2$Opportunities.CE.Region<-as.factor(year2$Opportunities.CE.Region)
year2$Schools.Type.of.School<-as.factor(year2$Schools.Type.of.School)
year2$Opportunities.Sales.Stage<-as.factor(year2$Opportunities.Sales.Stage)
year2$Closed<-as.factor(year2$Closed)


# Visual analysis (Univariate relationship)
ggplot(year2,aes(x=School.LKG.Fees))+geom_histogram(binwidth=20000,fill="palegreen4",col="green")
ggsave("LKG.Fees.png")
ggplot(year2,aes(x=School.Grade.5.Fees))+geom_histogram(bins=20000,fill="palegreen4",col="green")
ggsave("Grade5.Fees")
ggplot(year2,aes(x=School.Strength))+geom_histogram(bins=10,fill="palegreen4",col="green")+geom_label()


# Visual analysis (Relationship between categorical variables and school closure)
ggplot(year2,aes(x=Opportunities.CE.Region,..count..))+geom_bar(aes(fill=Closed),position="fill")
ggplot(year2,aes(x=Opportunities.CE.Region))+geom_bar()
                                                      
ggplot(year2,aes(x=Schools.Type.of.School,..count..))+geom_bar(aes(fill=Closed),position="fill")
ggplot(year2,aes(x=Schools.Type.of.School,..count..))+geom_bar()  

ggplot(year2,aes(x=School.LKG.Fees,y=Closed,color=Closed))+geom_point()
ggplot(year2,aes(x=School.Grade.5.Fees,y=Closed,color=Closed))+geom_point()

ggplot(year2,aes(x=Opportunities.Sales.Stage,..count..))+geom_bar(aes(fill=Closed),position="fill")
ggplot(year2,aes(x=Opportunities.Sales.Stage,..count..))+geom_bar()


##Training model by cross validation
formula<-Closed~Opportunities.CE.Region+Schools.Type.of.School+School.LKG.Fees+School.Grade.5.Fees+School.Strength
n<-nrow(year2)
splitPlan<-kWayCrossValidation(n,3,NULL,NULL)
str(splitPlan)
K<-3
year2$pred.cv<-0

for(i in 1:K)
  {
  split<-splitPlan[[i]]
  model<-glm(formula,data=year2[split$train, ],family=binomial())
  year2$pred.cv[split$app]<-predict(model,newdata=year2[split$app, ],type="response")
}

##Model Results
summary(model)
year2$pred.cv

#confusion matrix
cm<-table(actual=year2$Closed,predicted=year2$pred.cv>0.5)
cm

#Derived metrics
accuracy<-(cm[1,1]+cm[2,2])/(cm[1,1]+cm[2,2]+cm[1,2]+cm[2,1]);accuracy
sensitivity<-(cm[2,2])/(cm[2,1]+cm[2,2]);sensitivity
specificity<-(cm[1,1])/(cm[1,1]+cm[1,2]);specificity

# ROC Curve
pred2 <- prediction(year2$pred.cv, year2$Closed)
roc.perf <- performance(pred2, measure = "tpr", x.measure = "fpr")
plot(roc.perf,colorize=TRUE,print.cutoffs.at=seq(0.1,by=0.1))
roc.auc<-performance(pred2,measure="auc")
roc.auc@y.values[[1]]



