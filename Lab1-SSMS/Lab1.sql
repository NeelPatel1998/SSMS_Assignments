--Q3a: QUERIES:
----------------------------------------------------
--i)
SELECT TOP 5 * FROM Purchasing.Suppliers;

--ii)
SELECT * FROM Purchasing.SupplierCategories WHERE SupplierCategoryID = 2;

--iii)
SELECT * FROM Application.People WHERE PersonID = 21 OR PersonID = 22



--Q3b
----------------------------------------------------
--CREATING VIEW WITH NAME 'Purchasing.SupplierDetailColumns'
-- Explanation: JOIN can combine 2 tables based on common related column
-- Explanation: AS is used for renaming table for short abbreviation
GO 
CREATE VIEW Purchasing.SupplierDetailColumns AS
SELECT 
	Suppliers.SupplierName,
	SupplierCategories.SupplierCategoryName,
	PrimaryContact.FullName AS PrimaryContact,
	PrimaryContact.PhoneNumber AS PrimaryPhone,
	PrimaryContact.EmailAddress AS PrimaryEmail,
	AlternateContact.FullName AS AlternateContact,
	AlternateContact.PhoneNumber AS AlternatePhone,
	AlternateContact.EmailAddress AS AlternateEmail
FROM Purchasing.Suppliers
	INNER JOIN Purchasing.SupplierCategories
		ON Suppliers.SupplierCategoryID = SupplierCategories.SupplierCategoryID
	INNER JOIN Application.People AS PrimaryContact
		ON Suppliers.PrimaryContactPersonID = PrimaryContact.PersonID
	INNER JOIN Application.People AS AlternateContact
		ON Suppliers.AlternateContactPersonID = AlternateContact.PersonID;


--CREATING VIEW WITH NAME 'Purchasing.SupplierDetailRows'
--Explanation: UNION can combine result to 2 queries into one output
GO
CREATE VIEW Purchasing.SupplierDetailRows AS
SELECT
	Suppliers.SupplierName,
	SupplierCategories.SupplierCategoryName,
	'Primary Contact' AS ContactType,
	People.FullName AS Contact,
	People.PhoneNumber AS Phone,
	People.EmailAddress AS Email
FROM Purchasing.Suppliers
	INNER JOIN Purchasing.SupplierCategories
		ON Suppliers.SupplierCategoryID =SupplierCategories.SupplierCategoryID
	INNER JOIN Application.People
		ON Suppliers.PrimaryContactPersonID =People.PersonID
UNION
SELECT
	Suppliers.SupplierName,
	SupplierCategories.SupplierCategoryName,
	'Alternate Contact'AS ContactType,
	People.FullName AS Contact,
	People.PhoneNumber AS Phone,
	People.EmailAddress AS Email
FROM Purchasing.Suppliers
	INNER JOIN Purchasing.SupplierCategories
		ON Suppliers.SupplierCategoryID =SupplierCategories.SupplierCategoryID
	INNER JOIN Application.People
	ON Suppliers.AlternateContactPersonID =People.PersonID



--Q3c
----------------------------------------------------
--FOR DISPLAYING ALL VIEWS IN DATABASE USING QUERY
GO
SELECT * FROM sys.objects WHERE type_desc='VIEW';

--MODIFIED QUERY TO GET GIVEN INFORMATION
SELECT 
	sys.objects.object_id,
	sys.schemas.name AS schema_name,
	sys.objects.name AS view_name
FROM sys.objects 
	INNER JOIN sys.schemas 
		ON sys.objects.schema_id = sys.schemas.schema_id
WHERE 
	sys.objects.name LIKE 'SupplierDetailColumns' OR 
	sys.objects.name LIKE 'Suppliers' AND sys.schemas.name LIKE 'Website' OR 
	sys.objects.name LIKE 'Customers'  AND sys.schemas.name LIKE 'Website' OR 
	sys.objects.name LIKE 'VehicleTemperatures' AND sys.schemas.name LIKE 'Website';
	

--TESTING GIVEN QUERY
SELECT * 
FROM sys.sql_modules
WHERE object_id = 1678629023 --OBJECT_ID('Website.Suppliers')

--VERIFYING AND COMPARING
SELECT * 
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('Website.Suppliers')

EXEC sp_helptext 'Website.Suppliers';
--EXPLANATION: Here we are displaying specific sql module by object id. sp_helptext displays query in detail.


--Q4
----------------------------------------------------
--i - CREATING VIEW WITH NAME 'Sales.OutstandingBalance'
GO
CREATE VIEW Sales.OutstandingBalance AS
SELECT * FROM Sales.CustomerTransactions WHERE IsFinalized = 0;

