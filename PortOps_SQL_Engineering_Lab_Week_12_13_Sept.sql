
/*==============================================================================
 ONE-ROOF DATA ENGINEERING
 PORTOPS SQL ENGINEERING LAB

 IMPORTANT NOTE
 ------------------------------------------------------------------------------
 Some concepts in this lab have NOT been fully taught in class yet.

 You may not finish every question.

 You MUST still attempt every question.

 If you get stuck:
 1. Keep your query attempt.
 2. Add a SQL comment explaining where you got stuck.
 3. State what you think you need to learn to complete it.

 Do not submit AI-generated solutions.

 ENGINEERING RULE
 ------------------------------------------------------------------------------
 Before writing each query, ask yourself:

 - What does one row represent?
 - Which table should be the driving table?
 - Why is the join needed?
 - What business meaning should NULL have?
 - What columns must be returned?
==============================================================================*/


/*==============================================================================
 QUESTION 1 — VALID CONTAINER MOVEMENTS
 ------------------------------------------------------------------------------

 Business Requirement:
 Operations wants a movement-level dataset containing only movements that can be
 matched to a valid registered container.

 Return ONLY these columns:

 - MovementID
 - ContainerID
 - ContainerNumber
 - ISOType
 - Category
 - ShippingLineID
 - MovementType
 - MovementTime
 - LocationCode

 Requirement:
 - Your query MUST use a JOIN between ContainerMovement and Container.
 - Return only movement records that have a matching container record.
 - Order the result by MovementTime from earliest to latest.

 Engineering Question:
 Which table should drive the query, and why?The ContainerMovement table should drive the query, that way we are able to identify the business requirement
 by using the movementid to identify containers containing movements.

 Write your query below.
==============================================================================*/

Select Top 10 *
From dbo.Container

Select Top 10 *
From dbo.ContainerMovement

Select CM.MovementID,C.ContainerID,C.ContainerNumber,C.ISOType,C.Category,C.ShippingLineID,CM.MovementType,CM.MovementTime,CM.FromLocation,CM.ToLocation
From dbo.Container C 
inner join dbo.ContainerMovement CM 
ON C.ContainerID = CM.ContainerID;

/*Select CM.MovementID,C.ContainerID,C.ContainerNumber,C.ISOType,C.Category,C.ShippingLineID,CM.MovementType,CM.MovementTime,CM.FromLocation,CM.ToLocation
From dbo.ContainerMovement CM 
left join dbo.Container C
ON C.ContainerID = CM.ContainerID; */ --- Used the left join to compare data quality between two queries.

/*==============================================================================
 QUESTION 2 — ALL CONTAINERS AND MOVEMENT STATUS
 ------------------------------------------------------------------------------

 Business Requirement:
 Operations wants to review ALL registered containers, whether they already have
 movement history or not.

 Return ONLY these columns:

 - ContainerID
 - ContainerNumber
 - ISOType
 - Category
 - ShippingLineID
 - MovementID
 - MovementType
 - MovementTime
 - MovementStatus

 Requirement:
 - Your query MUST use a JOIN between Container and ContainerMovement.
 - Every registered container must remain in the result.
 - Create MovementStatus using CASE:

      If MovementID is NULL      = 'NO MOVEMENT YET'
      Otherwise                  = 'MOVEMENT RECORDED'

 Engineering Question:
 What business meaning does NULL represent in this result? Means movements for these containers haven't been processed yet.

 Write your query below.
==============================================================================*/

Select Top 10 *
From dbo.Container

Select Top 10 *
From dbo.ContainerMovement

Select C.ContainerID,C.ContainerNumber,C.ISOType,C.Category,C.ShippingLineID,CM.MovementID,CM.MovementType,CM.MovementTime,
CASE 
    WHEN MovementID IS NULL THEN 'NO MOVEMENT YET'
    ELSE 'MOVEMENT RECORDED'
END AS 'MovementStatus'
From dbo.Container C
left join dbo.ContainerMovement CM
ON C.ContainerID = CM.ContainerID



