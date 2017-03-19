## This code is for the Getting and Cleaning Data Course Project
## S. Burrell
## March 2017

## This script produces a clean dataset derived from the original data, that calculates the mean for each Subject/Activity/Sensor Reading.

setwd("~/R/DataCleaning4")
#install.packages("reshape2")
library(data.table)
library(dplyr)
library(reshape2)

#get the path to the data files
pathwd <- getwd()
pathto <- file.path(pathwd, "UCI HAR Dataset")
list.files(pathto, recursive=TRUE)

##read in the datafiles
dtSubjectTrain <- fread(file.path(pathto, "train", "subject_train.txt"))
dtSubjectTest  <- fread(file.path(pathto, "test" , "subject_test.txt" ))
dtActivityTrain <- fread(file.path(pathto, "train", "Y_train.txt"))
dtActivityTest  <- fread(file.path(pathto, "test" , "Y_test.txt" ))
dtTest  <- fread(file.path(pathto, "test" , "X_test.txt" ))
dtTrain <- fread(file.path(pathto, "train", "X_train.txt"))


#1)Merge the training and the test sets to create one data set.
#subject
dsSubject <- rbind(dtSubjectTrain, dtSubjectTest)
setnames(dsSubject, "V1", "subject")
#activity
dsActivity <- rbind(dtActivityTrain, dtActivityTest)
setnames(dsActivity, "V1", "activityNum")
#raw
ds <- rbind(dtTrain, dtTest)

#Merge columns.

dsSubject <- cbind(dsSubject, dsActivity)
ds <- cbind(dsSubject, ds)

#Set key.

setkey(ds, subject, activityNum)

#End of step 1

#2.Extracts only the measurements on the mean and standard deviation for each measurement. 

#Read the features.txt file. This tells which variables in dt are measurements for the mean and standard deviation.

dsFeatures <- fread(file.path(pathto, "features.txt"))
setnames(dsFeatures, names(dsFeatures), c("featureNum", "featureName"))

#Subset only measurements for the mean and standard deviation.

dsFeatures <- dsFeatures[grepl("mean\\(\\)|std\\(\\)", featureName)]

#Convert the column numbers to a vector of variable names matching columns in dt.

dsFeatures$featureCode <- dsFeatures[, paste0("V", featureNum)]
#head(dsFeatures)
#dsFeatures$featureCode

#Subset these variables using variable names.

select <- c(key(ds), dsFeatures$featureCode)
ds <- ds[, select, with=FALSE]

#End of step 2

#3.Uses descriptive activity names to name the activities in the data set, and...
#4.Appropriately labels the data set with descriptive variable names. 

#Read activity_labels.txt file. This will be used to add descriptive names to the activities.

dsActivityNames <- fread(file.path(pathto, "activity_labels.txt"))
setnames(dsActivityNames, names(dsActivityNames), c("activityNum", "activityName"))

#Merge activity labels.

ds <- merge(ds, dsActivityNames, by="activityNum", all.x=TRUE)

#Add activityName as a key.

setkey(ds, subject, activityNum, activityName)
#head(dts)

#Melt the data table to reshape it from a short and wide format to a tall and narrow format.

ds <- data.table(melt(ds, key(ds), variable.name="featureCode"))


#Merge activity name.

ds <- merge(ds, dsFeatures[, list(featureNum, featureCode, featureName)], by="featureCode", all.x=TRUE)

#End of step 3 and 4

#remove the duplicate columns (id's)
ds <- select(ds, subject, activityName, featureName, value)

#group up the dataset and produce an independant dataset
ds.final <- summarise(group_by(ds,subject, activityName, featureName), mean(value))
