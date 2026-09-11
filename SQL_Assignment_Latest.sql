SELECT *
FROM dbo.VesselCall

/*TASK 1: Understand the Size of the Source
 Return the total number of records separately for:
   dbo.VesselCall
   dbo.Container
   dbo.ContainerMovement
   dbo.DataLoadLog
 ENGINEERING QUESTION:
 Why would row volume matter when deciding how to load data?*/

 --YOUR QUERY HERE:

--total number of records separately for dbo.VesselCall: --
 Select Count(*) AS TOTAL_ROWS
 FROM dbo.VesselCall;
 Reasoning - Using the Count Function alongside the * gives me the total number of rows in the table.

-- total number of records separately for dbo.Container
Select Count(*) AS TOTAL_ROWS
FROM dbo.Container;

-- total number of records separately for dbo.ContainerMovement
Select Count(*) AS TOTAL_ROWS
FROM dbo.ContainerMovement;

-- total number of records separately for dbo.DataLoadLog
Select Count(*) AS TOTAL_ROWS
FROM dbo.DataLoadLog;

/*Why would row volume matter when deciding how to load data? Row Volume is important especially for batch loading, whether loading data incrementally, or full load. We need to know the total 
volume of the data going into the target.*/



-- TASK 2: Understand the Container Data Coverage
 /*Determine:
   - Earliest CreatedAt                 
   - Latest CreatedAt
   - Total number of containers
 from dbo.Container.
 ENGINEERING QUESTION:
 What period of source data are we dealing with?*/

 YOUR QUERY HERE:

--Earliest CreatedAt
Select min(CreatedAt) AS Minimum
From dbo.Container;  

-- Latest CreatedAt
Select max(CreatedAt) AS Maximum
From dbo.Container;

-- Total number of containers
Select Count(ContainerNumber) AS TOTAL_CONTAINER
From dbo.Container;




/* TASK 3: Understand the Movement Data Coverage
 Determine:
   - Earliest MovementTime
   - Latest MovementTime
   - Total number of movements
 from dbo.ContainerMovement.
 ENGINEERING QUESTION:
 Does the movement history cover the same period as the
 container master data?*/

 -- YOUR QUERY HERE:

 -- Earliest MovementTime
     Select Min(MovementTime) AS Earliest_Time
     From dbo.ContainerMovement
 -- Latest MovementTime
     Select Max(MovementTime) AS Latest_Time
     From dbo.ContainerMovement
 -- Total number of movements
     Select Count(MovementID) AS Number_of_Movements
     From dbo.ContainerMovement

TASK 4: Mandatory Weight Check
 GrossWeightKG is required for the destination dataset.
 Find all containers where GrossWeightKG is NULL.
 Return:
   ContainerID
   ContainerNumber
   ISOType
   Category
   ShippingLineID
 Then write a second query showing the total number affected.
 ENGINEERING QUESTION:
 Would you load these records?
 If yes, how would you treat them?
 If no, what happens to them?

 a) Detail records:
 YOUR QUERY HERE:
Select ContainerID, ContainerNumber, ISOType,Category, ShippingLineID
From dbo.Container
Where GrossWeightKG IS NULL;

 b) Count:
 YOUR QUERY HERE:
SELECT COUNT(*) AS NUMBER_AFFECTED
FROM 
(Select ContainerID, ContainerNumber, ISOType,Category, ShippingLineID
From dbo.Container
Where GrossWeightKG IS NULL) AS FILTERED

 USING CTE TO SOLVE THIS
WITH DIFF AS (Select ContainerID, ContainerNumber, ISOType,Category, ShippingLineID
From dbo.Container
Where GrossWeightKG IS NULL)

SELECT COUNT(*) AS NUMBER_AFFECTED
FROM DIFF;

 Would you load these records?
 If yes, how would you treat them? I would load the data,but would not ignore the null data, but intead investigate reason why its null, and
 possibly undergo backfilling.
 If no, what happens to them?



 TASK 5: Container Number Uniqueness
 The business expects ContainerNumber to identify a physical
 container.
 Find ContainerNumbers that occur more than once.
 Return:
   ContainerNumber
   Occurrences
 ENGINEERING QUESTION:
 Does a repeated ContainerNumber automatically mean that
 the data is wrong? No,it doesn't mean the data is wrong, it just means the containerNumber occured more than once. Duplicate is when entire value 
  is consistent/duplicated in all the rows of the table.