--ii - TESTING THE ABOVE VIEW
GO
SELECT * from Sales.OutstandingBalance

--iii
EXEC sp_rename 'Sales.CustomerTransactions.AmountExcludingTax','PreTaxTotal','COLUMN';
--WARNING: Changing any part of an object name could break scripts and stored procedures.
--HENCE VIEW IN THE ABOVE QUESTION (Q4-ii) HAS BEEN BROKEN

--iv
--ALTERING THE VIEW TO CHANGE NAME OF COLUMN IN OUTPUT OF VIEW
GO
ALTER VIEW Sales.OutstandingBalance AS 
SELECT * FROM Sales.CustomerTransactions WHERE IsFinalized = 0;

--v
--AGAIN TESTING THE VIEW
GO
SELECT * FROM Sales.OutstandingBalance

--vi
--EXECUTING GIVEN QUERY
GO
ALTER VIEW Sales.OutstandingBalance
WITH SCHEMABINDING 
AS
SELECT
	CustomerTransactionID AS 'Transaction Number',
	CustomerID AS 'Customer Number',
	TransactionDate AS 'Order Date',
	PreTaxTotal AS 'Amount Before Tax',
	TaxAmount AS 'Tax Due',
	OutstandingBalance AS 'Balance Due'
FROM Sales.CustomerTransactions
WHERE OutstandingBalance >0
--Explanation: SCHEMABINDING can bind object to the schema. This disables from dropping underlying views.
-- It also increases performance of the query. 

--vii
--REPEAT COLUMN RENAME FROM iii
EXEC sp_rename 'Sales.CustomerTransactions.AmountExcludingTax','PreTaxTotal','COLUMN';
--ERROR: Either the parameter @objname is ambiguous or the claimed @objtype (COLUMN) is wrong.

--viii
--EXECUTING GIVEN QUERY
SELECT dm_sql_referencing_entities.referencing_schema_name,
	dm_sql_referencing_entities.referencing_entity_name,
	sql_modules.object_id,
	sql_modules.definition,
	sql_modules.is_schema_bound
FROM sys.dm_sql_referencing_entities('Sales.CustomerTransactions','OBJECT')
	JOIN sys.sql_modules ON dm_sql_referencing_entities.referencing_id =sql_modules.object_id;
--Explanation: QUERY FOR DISPLAYING DEPENDENT VIEWS

--ix
--DROPPING THE VIEW WITH NAME 'Sales.OutstandingBalance'
DROP VIEW IF EXISTS Sales.OutstandingBalance;

--x
--RAN QUERY FROM viii AGAIN
--WE COULD SEE THAT ONE RESULT WITH SCHEMA BOUND 'Sales.OutstandingBalance' HAS BEEN REMOVED.


--Q5
----------------------------------------------------
--i : SIMPLE SELECT QUERY. THIS RETURNS MANY UNWANTED COLUMNS
SELECT * FROM Warehouse.StockItems
SELECT * FROM Purchasing.Suppliers

--ii
--CREATING VIEW WITH NAME 'Warehouse.StockItemDetails'
GO
CREATE VIEW Warehouse.StockItemDetails 
WITH SCHEMABINDING AS
SELECT 
	StockItemStockGroups.StockItemStockGroupID,
	StockItems.StockItemName,
	StockItemHoldings.QuantityOnHand,
	StockGroups.StockGroupName,
	Colors.ColorName,
	StockItems.UnitPrice,
	StockItems.SupplierID
FROM Warehouse.StockItemStockGroups
	INNER JOIN Warehouse.StockItems
		ON StockItemStockGroups.StockItemID = StockItems.StockItemID
	INNER JOIN Warehouse.StockGroups
		ON StockItemStockGroups.StockGroupID = StockGroups.StockGroupID
	INNER JOIN Warehouse.Colors
		ON StockItems.ColorID = Colors.ColorID
	INNER JOIN Warehouse.StockItemHoldings
		ON StockItems.StockItemID = StockItemHoldings.StockItemID

--iii
--CREATING INDEX ON VIEW FOR FASTER PERFORMANCE OF QUERY
CREATE UNIQUE CLUSTERED INDEX index_stock ON Warehouse.StockItemDetails(StockItemStockGroupID, StockItemName, SupplierID)

--iv
--MERGING DATA FROM VIEW BY JOINING OTHER TABLE
SELECT * 
	FROM Warehouse.StockItemDetails
		INNER JOIN Purchasing.Suppliers
			ON Suppliers.SupplierID =StockItemDetails.SupplierID
WHERE StockItemDetails.SupplierID =5;