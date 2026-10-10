/*==============================================================================
 ONE-ROOF DATA ENGINEERING
 PORTOPS SQL ENGINEERING LAB
 WEEK: 3-4 OCTOBER 2026

 LAB TITLE:
 FIRST MANUAL / SEMI-AUTOMATED DATA PIPELINE

 BUSINESS SCENARIO
 ------------------------------------------------------------------------------

 Gate Operations receives a daily file containing truck and container
 transactions.

 The business wants the data to:

 1. arrive first in SQL Server Express;
 2. move to SQL Server Developer;
 3. be cleaned and loaded into a trusted target table;
 4. avoid loading the same transaction twice;
 5. use reusable load logic;
 6. run on a schedule without someone manually clicking Execute.

 SQL Server Express = SOURCE / LANDING ENVIRONMENT
 SQL Server Developer = PROCESSING / TARGET ENVIRONMENT

 Do not use SSIS for this lab.
==============================================================================*/


/*==============================================================================
 SOURCE FILE
 ------------------------------------------------------------------------------

 Use:
 PortOps_Gate_Source_Week_3_4_Oct.csv

 Columns:
 - TransactionID
 - TransactionTime
 - ContainerNumber
 - GateDirection
 - TruckNumber
 - Lane
 - OperatorName
==============================================================================*/


/*==============================================================================
 PART 1 - LAND THE DAILY FILE IN SQL SERVER EXPRESS
 ------------------------------------------------------------------------------

 Load the source file into SQL Server Express.

 Create:
 Database: PortOps_Source
 Table: dbo.GateTransaction_Raw

 After loading, return:
 - TotalRows
 - EarliestTransactionTime
 - LatestTransactionTime
 - DistinctContainers
 - MissingTruckNumbers

 Business rules:
 - Keep the landing data as received.
 - Do not clean ContainerNumber before landing.
 - Do not replace missing TruckNumber before landing.
 - SQL row count must match the source file.

 Write your SQL below.
==============================================================================*/
--CREATE DATABASE PortOpsSource
CREATE DATABASE PortOpsSource

--Create our table for the new DB

CREATE TABLE dbo.GateTransaction_Raw (
TransactionID NVARCHAR (50),
GateTime DATETIME,
ContainerNumber NVARCHAR(50),
TruckNumber INT 
)
-- TruckNumber was created as int, instead of varchar.
ALTER TABLE dbo.GateTransaction_Raw
ALTER COLUMN TruckNumber NVARCHAR(50);

--BULK INSERT

BULK INSERT [PortOpsSource].[dbo].[GateTransaction_Raw]
FROM 'C:\PortOps\gate_source.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',',ROWTERMINATOR = '\n',KEEPNULLS);

--Business Rule


Select  Count(*) AS TotalRows, MIN(GateTime) AS MinGateTime, MAX(GateTime) AS MaxGateTime, COUNT(DISTINCT ContainerNumber) AS DistinctContainers, 
    COUNT(CASE
        WHEN TruckNumber IS NOT NULL THEN 1
    END ) AS MissingTruckNumbers
From [PortOpsSource].[dbo].[GateTransaction_Raw]







/*==============================================================================
 PART 2 - MOVE THE DATA FROM EXPRESS TO DEVELOPER
 ------------------------------------------------------------------------------

 The analytics team does not want reporting workloads to run directly against
 the source environment.

 Move the landed data from SQL Server Express to SQL Server Developer using
 the command-line bulk-copy method practiced in class.

 On SQL Server Developer create:
 Database: PortOps_DW
 Staging table: dbo.stg_GateTransaction

 Staging columns:
 - TransactionID
 - TransactionTime
 - ContainerNumber
 - GateDirection
 - TruckNumber
 - Lane
 - OperatorName

 Business rules:
 - All landed rows must arrive in staging.
 - Staging row count must match Express landing row count.
 - Do not use Linked Server.
 - Do not use SSIS.
 - Keep the intermediate file used during movement.

 Record your movement commands as SQL comments below and add validation SQL.
==============================================================================*/
USE PortOps_DW;

CREATE TABLE dbo.stg_GateTransaction (
TransactionID NVARCHAR (50),
GateTime DATETIME,
ContainerNumber NVARCHAR(50),
TruckNumber NVARCHAR(50))

--Move the landed data from SQL Server Express to SQL Server Developer.

bcp [PortOps_DW].[dbo].[stg_GateTransaction] in "C:\PortOps\gate_source.dat" -c -t "/" -S localhost -T  --HAD TO TROUBLESHOOT THIS BECAUSE I WAS USING A CSV FILE, NOT A .DAT FILE TYPE


