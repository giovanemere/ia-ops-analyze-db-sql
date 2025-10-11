-- =====================================================
-- SEGURIDAD Y PERMISOS DE LA BASE DE DATOS
-- Usuarios, Roles, Permisos, etc.
-- =====================================================

-- 1. USUARIOS DE BASE DE DATOS
SELECT 
    'DATABASE_USERS' as SECTION,
    dp.name as PRINCIPAL_NAME,
    dp.type_desc as PRINCIPAL_TYPE,
    dp.authentication_type_desc as AUTHENTICATION_TYPE,
    dp.default_schema_name as DEFAULT_SCHEMA,
    dp.create_date as CREATED_DATE,
    dp.modify_date as MODIFIED_DATE,
    CASE WHEN dp.is_fixed_role = 1 THEN 'YES' ELSE 'NO' END as IS_FIXED_ROLE,
    sp.name as SERVER_PRINCIPAL_NAME
FROM sys.database_principals dp
LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE dp.type NOT IN ('R') -- Excluir roles por ahora
ORDER BY dp.type_desc, dp.name;

-- 2. ROLES DE BASE DE DATOS
SELECT 
    'DATABASE_ROLES' as SECTION,
    dp.name as ROLE_NAME,
    dp.type_desc as ROLE_TYPE,
    dp.create_date as CREATED_DATE,
    dp.modify_date as MODIFIED_DATE,
    CASE WHEN dp.is_fixed_role = 1 THEN 'YES' ELSE 'NO' END as IS_FIXED_ROLE,
    COUNT(rm.role_principal_id) as MEMBER_COUNT
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.role_principal_id
WHERE dp.type = 'R'
GROUP BY dp.name, dp.type_desc, dp.create_date, dp.modify_date, dp.is_fixed_role
ORDER BY dp.name;

-- 3. MEMBRESÍA DE ROLES
SELECT 
    'ROLE_MEMBERS' as SECTION,
    r.name as ROLE_NAME,
    m.name as MEMBER_NAME,
    m.type_desc as MEMBER_TYPE
FROM sys.database_role_members rm
INNER JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
INNER JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
ORDER BY r.name, m.name;

-- 4. PERMISOS EXPLÍCITOS
SELECT 
    'EXPLICIT_PERMISSIONS' as SECTION,
    dp.class_desc as PERMISSION_CLASS,
    dp.permission_name as PERMISSION_NAME,
    dp.state_desc as PERMISSION_STATE,
    pr.name as PRINCIPAL_NAME,
    pr.type_desc as PRINCIPAL_TYPE,
    CASE 
        WHEN dp.class = 0 THEN 'DATABASE'
        WHEN dp.class = 1 THEN OBJECT_SCHEMA_NAME(dp.major_id) + '.' + OBJECT_NAME(dp.major_id)
        WHEN dp.class = 3 THEN SCHEMA_NAME(dp.major_id)
        ELSE 'OTHER'
    END as OBJECT_NAME,
    CASE 
        WHEN dp.class = 1 AND dp.minor_id > 0 THEN COL_NAME(dp.major_id, dp.minor_id)
        ELSE ''
    END as COLUMN_NAME
FROM sys.database_permissions dp
INNER JOIN sys.database_principals pr ON dp.grantee_principal_id = pr.principal_id
WHERE dp.major_id >= 0
ORDER BY pr.name, dp.class_desc, dp.permission_name;

-- 5. ESQUEMAS Y SUS PROPIETARIOS
SELECT 
    'SCHEMAS' as SECTION,
    s.name as SCHEMA_NAME,
    dp.name as SCHEMA_OWNER,
    dp.type_desc as OWNER_TYPE,
    s.schema_id as SCHEMA_ID
FROM sys.schemas s
INNER JOIN sys.database_principals dp ON s.principal_id = dp.principal_id
WHERE s.schema_id > 4 -- Excluir esquemas del sistema
ORDER BY s.name;

-- 6. CERTIFICADOS
SELECT 
    'CERTIFICATES' as SECTION,
    c.name as CERTIFICATE_NAME,
    c.certificate_id as CERTIFICATE_ID,
    c.principal_id as PRINCIPAL_ID,
    dp.name as PRINCIPAL_NAME,
    c.pvt_key_encryption_type_desc as PRIVATE_KEY_ENCRYPTION,
    c.issuer_name as ISSUER_NAME,
    c.subject as SUBJECT,
    c.start_date as VALID_FROM,
    c.expiry_date as VALID_TO
FROM sys.certificates c
LEFT JOIN sys.database_principals dp ON c.principal_id = dp.principal_id
ORDER BY c.name;

-- 7. CLAVES SIMÉTRICAS
SELECT 
    'SYMMETRIC_KEYS' as SECTION,
    sk.name as KEY_NAME,
    sk.key_id as KEY_ID,
    sk.principal_id as PRINCIPAL_ID,
    dp.name as PRINCIPAL_NAME,
    sk.algorithm_desc as ALGORITHM,
    sk.key_length as KEY_LENGTH,
    sk.create_date as CREATED_DATE,
    sk.modify_date as MODIFIED_DATE
FROM sys.symmetric_keys sk
LEFT JOIN sys.database_principals dp ON sk.principal_id = dp.principal_id
WHERE sk.key_id > 100 -- Excluir claves del sistema
ORDER BY sk.name;

-- 8. CLAVES ASIMÉTRICAS
SELECT 
    'ASYMMETRIC_KEYS' as SECTION,
    ak.name as KEY_NAME,
    ak.key_id as KEY_ID,
    ak.principal_id as PRINCIPAL_ID,
    dp.name as PRINCIPAL_NAME,
    ak.algorithm_desc as ALGORITHM,
    ak.key_length as KEY_LENGTH,
    ak.public_key as PUBLIC_KEY_FINGERPRINT,
    ak.thumbprint as THUMBPRINT
FROM sys.asymmetric_keys ak
LEFT JOIN sys.database_principals dp ON ak.principal_id = dp.principal_id
ORDER BY ak.name;
