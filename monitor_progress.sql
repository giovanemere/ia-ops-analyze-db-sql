-- Monitor Progress Query for Database Operations
-- Ejecutar cada 2-3 minutos para monitorear progreso

SELECT 
    GETDATE() as timestamp_check,
    session_id,
    command,
    CAST(percent_complete AS DECIMAL(5,2)) as percent_complete,
    CAST(estimated_completion_time/1000.0/60 AS DECIMAL(10,2)) as estimated_minutes_remaining,
    start_time,
    DATEDIFF(MINUTE, start_time, GETDATE()) as elapsed_minutes,
    status,
    blocking_session_id,
    wait_type,
    wait_time,
    cpu_time,
    total_elapsed_time/1000 as elapsed_seconds,
    reads,
    writes,
    logical_reads
FROM sys.dm_exec_requests 
WHERE percent_complete > 0
   OR command IN ('DBCC', 'ALTER INDEX', 'UPDATE STATISTICS', 'BACKUP DATABASE', 'RESTORE DATABASE')
ORDER BY percent_complete DESC, start_time;

-- Query adicional para ver sesiones activas
SELECT 
    'ACTIVE_SESSIONS' as log_type,
    GETDATE() as timestamp_check,
    s.session_id,
    s.login_name,
    s.program_name,
    s.host_name,
    s.status,
    r.command,
    r.percent_complete,
    DB_NAME(s.database_id) as database_name
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
WHERE s.is_user_process = 1
  AND s.status IN ('running', 'runnable', 'suspended')
ORDER BY s.session_id;