bcp [PortOps_DW].[dbo].[stg_GateTransaction] in "C:\PortOps\gate_source.csv" -c -t "," -S localhost -T -u

Select *From dbo.stg_GateTransaction


/*==============================================================================
 PART 3 - CREATE THE TRUSTED TARGET TABLE
 ------------------------------------------------------------------------------

 Create:
 dbo.GateTransaction

 Columns:
 - TransactionID
 - TransactionTime
 - ContainerNumber
 - GateDirection
 - TruckNumber
 - Lane
 - OperatorName
 - LoadDate

 Business rules:
 - ContainerNumber must not contain spaces.
 - TruckNumber must not contain spaces.
 - Missing TruckNumber must become 'NO TRUCK RECORDED'.
 - LoadDate must show when the row entered the trusted table.
 - A TransactionID must not exist more than once.

 Write your SQL below.
==============================================================================*/
USE PortOps_DW;
GO

CREATE TABLE dbo.GateTransaction (
    TransactionID NVARCHAR(50) NOT NULL UNIQUE,
    TransactionTime DATETIME,
    ContainerNumber NVARCHAR(50),
    GateDirection NVARCHAR(50),
    TruckNumber NVARCHAR(50) NOT NULL
        DEFAULT 'NO TRUCK RECORDED',
    Lane NVARCHAR(50),
    OperatorName NVARCHAR(50),
    LoadDate DATETIME NOT NULL
        DEFAULT GETDATE()
);

--INSERT INTO dbo.GateTransaction
SELECT *
FROM dbo.stg_GateTransaction







/*==============================================================================
 PART 4 - BUILD THE REUSABLE LOAD
 ------------------------------------------------------------------------------

 Create:
 dbo.usp_Load_GateTransaction

 When executed it must:
 - read from dbo.stg_GateTransaction;
 - apply the target business rules;
 - load only transactions not already in dbo.GateTransaction;
 - populate LoadDate for newly loaded rows.

 Test:
 1. Execute it once.
 2. Return the target row count.
 3. Execute it again without changing staging.
 4. Return the target row count again.

 Expected behaviour:
 The second run must not create duplicate TransactionID records.

 Write your SQL below.
==============================================================================*/
 Business rules:
 - ContainerNumber must not contain spaces.
 - TruckNumber must not contain spaces.
 - Missing TruckNumber must become 'NO TRUCK RECORDED'.
 - LoadDate must show when the row entered the trusted table.
 - A TransactionID must not exist more than once.


USE PortOps_DW;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Load_GateTransaction
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.GateTransaction (
        TransactionID,
        TransactionTime,
        ContainerNumber,
        GateDirection,
        TruckNumber,
        Lane,
        OperatorName,
        LoadDate
    )
    SELECT
        S.TransactionID,
        S.TransactionTime,
        REPLACE(S.ContainerNumber, ' ', ''),
        S.GateDirection,
        COALESCE(
            NULLIF(REPLACE(S.TruckNumber, ' ', ''), ''),
            'NO TRUCK RECORDED'
        ),
        S.Lane,
        S.OperatorName,
        GETDATE()
    FROM dbo.stg_GateTransaction AS S
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.GateTransaction AS T
        WHERE T.TransactionID = S.TransactionID
    );
END;
GO



/*==============================================================================
 PART 5 - PROVE THAT NEW DATA CAN FLOW
 ------------------------------------------------------------------------------

 Add at least TWO new valid transactions to the source landing table in
 SQL Server Express.

 Repeat the movement into Developer staging and execute the Stored Procedure.

 Return:
 - SourceRowCount
 - StagingRowCount
 - TargetRowCount
 - NewlyLoadedRows
 - DuplicateTransactionCount

 Business rules:
 - Existing target transactions must remain unchanged.
 - New transactions must load.
 - Duplicate TransactionID records must not be created.

 Record movement commands as SQL comments and write validation SQL below.
==============================================================================*/

--USE PortOpsSource
SELECT TOP (1000) [TransactionID]
      ,[GateTime]
      ,[ContainerNumber]
      ,[TruckNumber]
FROM [PortOpsSource].[dbo].[GateTransaction_Raw]


USE PortOpsSource;
GO

-- INSERTING NEW RECORDS
INSERT INTO dbo.GateTransaction_Raw
    (TransactionID, GateTime, ContainerNumber, TruckNumber)
