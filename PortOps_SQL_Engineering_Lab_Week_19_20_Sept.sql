/*==============================================================================
 ONE-ROOF DATA ENGINEERING
 PORTOPS SQL ENGINEERING LAB
 Week: 19-20 September

 File: PortOps_SQL_Engineering_Lab_Week_19_20_Sept.sql

 IMPORTANT NOTE
 ------------------------------------------------------------------------------
 This lab is designed to reinforce concepts practiced during the week:

 - CTE
 - Subquery
 - ROW_NUMBER() OVER()
 - VIEW
 - GROUP BY
 - HAVING
 - Aggregate Functions
 - JOIN reasoning

 ENGINEERING RULE
 ------------------------------------------------------------------------------
 Before writing each query, ask yourself:

 - What does one row represent?
 - Which table carries the weight of the business question?
 - Which table should be the driving table?
 - Why is the JOIN needed?
 - What rows must survive the JOIN?
 - What columns must be returned?
 - Am I summarizing rows or preserving row-level detail?

 Do not write SQL only to make it run.
 The query must answer the business question correctly.
==============================================================================*/


/*==============================================================================
 QUESTION 1 - LATEST MOVEMENT PER CONTAINER
 ------------------------------------------------------------------------------

 Business Requirement:
 Operations wants to know the latest recorded movement for every container that
 has movement history.

 Return ONLY these columns:

 - ContainerID
 - ContainerNumber
 - Category
 - MovementID
 - MovementType
 - MovementTime
 - LocationCode

 Requirements:
 - ContainerMovement must carry the business question.
 - Join ContainerMovement to Container.
 - Use a CTE.
 - Use ROW_NUMBER() OVER().
 - Partition by ContainerID.
 - Order the window so that the latest movement receives row number 1.
 - Return only the latest movement per container.

 Engineering Question:
 Why is ROW_NUMBER() more suitable than GROUP BY when the requirement is to
 return the full latest movement row? Row_number is suitable than Group by because it will show the occurence of each containerID, as opposed to aggregarting them, and therefore, we can get the latest movement.

 Write your query below.
==============================================================================*/
Select top 10 *
from dbo.Container

Select top 10 *
from dbo.ContainerMovement


WITH Latest AS (
Select C.ContainerID, C.ContainerNumber, C.Category, CM.MovementID, CM.MovementType, CM.MovementTime,CM.FromLocation,CM.ToLocation, ROW_NUMBER() OVER (PARTITION BY CM.ContainerID ORDER BY CM.MovementTime DESC) AS LatestMovement
from dbo.ContainerMovement AS CM
inner join  dbo.Container AS C
ON CM.ContainerID = C.ContainerID)

Select * From Latest Where LatestMovement = 1 OR LatestMovement < 2;

/*A learning approach: I noticed that when i didn't fulfil one of the requirement of order by latest window (desc), i wasnt able to filter based off the latest. Secondly, ContainerID 1, has a latest movement of 6th jan, but that doesn't 
show up as the latest.*/



/*==============================================================================
 QUESTION 2 - FIRST AND LATEST MOVEMENT COMPARISON
 ------------------------------------------------------------------------------

 Business Requirement:
 Operations wants to identify containers whose latest movement happened more
 than 24 hours after their first recorded movement.

 Return ONLY these columns:

 - ContainerID
 - ContainerNumber
 - FirstMovementTime
 - LastMovementTime
 - MovementDurationHours

 Requirements:
 - Use a subquery.
 - The subquery must calculate:
      MIN(MovementTime) AS FirstMovementTime
      MAX(MovementTime) AS LastMovementTime
 - Aggregate at ContainerID level.
 - Join the aggregated result to Container.
 - Calculate MovementDurationHours.
 - Return only containers where MovementDurationHours is greater than 24.
 - Order the result from the longest duration to the shortest.

 Engineering Question:
 What does one row represent after the aggregation?

 Write your query below.
==============================================================================*/

Select top 10 *
from dbo.Container

Select top 10 *
from dbo.ContainerMovement


SELECT C.ContainerID, C.ContainerNumber, FirstMovementTime, LastMovementTime, DATEDIFF(Hour,FirstMovementTime,LastMovementTime) AS MovementDurationHour
FROM
(Select ContainerID, MIN(MovementTime) AS FirstMovementTime, MAX(MovementTime) AS LastMovementTime
from dbo.ContainerMovement
GROUP BY ContainerID) AS MOVEMENT_DURATION
Left join dbo.Container AS C
ON C.ContainerID = MOVEMENT_DURATION.ContainerID
WHERE DATEDIFF(Hour,FirstMovementTime,LastMovementTime) > 24  --- Alias wouldn't work, so calling the whole query.
ORDER BY MovementDurationHour DESC;
 



