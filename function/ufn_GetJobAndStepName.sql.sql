CREATE OR ALTER FUNCTION dbo.ufn_GetJobAndStepName
(
    @InputMessage NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE
        @result    NVARCHAR(MAX) = @InputMessage,
        @pos0x     INT,
        @posStep   INT,
        @hex34     NVARCHAR(34),
        @jobBin    VARBINARY(16),
        @stepNum   INT,
        @jobName   NVARCHAR(128),
        @stepName  NVARCHAR(128);

    -- Locate "0x" and ": Step"
    SET @pos0x   = CHARINDEX('0x', @InputMessage);
    SET @posStep = CHARINDEX(': Step ', @InputMessage);
    IF @pos0x = 0 OR @posStep = 0 RETURN @result; -- echo original if not found

    -- Try to slice exactly 34 chars: "0x" + 32 hex digits
    IF @pos0x > 0
        SET @hex34 = SUBSTRING(@InputMessage, @pos0x, 34);

    -- Validate & convert the hex
    IF LEN(@hex34) = 34
       AND @hex34 LIKE '0x[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]%'
    BEGIN
        SET @jobBin = TRY_CONVERT(VARBINARY(16), @hex34, 1);
    END

    -- Parse the step number after ": Step "
    IF @posStep > 0
    BEGIN
        DECLARE @after NVARCHAR(64) = LTRIM(RTRIM(SUBSTRING(@InputMessage, @posStep + 7, 64)));
        DECLARE @cut INT = NULLIF(PATINDEX('%[^0-9]%', @after), 0);
        SET @stepNum = TRY_CAST(IIF(@cut IS NULL, @after, LEFT(@after, @cut - 1)) AS INT);
    END

    -- Look up names only if we have both pieces
    IF @jobBin IS NOT NULL AND @stepNum IS NOT NULL
    BEGIN
        SELECT @jobName = j.name
        FROM msdb.dbo.sysjobs AS j
        WHERE CONVERT(VARBINARY(16), j.job_id) = @jobBin;

        SELECT @stepName = s.step_name
        FROM msdb.dbo.sysjobsteps AS s
        WHERE CONVERT(VARBINARY(16), s.job_id) = @jobBin
          AND s.step_id = @stepNum;

        IF @jobName IS NOT NULL AND @stepName IS NOT NULL
            SET @result = @jobName + N' | ' + @stepName;  -- success
    END

    RETURN @result;  -- echo original if not found
END
