/*
-- Detecting Circular References
--
-- detect if there are any circular references in your database schema
--
-- https://azure.microsoft.com/fr-ca/blog/finding-circular-foreign-key-references/
--
-- * added a hotfix
--
*/
GO
SET NOCOUNT ON
-- WWB: Create a Temp Table Of All Relationship To Improve Overall Performance
DROP TABLE IF EXISTS #TableRelationships;
CREATE TABLE #TableRelationships (
  FK_Schema nvarchar(MAX)
, FK_Table  nvarchar(MAX)
, PK_Schema nvarchar(MAX)
, PK_Table  nvarchar(MAX) )
-- WWB: Create a List Of All Tables To Check
DROP TABLE IF EXISTS #TableList
CREATE TABLE #TableList (
  [Schema] nvarchar(MAX)
, [Table]  nvarchar(MAX) )
-- WWB: Fill the Table List
INSERT INTO #TableList ( [Table], [Schema] )
SELECT TABLE_NAME
,      TABLE_SCHEMA
FROM INFORMATION_SCHEMA.TABLES
WHERE
	Table_Type = 'BASE TABLE'
-- WWB: Fill the RelationShip Temp Table
INSERT INTO #TableRelationships ( FK_Schema, FK_Table, PK_Schema, PK_Table )
SELECT FK.TABLE_SCHEMA
,      FK.TABLE_NAME
,      PK.TABLE_SCHEMA
,      PK.TABLE_NAME
FROM       INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS C 
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS       FK ON C.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS       PK ON C.UNIQUE_CONSTRAINT_NAME = PK.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE        CU ON C.CONSTRAINT_NAME = CU.CONSTRAINT_NAME
INNER JOIN ( SELECT i1.TABLE_NAME
,                   i2.COLUMN_NAME
FROM       INFORMATION_SCHEMA.TABLE_CONSTRAINTS i1
INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE  i2 ON i1.CONSTRAINT_NAME = i2.CONSTRAINT_NAME
WHERE
	i1.CONSTRAINT_TYPE = 'PRIMARY KEY' )              PT ON PT.TABLE_NAME = PK.TABLE_NAME
DROP TABLE IF EXISTS #Stack
CREATE TABLE #Stack (
  [Schema] nvarchar(MAX)
, [Table]  nvarchar(MAX) )
GO
-- WWB: Drop SqlRecursiveFind
DROP PROCEDURE IF EXISTS [dbo].[SqlRecursiveFind]
GO
-- WWB: Create a Stored Procedure that Recursively Calls Itself
CREATE OR ALTER PROC #SqlRecursiveFind @BaseSchmea nvarchar(MAX)
,                                  @BaseTable nvarchar(MAX)
,                                  @Schmea nvarchar(MAX)
,                                  @Table nvarchar(MAX)
,                                  @Fail nvarchar(MAX) OUTPUT
AS
	SET NOCOUNT ON
	-- WWB: Keep Track Of the Schema and Tables We Have Checked
	-- Prevents Looping
	INSERT INTO #Stack ( [Schema], [Table] )
	VALUES             ( @Schmea,  @Table  ) DECLARE @RelatedSchema nvarchar(MAX) DECLARE @RelatedTable nvarchar(MAX)
	-- WWB: Select all tables that the input table is dependent on
	DECLARE table_cursor CURSOR LOCAL FOR SELECT PK_Schema
	,                                            PK_Table
	FROM #TableRelationships
	WHERE
		FK_Schema = @Schmea
		AND FK_Table = @Table OPEN table_cursor;
	-- Perform the first fetch.
	FETCH NEXT FROM table_cursor INTO @RelatedSchema, @RelatedTable;
	-- Check @@FETCH_STATUS to see if there are any more rows to fetch.
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- WWB: If We have Recurred To Where We Start This
		-- Is a Circular Reference
		-- Begin failing out of the recursions
		IF (
				@BaseSchmea = @RelatedSchema
				AND @BaseTable = @RelatedTable)
		BEGIN
			SET @Fail = @RelatedSchema + '.' + @RelatedTable RETURN
		END ELSE BEGIN
			DECLARE @Count int
			-- WWB: Check to make sure that the dependencies are not in the stack
			-- If they are we don't need to go down this branch
			SELECT @Count = COUNT(1)
			FROM #Stack
			WHERE
				#Stack.[Schema] = @RelatedSchema
				AND #Stack.[Table] = @RelatedTable IF (@Count=0)
			BEGIN
				-- WWB: Recurse
				EXECUTE #SqlRecursiveFind @BaseSchmea
				,                              @BaseTable
				,                              @RelatedSchema
				,                              @RelatedTable
				,                              @Fail OUTPUT IF (LEN(@Fail) > 0)
				BEGIN
					-- WWB: If the Call Fails, Build the Output Up
					SET @Fail = @RelatedSchema + '.' + @RelatedTable + ' -> ' + @Fail RETURN
				END
			END
		END
		-- This is executed as long as the previous fetch succeeds.
		FETCH NEXT FROM table_cursor INTO @RelatedSchema, @RelatedTable;
	END CLOSE table_cursor; DEALLOCATE table_cursor;
GO
SET NOCOUNT ON DECLARE @Schema nvarchar(MAX) DECLARE @Table nvarchar(MAX) DECLARE @Fail nvarchar(MAX)
-- WWB: Loop Through All the Tables In the Database Checking Each One
DECLARE list_cursor CURSOR FOR SELECT [Schema]
,                                     [Table]
FROM #TableList OPEN list_cursor;
-- Perform the first fetch.
FETCH NEXT FROM list_cursor INTO @Schema, @Table;
-- Check @@FETCH_STATUS to see if there are any more rows to fetch.
WHILE @@FETCH_STATUS = 0
BEGIN
	-- WWB: Clear the Stack (Don't you love Global Variables)
	DELETE #Stack
	-- WWB: Initialize the Input
	SET @Fail = ''
	-- WWB: Check the Table
	EXECUTE #SqlRecursiveFind @Schema
	,                              @Table
	,                              @Schema
	,                              @Table
	,                              @Fail OUTPUT IF (LEN(@Fail) > 0)
	BEGIN
		-- WWB: Failed, Output
		SET @Fail = @Schema + '.' + @Table + ' -> ' + @Fail PRINT @Fail
	END
	-- This is executed as long as the previous fetch succeeds.
	FETCH NEXT FROM list_cursor INTO @Schema, @Table;
END

-- Remove cursor
IF CURSOR_STATUS('global','list_cursor')>=-1
BEGIN
 DEALLOCATE list_cursor
END

-- WWB: Clean Up  CLOSE list_cursor;  DEALLOCATE list_cursor;
DROP TABLE if exists #TableRelationships;
DROP TABLE if exists  #Stack;
DROP TABLE if exists  #TableList;
DROP PROC  if exists  #SqlRecursiveFind;
GO
