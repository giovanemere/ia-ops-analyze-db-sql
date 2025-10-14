-- =====================================================
-- ANÁLISIS DE SESIONES Y CONEXIONES
-- Sesiones activas, bloqueos, procesos
-- =====================================================

PRINT '👥 ANÁLISIS DE SESIONES Y CONEXIONES';
PRINT '====================================';

-- Resumen de sesiones activas
SELECT 
    'SESSION_SUMMARY' as SummaryType,
    COUNT(*) as TotalSessions,
    SUM(CASE WHEN is_user_process = 1 THEN 1 ELSE 0 END) as UserSessions,
    SUM(CASE WHEN is_user_process = 0 THEN 1 ELSE 0 END) as SystemSessions,
    SUM(CASE WHEN status = 'running' THEN 1 ELSE 0 END) as RunningSessions,
    SUM(CASE WHEN status = 'sleeping' THEN 1 ELSE 0 END) as SleepingSessions
FROM sys.dm_exec_sessions;

-- Sesiones activas con más detalle
SELECT TOP 20
    'ACTIVE_SESSIONS' as SessionType,
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status,
    s.cpu_time,
    s.memory_usage,
    s.total_scheduled_time,
    s.total_elapsed_time,
    s.last_request_start_time,
    s.last_request_end_time,
    CASE 
        WHEN r.session_id IS NOT NULL THEN 'EXECUTING'
        ELSE 'IDLE'
    END as CurrentState
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
WHERE s.is_user_process = 1
ORDER BY s.cpu_time DESC;

-- Bloqueos activos
SELECT 
    'BLOCKING_SESSIONS' as BlockType,
    blocking.session_id as BlockingSessionId,
    blocked.session_id as BlockedSessionId,
    blocking.login_name as BlockingUser,
    blocked.login_name as BlockedUser,
    blocking.host_name as BlockingHost,
    blocked.host_name as BlockedHost,
    r.wait_type,
    r.wait_time,
    r.wait_resource,
    SUBSTRING(qt.text, (r.statement_start_offset/2)+1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2)+1) as BlockedQuery
FROM sys.dm_exec_requests r
INNER JOIN sys.dm_exec_sessions blocked ON r.session_id = blocked.session_id
INNER JOIN sys.dm_exec_sessions blocking ON r.blocking_session_id = blocking.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) qt
WHERE r.blocking_session_id > 0;

-- Conexiones por aplicación
SELECT 
    'CONNECTIONS_BY_APP' as ConnectionType,
    program_name,
    COUNT(*) as ConnectionCount,
    SUM(cpu_time) as TotalCpuTime,
    AVG(memory_usage) as AvgMemoryUsage
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
    AND program_name IS NOT NULL
GROUP BY program_name
ORDER BY ConnectionCount DESC;

-- Consultas actualmente ejecutándose
SELECT TOP 10
    'RUNNING_QUERIES' as QueryType,
    r.session_id,
    r.status,
    r.command,
    r.cpu_time,
    r.total_elapsed_time,
    r.logical_reads,
    r.writes,
    r.wait_type,
    r.wait_time,
    SUBSTRING(qt.text, (r.statement_start_offset/2)+1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2)+1) as CurrentQuery
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) qt
WHERE r.session_id > 50
ORDER BY r.cpu_time DESC;

PRINT '✅ ANÁLISIS DE SESIONES COMPLETADO';
