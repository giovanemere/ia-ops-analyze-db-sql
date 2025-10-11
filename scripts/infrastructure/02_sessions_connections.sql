-- =====================================================
-- ANÁLISIS DE SESIONES Y CONEXIONES
-- Usuarios activos, bloqueos, procesos
-- =====================================================

-- 1. SESIONES ACTIVAS
SELECT 
    'ACTIVE_SESSIONS' as SECTION,
    s.session_id as SESSION_ID,
    s.login_name as LOGIN_NAME,
    s.host_name as HOST_NAME,
    s.program_name as PROGRAM_NAME,
    s.client_interface_name as CLIENT_INTERFACE,
    s.login_time as LOGIN_TIME,
    s.last_request_start_time as LAST_REQUEST_START,
    s.last_request_end_time as LAST_REQUEST_END,
    s.status as SESSION_STATUS,
    s.cpu_time as CPU_TIME_MS,
    s.memory_usage as MEMORY_USAGE_PAGES,
    s.total_scheduled_time as TOTAL_SCHEDULED_TIME_MS,
    s.total_elapsed_time as TOTAL_ELAPSED_TIME_MS,
    s.reads as TOTAL_READS,
    s.writes as TOTAL_WRITES,
    s.logical_reads as TOTAL_LOGICAL_READS,
    r.command as CURRENT_COMMAND,
    r.percent_complete as PERCENT_COMPLETE,
    r.estimated_completion_time as ESTIMATED_COMPLETION_MS,
    SUBSTRING(st.text, (r.statement_start_offset/2)+1, 
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2) + 1) as CURRENT_SQL
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE s.is_user_process = 1
ORDER BY s.cpu_time DESC;

-- 2. BLOQUEOS ACTIVOS
SELECT 
    'BLOCKING_SESSIONS' as SECTION,
    blocked.session_id as BLOCKED_SESSION_ID,
    blocked.login_name as BLOCKED_LOGIN,
    blocked.host_name as BLOCKED_HOST,
    blocked.program_name as BLOCKED_PROGRAM,
    blocking.session_id as BLOCKING_SESSION_ID,
    blocking.login_name as BLOCKING_LOGIN,
    blocking.host_name as BLOCKING_HOST,
    blocking.program_name as BLOCKING_PROGRAM,
    r.wait_type as WAIT_TYPE,
    r.wait_time as WAIT_TIME_MS,
    r.wait_resource as WAIT_RESOURCE,
    SUBSTRING(st_blocked.text, (r.statement_start_offset/2)+1, 
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(st_blocked.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2) + 1) as BLOCKED_SQL,
    st_blocking.text as BLOCKING_SQL
FROM sys.dm_exec_sessions blocked
INNER JOIN sys.dm_exec_requests r ON blocked.session_id = r.session_id
INNER JOIN sys.dm_exec_sessions blocking ON r.blocking_session_id = blocking.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) st_blocked
OUTER APPLY sys.dm_exec_sql_text((SELECT sql_handle FROM sys.dm_exec_requests WHERE session_id = blocking.session_id)) st_blocking
WHERE r.blocking_session_id <> 0
ORDER BY r.wait_time DESC;

-- 3. CONEXIONES POR APLICACIÓN
SELECT 
    'CONNECTIONS_BY_APP' as SECTION,
    program_name as APPLICATION,
    COUNT(*) as CONNECTION_COUNT,
    SUM(cpu_time) as TOTAL_CPU_TIME_MS,
    SUM(memory_usage) as TOTAL_MEMORY_PAGES,
    SUM(reads) as TOTAL_READS,
    SUM(writes) as TOTAL_WRITES,
    SUM(logical_reads) as TOTAL_LOGICAL_READS,
    AVG(cpu_time) as AVG_CPU_TIME_MS,
    MAX(login_time) as LAST_LOGIN_TIME
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
GROUP BY program_name
ORDER BY COUNT(*) DESC;

