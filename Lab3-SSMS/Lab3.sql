-----1) Create a transaction
--i)
CREATE OR ALTER PROCEDURE Warehouse.uspInsertColor (@Color AS nvarchar(100)) 
AS 
    DECLARE @ColorID INT 
    SET @ColorID = (SELECT MAX(ColorID) FROM Warehouse.Colors)+1; 
    INSERT INTO Warehouse.Colors (ColorID, ColorName, LastEditedBy) 
        VALUES (@ColorID, @Color, 1); 
    SELECT * FROM Warehouse.Colors 
        WHERE ColorID = @ColorID 
        ORDER BY ColorID DESC; 

--ii(a)
BEGIN TRANSACTION FirstTransaction WITH MARK; -- or BEGIN TRAN

--ii(b)
EXEC Warehouse.uspInsertColor 'Sunset Orange'; 
EXEC Warehouse.uspInsertColor 'Tomato Red';

--ii(c)
SELECT * FROM Warehouse.Colors 
ORDER BY ColorID DESC; 

--ii(d)
-- The query was not able to execute because the transaction has not yet been committed or roll-back. 
-- Bottom screen message is in infinite loop waiting for deadlock to get released.

--ii(e)
ROLLBACK TRANSACTION FirstTransaction; -- Undo the data input
-- Message at the bottom of the screen reads ‘Query executed successfully’. 
-- Deadlock was released because we rolled back our transaction of adding 2 colors and table doesn’t have 2 new rows(colors) added in transaction.

--ii(f)
COMMIT TRANSACTION FirstTransaction; --Commit the changes   
-- Again deadlock was released only after performing commit operation in first query window. 
-- This resulted in adding of 2 new colors from transaction and were reflected in other query window results.

-----2)Transaction save point
--i)
SELECT @@TRANCOUNT AS 'Open Transactions'; 
-- As there is no transaction running, it is showing 0.

--ii)
BEGIN TRANSACTION;

--iii)
SELECT @@TRANCOUNT AS 'Open Transactions'; 

--iv)
BEGIN TRANSACTION;

SELECT @@TRANCOUNT AS 'Open Transactions'; 

ROLLBACK TRANSACTION;

SELECT @@TRANCOUNT AS 'Open Transactions'; 

--v(a)
BEGIN TRANSACTION;
EXEC Warehouse.uspInsertColor 'Lemongrass Green'; 

--v(b)
SAVE TRANSACTION SavePointOne;

--v(c)
SELECT @@TRANCOUNT AS 'Open Transactions'; 
--As we can see there is 1 open transaction 

--v(d)
EXEC Warehouse.uspInsertColor 'Galaxy Purple'; 

--v(e)
SELECT * FROM Warehouse.Colors 
ORDER BY ColorID DESC;
-- 2 colors ‘Galaxy Purple’ & ‘Lemongrass Green’ have been added to the table. 
-- Galaxy Purple was added after savepoint whereas ‘Lemongrass Green’ was added after starting transaction.

--v(f)
ROLLBACK TRANSACTION SavePointOne;
-- If we omit the save point name then, the whole transaction (both colors including ‘Lemongrass Green’) would be reverted instead of savepoint.

--v(g)
SELECT @@TRANCOUNT AS 'Open Transactions'; 
-- As we rollbacked transaction to the savepoint we are still inside transaction started before savepoint.

--v(h)
COMMIT TRANSACTION;
SELECT * FROM Warehouse.Colors 
ORDER BY ColorID DESC;
-- As we committed the transaction after reverting back to savepoint, color ‘Lemongrass Green’ has been added to the table.


-----3)Automatically roll back transactions
--i)
-- If transaction includes command that generates error, then that command wouldn’t be executed other commands in the transaction would be executed.

--ii)
SELECT * FROM Warehouse.Colors 
	WHERE ColorID IN (SELECT MAX(ColorID) FROM Warehouse.Colors);
-- Most Recent Color is 'Lemongrass Green'

--iii)
BEGIN TRANSACTION;

--iv)
EXEC Warehouse.uspInsertColor 'burnished bronze'; 