/*==============================================================================
 QUESTION 3 — GATE TRANSACTIONS WITH BUSINESS-FRIENDLY OUTPUT
 ------------------------------------------------------------------------------

 Business Requirement:
 The Gate team wants every recorded gate transaction enriched with the related
 container details.

 Return ONLY these columns:

 - GateTransactionID
 - ContainerID
 - ContainerNumber
 - ISOType
 - Category
 - GateDirection ###
 - TransactionTime
 - TruckNumber
 - TruckStatus

 Requirement:
 - Your query MUST use a JOIN between GateTransaction and Container.
 - Create TruckStatus using CASE:

      If TruckNumber is NULL     = 'NO TRUCK RECORDED'
      Otherwise                  = 'TRUCK RECORDED'

 - Also use COALESCE or ISNULL so that TruckNumber itself shows
   'NO TRUCK RECORDED' instead of NULL.

 Engineering Question:
 Why might replacing NULL with a business-friendly label be useful for reports? it makes reports easier for non-technical users to understand

 Write your query below.
==============================================================================*/

Select *
From dbo.GateTransaction

Select Top 10 *
From dbo.Container

Select GT.TransactionID,GT.ContainerID,C.ContainerID,C.ISOType,C.Category,GT.LaneID,GT.TransactionTime,
COALESCE(GT.TruckPlate,'NO TRUCK RECORDED') AS TruckNumber,
GT.TruckPlate,
CASE
    WHEN GT.TruckPlate IS NULL THEN 'NO TRUCK RECORDED'
    ELSE 'TRUCK RECORDED'
END AS 'TruckStatus'
From dbo.GateTransaction GT
left join dbo.Container C
ON GT.ContainerID = C.ContainerID;


/*==============================================================================
 QUESTION 4 — MOVEMENT PROFILE BY CATEGORY
 ------------------------------------------------------------------------------

 Business Requirement:
 Operations wants to understand movement activity by movement type and container
 category.

 Return ONLY these columns:

 - MovementType
 - Category
 - TotalMovements
 - ActivityLevel

 Requirement:
 - Your query MUST join ContainerMovement to Container.
 - Group the result by MovementType and Category.
 - Return only combinations with more than 1 movement.
 - Create ActivityLevel using CASE:

      TotalMovements >= 5        = 'HIGH ACTIVITY'
      Otherwise                  = 'NORMAL ACTIVITY'

 Hint:
 You may need a concept that has not yet been fully taught.

 Engineering Question:
 Why is filtering an aggregated result different from filtering individual rows? Aggregated results shows relationsip between two or more columns, and helps in decision making for stake holders. Filtering individual rows can be used to
 make decision making, but often better for exploration.

 Write your query below.
==============================================================================*/



--USE CTE TO FIND TotalMovements 
WITH Total(ContainerID, Number_of_movements) AS
(Select ContainerID, count(ContainerID) AS Number_of_movements
From  dbo.ContainerMovement 
Group by ContainerID 
having count(ContainerID) > 1)

/*select *
from Total*/

Select CM.MovementType, C.Category, Count(T.Number_of_movements),  
CASE 
    WHEN T.Number_of_movements >= 5 THEN 'HIGH ACTIVITY'
    ELSE 'NORMAL ACTIVITY'
END AS 'ActivityLevel'

From dbo.Container AS C
left join dbo.ContainerMovement AS CM
ON C.ContainerID = CM.ContainerID
left join Total AS T
ON C.ContainerID = T.ContainerID
Group by CM.MovementType, C.Category,T.Number_of_movements; -- I think i complicated things lol


--REFINED CODE--


select top 10 *
from dbo.ContainerMovement

Select CM.MovementType, C.Category, Count(C.ContainerID) AS Total_Movements,  
CASE 
    WHEN Count(C.ContainerID) >= 5 THEN 'HIGH ACTIVITY'
    ELSE 'NORMAL ACTIVITY'
END AS 'ActivityLevel'