-- YOUR QUERY HERE:
Select ContainerID, ContainerNumber, COUNT(ContainerNumber) AS OCCURENCES
From dbo.Container
Group by ContainerID,ContainerNumber


 TASK 6: Vessel Call Integrity
 A vessel cannot physically depart before it arrives.
 Find VesselCall records where ATD < ATA.
 Return:
   CallID
   VoyageNumber
   ETA
   ATA
   ATD
   CallStatus
 ENGINEERING QUESTION:
 What should happen to these records during a production load?

Query

Select CallID,VoyageNumber, ETA, ATA, ATD, CallStatus
From dbo.VesselCall
Where ATD < ATA;

Select *
From dbo.VesselCall


 TASK 7: Incomplete Vessel Calls
 Identify vessel calls where ATA IS NULL.
 Return:
   CallID
   VoyageNumber
   ETA
   ATA
   ATD
   CallStatus
 ENGINEERING QUESTION:
 Is NULL ATA necessarily a data-quality problem?
 Explain.

 YOUR QUERY HERE:

Select CallID,VoyageNumber, ETA, ATA, ATD, CallStatus
From dbo.VesselCall
Where ATA IS NULL;



 TASK 8: Container -> Movement Relationship
 Every ContainerMovement should reference an existing
 ContainerID.
 Find movements that reference a ContainerID that does not
 exist in dbo.Container.
 Return:
   MovementID
   ContainerID
   MovementType
   MovementTime
 ENGINEERING QUESTION:
 What problem could this create after loading the data into
 an analytical platform? ContainerID that hasn't undergone further processing(Shipment), and has been logged on as being processed. This can cause inconsistent data for stakeholders.
 STUCK-POINT NOTE:
 Where did you get stuck, or what would you need to learn? I knew the type of join to use, but got stuck in the filter to use. Used <>, and NOT IN, before LLM gave me a clue to use IS NULL.

 YOUR QUERY HERE:  

 Select CM.MovementID, CM.ContainerID, CM.MovementType, CM.MovementTime
 From dbo.ContainerMovement AS CM
 left join dbo.Container AS C
 ON CM.ContainerID = C.ContainerID
 Where C.ContainerID IS NULL;


 
-- TASK 9: Containers With No Movement History
-- Find containers that exist in dbo.Container but have no
-- corresponding record in dbo.ContainerMovement.
-- Return:
--   ContainerID
--   ContainerNumber
--   ISOType
--   Category
-- ENGINEERING QUESTION:
-- Is this automatically an error?
-- What business clarification would you request?
-- STUCK-POINT NOTE:

-- YOUR QUERY HERE:

 Select C.ContainerID, C.ContainerNumber, C.ISOType,C.Category
 From dbo.Container AS C
 left join dbo.ContainerMovement AS CM
 ON C.ContainerID = CM.ContainerID
 WHERE CM.ContainerID IS NULL;


 -- TASK 10: Movement Enrichment
-- Operations wants movement data that users can understand
-- without separately looking up the container master table.
-- Combine:
--   dbo.ContainerMovement
--   dbo.Container
-- Return:
--   MovementID
--   ContainerID
--   ContainerNumber
--   ISOType
--   Category
--   MovementType
--   MovementTime
-- ENGINEERING QUESTION:
-- What has changed about the dataset after combining these tables?
-- What does one row now represent?
-- STUCK-POINT NOTE:

-- YOUR QUERY HERE:

Select CM.MovementID, CM.ContainerID, C.ContainerNumber, C.ISOType, C.Category, CM.MovementType, CM.MovementTime
From dbo.ContainerMovement CM
inner join dbo.Container C
ON CM.ContainerID = C.ContainerID;

-- What has changed about the dataset after combining these tables? Its now showing combined results from two tables. I used an inner join, so its showing peculiar result of data that is related to the two tables.
-- What does one row now represent? Each row represent the lifecycle of the container, from movement to current status of the container.



-- TASK 11: Vessel Arrival Variance
-- Create a new calculated column:
--   ArrivalVarianceMinutes
-- This should show the difference between ETA and ATA in minutes.
-- Only use records where both ETA and ATA exist.
-- Return:
--   CallID
--   VoyageNumber
--   ETA
--   ATA
--   ArrivalVarianceMinutes
-- ENGINEERING QUESTION:
-- What does a positive value mean?
-- What does a negative value mean?
-- STUCK-POINT NOTE: 

-- YOUR QUERY HERE:
Select *
From dbo.VesselCall

Select CallID, VoyageNumber, ETA, ATA, CAST((ATA - ETA) AS MINUTE) AS ArrivalVarianceMinutes
From dbo.VesselCall
Where ETA IS NOT NULL AND ATA IS NOT NULL;

STUCK-POINT NOTE: Getting the difference in minutes.