VALUES
    ('TX1001', '2026-10-01 06:05:00.000', 'MSKU 123456 7', 'TRK-101'),
    ('TX1002', '2026-10-01 06:12:00.000', 'TGHU 765432 1', NULL),
    ('TX1003', '2026-10-01 06:20:00.000', 'CMAU 111222 3', 'TRK-103'),
    ('TX1004', '2026-10-01 06:31:00.000', 'MSKU 123456 7', 'TRK-101'),
    ('TX1005', '2026-10-01 06:45:00.000', 'HLXU 333444 5', NULL);
GO
-- PAIN POINT, ONCE I USE INSERT, IT WON'T REFLECT IN THE CSV. WHICH WILL ULTIMATELY NOT REFLECT IN CHANGED DATA PICKED. HOW CAN I IMPORT THESE DATA.

--INSERT NEW DATA INTO THE EXPRESS SERVER

--BULK INSERT INTO SOURCE TABLE

BULK INSERT [PortOpsSource].[dbo].[GateTransaction_Raw]
FROM 'C:\PortOps\gate_source.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',',ROWTERMINATOR = '\n',KEEPNULLS);

--BULK LOAD THE NEW CSV DATA INTO STAGING
bcp [PortOps_DW].[dbo].[stg_GateTransaction] in "C:\PortOps\gate_source.csv" -c -t "," -S localhost -T -u

-- CONFIRM DATA IS REFLECTING

USE PortOps_DW;


Select *
From [PortOps_DW].[dbo].[stg_GateTransaction]

/*==============================================================================
 PART 6 - SCHEDULE THE LOAD
 ------------------------------------------------------------------------------

 On SQL Server Developer create a SQL Server Agent job named:

 PortOps - Load Gate Transactions

 The job must execute:
 dbo.usp_Load_GateTransaction

 Use a short test schedule for demonstration.

 Prove it works:
 1. Add a new transaction to Developer staging.
 2. Do not manually execute the Stored Procedure.
 3. Allow the scheduled job to run.
 4. Confirm the new transaction appears in dbo.GateTransaction.

 Record as SQL comments:
 - Job name
 - Schedule used
 - Time test record was added
 - Time record appeared in target
 - Final target row count
==============================================================================*/







/*==============================================================================
 PART 7 - PIPELINE VALIDATION
 ------------------------------------------------------------------------------

 Return one validation result containing:

 - SourceRows
 - StagingRows
 - TargetRows
 - DuplicateTargetTransactions
 - NullTargetTruckNumbers
 - EarliestTargetTransaction
 - LatestTargetTransaction

 Business expectations:
 - DuplicateTargetTransactions = 0
 - NullTargetTruckNumbers = 0
 - Each valid TransactionID appears only once in target.

 Write your SQL below.
==============================================================================*/







/*==============================================================================
 FINAL ENGINEERING REVIEW
 ------------------------------------------------------------------------------

 Answer using SQL comments.

 1. What is the role of SQL Server Express in this pipeline? It's acting as the source/ landing zone of our data.

 2. What is the role of the staging table in SQL Server Developer? The staging area is for holding the data, and helps in history tracking.

 3. Why should raw landing data remain close to how it arrived? It should be close to how it arrives because it is helpdful for lookup of any new data coming in.

 4. What problem does BCP solve in this lab? BCP helps solves the problem of migrating data from one server to the other, only if they're on the same machine.

 5. What problem does the Stored Procedure solve? Stored procedure helps in automation of tasks. instead of manually loadng, and changing data.

 6. What problem does SQL Server Agent solve?

 7. Why should running the Stored Procedure twice not duplicate the target? It won't duplicate the target because of the constraint in the ID column, which can only accept unique ids. This also helps in idempotency.

 8. If a TransactionID already exists in target but arrives again with a corrected
    TruckNumber, what would the current load do? It should store the trucknumber with the correct vaue, and overwrite 

 9. What extra capability would be required if corrected existing records must
    update automatically?

 10. If BCP is replaced by SSIS next week, what business problem remains exactly
     the same? 
==============================================================================*/


/*==============================================================================
 SUBMISSION
 ------------------------------------------------------------------------------

 Submit ONE completed .sql file containing:
 - source, staging and target creation SQL;
 - validation queries;
 - Stored Procedure;
 - BCP commands as SQL comments;
 - rerun-test evidence;
 - SQL Server Agent job details as SQL comments;
 - Final Engineering Review answers.

 Assessment focus:
 - source / staging / target understanding
 - data movement
 - cleaning
 - duplicate prevention
 - Stored Procedure design
 - rerunnable load behaviour
 - scheduling
 - validation
 - engineering reasoning
==============================================================================*/
