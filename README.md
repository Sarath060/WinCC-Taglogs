# WinCC-Taglogs
Read WinCC Taglogs from linked Server using dynamic Stored Procedure and pivot the data based on ValueID(TagName).


## Example 
```
  declare @prj AS nvarchar(90),
  @startTimeLocal AS DATETIME,
  @endTimeLocal AS DATETIME,
  @timeStepInterpolation AS varchar(20),
  @testString AS VARCHAR(max)

  SET @prj = 'CC_Example_22_06_02_11_44_39R'        -- Project Archive 'CC_******R'
  SET @testString = ''                              -- Value-ID or Tagname with ";" Delimiter
  SET @startTimeLocal = '2022-06-28 20:00:00'       -- Format YYYY-MM-DD hh.mm.ss.mmm
  SET @endTimeLocal = '2022-06-28 20:10:00'         -- Format YYYY-MM-DD hh.mm.ss.mmm
  SET @timeStepInterpolation = 'TIMESTEP=60,257'    -- Format 'Time_Step,interpolation'

  exec dbo.spWinccTagLogsPivoted @prj,@testString,@startTimeLocal,@endTimeLocal,@timeStepInterpolation
```

> Note: To read all the tags @testString should be ''(empty string) or 'all'

## Wincc Linked Server Query


### Building the complete command string:

	'"TAG:R,1,'2009-01-20 11:15:23.000',"'2009-01-20 13:26:45.000','TIMESTEP=5,261'"
	'   |   |            |                          |                        |  |
	'   |   |            ---- Starttime (UTC)       ------ Endtime (UTC)     |  ---- AVG_Interpolated
	'   |   ----- Value-ID or Tagname                                        ------- Time interval
	'   |
	'   --------- Read command for a Tag

### Selection of an ValueID or ValueName:

	Parameter                   Description
	ValueID                     ValueID from the database table.
	ValueName                   ValueName in the format "ArchiveName\\ValueName". The ValurName must be enclosed by single quotation marks.

### Selection of an absolute Time Interval:
	Parameter                   Description   
	TimeBegin                   Start time in the format YYYY-MM-DD hh.mm.ss.mmm
	TimeEnd                     End time in the format YYYY-MM-DD hh.mm.ss.mmm

### Selection of a relative Time Interval:

	Parameter                   Description       
	TimeBegin                   0000-00-00 00:00:00.000: Reads from the beginning of the recording.
	TimeEnd                     0000-00-00 00:00:00.000: Reads until the end of the recording.
	
> Note: Relative time interval input is not valid.

	Example 1                   <TimeBegin> = From 2002-02-02 12:00:00.000 until
                              <TimeEnd> = 0000-00-00 00:00:10.000: Reads 10 seconds
                              forward.
	Example 2                   <TimeBegin> = From 0000-00-00 00:00:10.000 until
                              <TimeEnd> = 2002-02-02 12:00:00.000: Reads 10 seconds
                              back.

### TIMESTEP:

	- The first parameter "TimeStep" is specified as an interval in seconds via the
		user interface of the Excel client.
      Example:
        If the archive values are available in a recording interval of two seconds and
        the query interval (TimeStep) is specified as "4", then only every second value
        is read (4 seconds interval between the individual values).

	- The second parameter, here: "5", has been permanently stored in the script
		and must either be changed there or also transferred to the user interface. This
		parameter is also known as the aggregation type and is responsible for
		creating intermediate values

### TimeStepModes:

	Without                 With
	interpolation           interpolation                       Meaning
	1 (FIRST)               257 (FIRST_INTERPOLATED)            First value
	2 (LAST)                258 (LAST_INTERPOLATED)             Last value
	3 (MIN)                 259 (MIN_INTERPOLATED)              Minimum value
	4 (MAX)                 260 (MAX_INTERPOLATED)              Maximum value
	5 (AVG)                 261 (AVG_INTERPOLATED)              Mean value
	6 (SUM)                 262 (SUM_INTERPOLATED)              Total
	7 (COUNT)               263 (COUNT_INTERPOLATED)            Number of values