-- 4. CONEXIONES POR USUARIO
SELECT 
    'CONNECTIONS_BY_USER' as SECTION,
    login_name as LOGIN_NAME,
    COUNT(*) as CONNECTION_COUNT,
    COUNT(DISTINCT host_name) as UNIQUE_HOSTS,
    COUNT(DISTINCT program_name) as UNIQUE_PROGRAMS,
    SUM(cpu_time) as TOTAL_CPU_TIME_MS,
    SUM(memory_usage) as TOTAL_MEMORY_PAGES,
    MIN(login_time) as FIRST_LOGIN_TIME,
    MAX(login_time) as LAST_LOGIN_TIME
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
GROUP BY login_name
ORDER BY COUNT(*) DESC;

-- 5. PROCESOS DE LARGA DURACIÓN
SELECT 
    'LONG_RUNNING_QUERIES' as SECTION,
    s.session_id as SESSION_ID,
    s.login_name as LOGIN_NAME,
    s.host_name as HOST_NAME,
    s.program_name as PROGRAM_NAME,
    r.start_time as START_TIME,
    DATEDIFF(MINUTE, r.start_time, GETDATE()) as DURATION_MINUTES,
    r.status as REQUEST_STATUS,
    r.command as COMMAND_TYPE,
    r.percent_complete as PERCENT_COMPLETE,
    r.estimated_completion_time / 1000 / 60 as ESTIMATED_COMPLETION_MINUTES,
    r.cpu_time as CPU_TIME_MS,
    r.reads as READS,
    r.writes as WRITES,
    r.logical_reads as LOGICAL_READS,
    SUBSTRING(st.text, (r.statement_start_offset/2)+1, 
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2) + 1) as CURRENT_SQL
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE DATEDIFF(MINUTE, r.start_time, GETDATE()) > 5  -- Consultas de más de 5 minutos
ORDER BY DATEDIFF(MINUTE, r.start_time, GETDATE()) DESC;

-- 6. ESTADÍSTICAS DE ESPERAS
SELECT 
    'WAIT_STATISTICS' as SECTION,
    wait_type as WAIT_TYPE,
    waiting_tasks_count as WAITING_TASKS_COUNT,
    wait_time_ms as TOTAL_WAIT_TIME_MS,
    max_wait_time_ms as MAX_WAIT_TIME_MS,
    signal_wait_time_ms as SIGNAL_WAIT_TIME_MS,
    wait_time_ms - signal_wait_time_ms as RESOURCE_WAIT_TIME_MS,
    CASE 
        WHEN waiting_tasks_count = 0 THEN 0
        ELSE wait_time_ms / waiting_tasks_count
    END as AVG_WAIT_TIME_MS,
    CASE 
        WHEN SUM(wait_time_ms) OVER() = 0 THEN 0
        ELSE CAST(100.0 * wait_time_ms / SUM(wait_time_ms) OVER() AS DECIMAL(5,2))
    END as PERCENTAGE_OF_TOTAL
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
    'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE',
    'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT',
    'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT',
    'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
    'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'HADR_FILESTREAM_IOMGR_IOCOMPLETION'
)
AND wait_time_ms > 0
ORDER BY wait_time_ms DESC;

-- 7. LOCKS ACTUALES
SELECT 
    'CURRENT_LOCKS' as SECTION,
    l.resource_type as RESOURCE_TYPE,
    l.resource_database_id as DATABASE_ID,
    DB_NAME(l.resource_database_id) as DATABASE_NAME,
    l.resource_associated_entity_id as ENTITY_ID,
    l.request_mode as REQUEST_MODE,
    l.request_type as REQUEST_TYPE,
    l.request_status as REQUEST_STATUS,
    l.request_session_id as SESSION_ID,
    s.login_name as LOGIN_NAME,
    s.host_name as HOST_NAME,
    s.program_name as PROGRAM_NAME,
    CASE l.resource_type
        WHEN 'OBJECT' THEN OBJECT_NAME(l.resource_associated_entity_id, l.resource_database_id)
        WHEN 'DATABASE' THEN DB_NAME(l.resource_database_id)
        ELSE CAST(l.resource_associated_entity_id AS VARCHAR(20))
    END as RESOURCE_NAME
FROM sys.dm_tran_locks l
LEFT JOIN sys.dm_exec_sessions s ON l.request_session_id = s.session_id
WHERE l.resource_database_id = DB_ID()
ORDER BY l.resource_type, l.request_session_id;
