--1>

CREATE OR ALTER PROCEDURE Application.uspViewEmployees
AS
SELECT PersonID,FullName,IsEmployee,IsSalesperson
FROM Application.People
WHERE IsEmployee =1;

EXEC Application.uspViewEmployees;


GO
CREATE OR ALTER PROCEDURE Application.uspViewEmployees
AS 
SELECT PersonID AS 'ID Number',
	FullName AS 'Name',
	'Employee' AS Status,
	CASE WHEN IsSalesperson = 1 THEN 'Salesperson'
		 WHEN IsSalesperson = 0 THEN'Not Salesperson'
	END AS Position
FROM Application.People
WHERE IsEmployee = 1;


GO
CREATE OR ALTER PROCEDURE Application.uspViewData
AS
SELECT TOP 3 * FROM Application.People;
SELECT TOP 3 * FROM Warehouse.Colors;
SELECT TOP 3 * FROM Sales.Customers;

EXEC Application.uspViewData;



--2>

SELECT * FROM Warehouse.Colors ORDER BY ColorID DESC


GO
CREATE OR ALTER PROCEDURE Warehouse.uspInsertColor (@Color AS nvarchar(100))
AS
	DECLARE @ColorID INT
	SET @ColorID =(SELECT MAX(ColorID) FROM Warehouse.Colors)+1;
	INSERT INTO Warehouse.Colors(ColorID,ColorName,LastEditedBy)
		VALUES (@ColorID,@Color,1);
	SELECT * FROM Warehouse.Colors
		WHERE ColorID = @ColorID
		ORDER BY ColorID DESC;

EXEC Warehouse.uspInsertColor 'Periwinkle Blue'


GO
CREATE OR ALTER PROCEDURE Warehouse.uspRemoveLastColor
AS
DELETE FROM Warehouse.Colors ORDER BY ColorID DESC LIMIT 1

EXEC Warehouse.uspRemoveLastColor;



--3> 

GO
CREATE OR ALTER PROCEDURE Application.uspSimpleProcedure (@OutputMessage AS 
nvarchar(200) OUTPUT)
AS 
SET @OutputMessage ='This message was returned by the stored procedure on ' +
FORMAT(GETDATE(),'d')
;


DECLARE @MyLocalMessage nvarchar(200);
EXEC Application.uspSimpleProcedure
	@OutputMessage =@MyLocalMessage OUTPUT;
PRINT @MyLocalMessage;