/*==============================================================================
 QUESTION 3 - BUILD A REUSABLE CURRENT MOVEMENT VIEW
 ------------------------------------------------------------------------------

 Business Requirement:
 The reporting team repeatedly needs the current/latest movement state of each
 container.

 Return ONLY these columns:

 - ContainerID
 - ContainerNumber
 - ISOType
 - Category
 - MovementID
 - MovementType
 - MovementTime
 - LocationCode

 Requirements:
 - ContainerMovement must carry the business question.
 - Use a CTE.
 - Use ROW_NUMBER() OVER() to identify the latest movement per container.
 - Join to Container.
 - Return one row per container that has movement history.
 - Once the query works, create a VIEW named:

      dbo.vw_CurrentContainerMovement

 - Query the VIEW after creating it.

 Engineering Question:
 Why is a VIEW useful when several reports need the same business logic? It helps in reusability.

 Write your query below.
==============================================================================*/


Select top 10 *
from dbo.Container

Select top 10 *
from dbo.ContainerMovement 


CREATE VIEW dbo.vw_CurrentContainerMovement AS

With Calc AS (Select ContainerID,MovementID,MovementType,MovementTime, FromLocation, ToLocation, ROW_NUMBER() OVER (PARTITION BY ContainerID ORDER BY MovementTime DESC) AS LatestMovement 
from dbo.ContainerMovement)

Select C.ContainerID, C.ContainerNumber, C.ISOTYPE, C.Category,
CA.MovementID,CA.MovementType,CA.MovementTime, CA.FromLocation, CA.ToLocation 
From dbo.Container AS C
left join Calc AS CA
ON C.ContainerID = CA.ContainerID
Where CA.LatestMovement = 1


Select *
From dbo.vw_CurrentContainerMovement

/*==============================================================================
 QUESTION 4 - MOVEMENT ACTIVITY BY CATEGORY
 ------------------------------------------------------------------------------

 Business Requirement:
 Operations wants to understand movement volume by container category and
 movement type.

 Return ONLY these columns:

 - Category
 - MovementType
 - TotalMovements
 - FirstMovementTime
 - LastMovementTime
 - ActivityLevel

 Requirements:
 - ContainerMovement must carry the business question.
 - Join ContainerMovement to Container.
 - Use COUNT().
 - Use MIN().
 - Use MAX().
 - Use GROUP BY.
 - Use HAVING.
 - Use CASE.
 - Return only Category + MovementType combinations with more than 2 movements.
 - Create ActivityLevel:

      If TotalMovements >= 5  = 'HIGH ACTIVITY'
      Otherwise               = 'NORMAL ACTIVITY'

 Engineering Question:
 Why should HAVING be used instead of WHERE to filter TotalMovements? First off, based off we've used an aggregated function, so the 

 Write your query below.
==============================================================================*/
Select top 10 *
from dbo.Container

Select top 10 *
from dbo.ContainerMovement 

Select C.Category,CM.MovementType,COUNT(CM.MovementType) AS TotalMovements, 
MIN(CM.MovementTime) AS FirstMovementTime,
MAX(CM.MovementTime) AS LastMovementTime,
CASE
    WHEN COUNT(CM.MovementType) >= 5 THEN 'HIGH ACTIVITY'
    ELSE 'NORMAL ACTIVITY'
END AS 'ActivityLevel'
from dbo.ContainerMovement AS CM
left join dbo.Container AS C
ON CM.ContainerID = C.ContainerID
Group by C.Category,CM.MovementType
Having COUNT(CM.MovementType) > 2;



/*==============================================================================
 QUESTION 5 - SHIPPING LINE MOVEMENT PERFORMANCE
 ------------------------------------------------------------------------------

 Business Requirement:
 Management wants to understand which shipping lines generate the most movement
 activity.

 Return ONLY these columns:

 - ShippingLineID
 - TotalContainers
 - TotalMovements
 - FirstMovementTime
 - LastMovementTime

 Requirements:
 - ContainerMovement must carry the business question.
 - Join ContainerMovement to Container.
 - Group by ShippingLineID.
 - Calculate:

      TotalContainers = count of distinct containers
      TotalMovements  = count of movement records
      FirstMovementTime
      LastMovementTime

 - Return only shipping lines with more than 3 movements.
 - Sort by TotalMovements from highest to lowest.

 Engineering Question:
 Why is COUNT(DISTINCT ContainerID) different from COUNT(MovementID) in this
 business requirement? how many unique containers belong to that shipping line,how many movement records that shipping line has.

 Write your query below.
==============================================================================*/


Select top 10 *
from dbo.Container

Select top 10 *
from dbo.ContainerMovement 



Select C.ShippingLineID, COUNT(DISTINCT C.ContainerID) AS TotalContainers,COUNT(CM.MovementID) AS TotalMovements, MIN(MovementTime) AS FirstMovementTime,MAX(MovementTime) AS LastMovementTime
from dbo.ContainerMovement AS CM
left join  dbo.Container AS C
ON CM.ContainerID = C.ContainerID
Group by C.ShippingLineID
Having COUNT(CM.MovementID) > 3
Order by TotalMovements desc;
