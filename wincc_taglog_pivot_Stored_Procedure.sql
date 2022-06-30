SET ANSI_NULLS ON 
GO
SET QUOTED_IDENTIFIER ON 
GO

-- =============================================
-- Author:		Sarath Kumar K
-- Create date: 21 June 2022
-- Description:	Wincc Linked Server tag logs pivoted by ValueID
-- =============================================



alter PROCEDURE dbo.spWinccTagLogsPivoted 

	@prj AS nvarchar(90), -- Project Archive 'CC******R'
	@tags AS nvarchar(max), --Value-ID or Tagname with ";" Delimiter
	@startTimeLocal AS DATETIME, --Format YYYY-MM-DD hh.mm.ss.mmm
	@endTimeLocal AS DATETIME, --Format YYYY-MM-DD hh.mm.ss.mmm
	@timeStepInterpolation AS nvarchar(20) --Format 'Time_Step,interpolation'

AS  BEGIN

	SET NOCOUNT ON 

	--UTC Time Format YYYY-MM-DD hh.mm.ss.mmm
	DECLARE @startTimeUTC AS datetime = DATEADD(SECOND,DATEDIFF(SECOND, GETDATE(), GETUTCDATE()),@startTimeLocal) 
	DECLARE @endTimeUTC AS datetime = DATEADD(SECOND,DATEDIFF(SECOND, GETDATE(), GETUTCDATE()),@endTimeLocal) 
	
	DECLARE @param VARCHAR(MAX),
	@query nVARCHAR(max),
	@resultTagIdList AS NVARCHAR(MAX),
	@resultValueName AS nvarchar(max) 
	
	
	--Read all Tags if @tags is "All" or ""
	IF (@tags = '' OR @tags = 'all') 
		BEGIN
			SET @tags = ''
			SET @query = 'Select @tags = COALESCE(@tags , '', '') + concat(ValueID,'';'')  FROM  [' + @prj + '] .[dbo].[Archive]' 
		
			EXECUTE sp_executesql @query, N'@tags nvarchar(max) OUTPUT',@tags OUTPUT

		END 
		
	--Getting tag logs from wincc linked server to temp table
	CREATE TABLE #myTable (ValueID int, Timestamp datetime, RealValue float)

	SET @param = '''TAG:R,(' + @tags + '),' + CONVERT(varchar, @startTimeUTC, 120) + ',' + CONVERT(varchar, @endTimeUTC, 120) + ',' + @timeStepInterpolation + ''''
	SET @query = 'INSERT INTO #myTable SELECT ValueID,Timestamp,RealValue FROM OPENQUERY(LnkRtDb_WinCCOLEDB,' + @param + ')' 
	
	EXEC(@query) 
	
	-- ValueID list in linked provider Server result
	SELECT @resultTagIdList = STUFF((SELECT ', ' + quotename(ValueID)
				FROM
					#myTable
				GROUP BY
					ValueID
				ORDER BY
					ValueID FOR XML PATH('')
			),1,2,'');

	-- Get Value Name from and Archive Info OUTPUT (" ValueID as Value Name , ")
	SET @query = ' Select @resultValueName =COALESCE(@resultValueName , '', '') + 
					concat(char(91),[valueid],char(93), '' as '', char(39) , [ValueName], char(39), '' , '')  FROM
				[' + @prj + '].[dbo].[Archive] where [ValueID] in (' + REPLACE(REPLACE(@resultTagIdList, ']', ''), '[', '') + ')' 
	
	EXECUTE sp_executesql @query, N'@resultValueName nvarchar(max) OUTPUT', @resultValueName OUTPUT


	SET @resultValueName = LEFT(@resultValueName, len(@resultValueName) - 1) 
	
	--Pivot Query
	SET @query = '
		SELECT 
				dateadd(SECOND, DATEDIFF(second, GETUTCDATE(), GETDATE()),Timestamp) as ''Log Time'' ' + @resultValueName + '
		FROM
				(select  ValueID,Timestamp,RealValue FROM #myTable) as  PivotData
		PIVOT	
				(max(RealValue) FOR ValueID IN (' + @resultTagIdList + ')) as   Pivoting
		
				order by Timestamp' 
				
	EXEC sp_executesql @query 
	
	--Drop the temp Table
	DROP TABLE #myTable

END


GO