From dbo.Container AS C
left join dbo.ContainerMovement AS CM
ON C.ContainerID = CM.ContainerID
group by CM.MovementType, C.Category
having Count(C.ContainerID) > 1;

/*==============================================================================
 QUESTION 5 — CONTAINER SEARCH AND MOVEMENT HISTORY
 ------------------------------------------------------------------------------

 Business Requirement:
 A user remembers only part of a container number and wants to inspect its
 movement history.

 Return ONLY these columns:

 - ContainerID
 - ContainerNumber
 - Category
 - ISOType
 - MovementID
 - MovementType
 - MovementTime
 - LocationCode
 - MovementDescription

 Requirement:
 - Your query MUST join Container to ContainerMovement.
 - Search for containers where ContainerNumber contains '00'.
 - Create MovementDescription using COALESCE or ISNULL:

      If MovementType is NULL    = 'NO MOVEMENT YET'
      Otherwise                  = return MovementType

 Additional Practice:
 After your first query works, try changing the pattern to:

 - Starts with 'MSK'
 - Ends with '001'
 - Second character is 'S'

 Engineering Question:
 How is pattern searching different from filtering for an exact value?

 Write your query below.
==============================================================================*/

Select Top 10 *
From dbo.Container

Select Top 10 *
From dbo.ContainerMovement

Select C.ContainerID, C.ContainerNumber, C.Category, C.ISOType, CM.MovementID,COALESCE(CM.MovementType,'NO MOVEMENT YET') AS MovementType, CM.MovementTime, CM.FromLocation, CM.ToLocation, 
CASE
    WHEN CM.MovementType IS NULL THEN COALESCE(CM.MovementType,'NO MOVEMENT YET') 
    ELSE 'MovementType'
END AS 'MovementDescription'

From dbo.Container C
left join dbo.ContainerMovement CM
ON C.ContainerID = CM.ContainerID
Where C.ContainerNumber LIKE '%00%'
--Where C.ContainerNumber LIKE '%001'



/*==============================================================================
 QUESTION 6 — HIGH-ACTIVITY CONTAINERS
 ------------------------------------------------------------------------------

 Business Requirement:
 The Data Engineering team wants to identify containers with unusually high
 movement activity.

 Return ONLY these columns:

 - ContainerID
 - ContainerNumber
 - Category
 - MovementCount
 - FirstMovementTime
 - LastMovementTime
 - MovementActivityStatus

 Requirement:
 - Your query MUST join ContainerMovement to Container.
 - Calculate the number of movements for each container.
 - Calculate the first and last movement time.
 - Return only containers whose movement count is greater than the average
   movement count across containers.
 - Create MovementActivityStatus using CASE:

      If MovementCount is greater than the average movement count
          = 'ABOVE AVERAGE ACTIVITY'
      Otherwise
          = 'NORMAL ACTIVITY'

 Important:
 This question may require concepts that have NOT yet been fully taught.

 You may not finish it.

 You MUST attempt it and keep your attempt.

 Engineering Question:
 How can the result of one calculation be used to filter another query?

 Write your query below.
==============================================================================*/

Select Top 10 *
From dbo.Container

Select Top 10 *
From dbo.ContainerMovement


Select CM.ContainerID, C.ContainerNumber, C.Category, Count(CM.ContainerID) AS MovementCount, AVG(CM.ContainerID) AS AverageMovement,
CASE
    WHEN Count(CM.ContainerID) > AVG(CM.ContainerID) THEN 'ABOVE AVERAGE ACTIVITY'
    ELSE 'NORMAL ACTIVITY'
END AS 'MovementActivityStatus'

From dbo.Container C
Left join dbo.ContainerMovement CM
ON C.ContainerID = CM.ContainerID
Group by CM.ContainerID, C.ContainerNumber, C.Category
having CM.ContainerID IS NOT NULL;


-- My knowledge on window functions is quite rusty, i do know to solve this (Calculate the first and last movement time). We can partition, then use either row_number/ rank, but i've to go read up on it to refresh the syntax.