--v)
EXEC Warehouse.uspInsertColor 'burnished bronze'; 
-- We encountered error because Color with ColorName = ‘burnished bronze’ has been already present and UNIQUE key constraint is applied on it.

--vi)
COMMIT TRANSACTION;

--vii)
SELECT * FROM Warehouse.Colors 
	WHERE ColorID IN (SELECT MAX(ColorID) FROM Warehouse.Colors);

--viii)
-- As we can see, even if there was an error in one of the command in transaction, other insert stored procedure worked and added the entry.

--ix)
SELECT CASE WHEN (16384 & @@OPTIONS) = 16384 THEN 'ON' 
       ELSE 'OFF' 
       END AS XACT_ABORT;

--x)
SET XACT_ABORT ON; -- or OFF

--xi)
BEGIN TRANSACTION;

--xii)
EXEC Warehouse.uspInsertColor 'Glittering Gold'; 

--xiii)
EXEC Warehouse.uspInsertColor 'Glittering Gold'; 
-- We got error due to the inserting the same color again that creates duplicate values in table. 

--xiv)
COMMIT TRANSACTION;
-- As we had turned ON XACT_ABORT, the transaction rolled back when error occurred in 2nd Insert. 
-- Hence, we got an error for no BEGIN TRANSACTION statement for COMMIT TRANSACTION statement.

--xv)
SELECT * FROM Warehouse.Colors 
	WHERE ColorID IN (SELECT MAX(ColorID) FROM Warehouse.Colors);
-- Color ‘Glittering Gold’ was not added to the Warehouse.Colors table.

--xvi)
-- XACT_ABORT applies to the current session only. Upon restarting, it resets automatically to OFF.

----QUIZ
--i)
DROP TABLE IF EXISTS dbo.BankAccounts; 
CREATE TABLE dbo.BankAccounts ( 
    AccountID INT PRIMARY KEY, 
    Balance decimal(10,2) 
); 
GO 
INSERT INTO dbo.BankAccounts 
    VALUES (1, 100.00), (2, 200.00), (3, 300.00); 

--ii)
-- This Stored Procedure that takes input parameter (Payor Account number, Payee Account number and Amount)
-- It also outputs string which indicates if payment was successful or not.
-- It also checks if Payor is paying more money than his balance which is not possible. 
-- In that case, transaction is rolled back and no changes are made to the data. Moreover, it returns ‘Transaction Unsuccessful’ as output string.
GO 
CREATE OR ALTER PROCEDURE dbo.transferFunds (@PayorAcc AS int, @PayeeAcc AS int, @Amount AS float, @OutputMessage AS nvarchar(200) OUTPUT) 
AS 
    BEGIN TRANSACTION;
	DECLARE @PayorAmt FLOAT;
	DECLARE @PayeeAmt FLOAT;
	SET @PayorAmt = (SELECT Balance FROM dbo.BankAccounts WHERE AccountID = @PayorAcc);
	SET @PayeeAmt = (SELECT Balance FROM dbo.BankAccounts WHERE AccountID = @PayeeAcc);
	SET @PayorAmt = @PayorAmt - @Amount;
	IF @PayorAmt >= 0
	BEGIN
		SET @PayeeAmt = @PayeeAmt + @Amount;
		UPDATE dbo.BankAccounts SET Balance = @PayorAmt FROM dbo.BankAccounts WHERE AccountID = @PayorAcc;
		UPDATE dbo.BankAccounts SET Balance = @PayeeAmt FROM dbo.BankAccounts WHERE AccountID = @PayeeAcc;	
		SET @OutputMessage ='Transaction Successful';
		COMMIT TRANSACTION;
	END
	ELSE
	BEGIN
		SET @OutputMessage ='Transaction Unsuccessful';
		ROLLBACK TRANSACTION;
	END

--iii)
DECLARE @MyLocalMessage nvarchar(200);
EXEC dbo.transferFunds 1,3,50.0, @OutputMessage =@MyLocalMessage OUTPUT;
PRINT @MyLocalMessage;

--FOR CHECKING BANKACCOUNTS TABLE
SELECT * FROM dbo.BankAccounts;