# Entity Relationship Diagram (EDR) - persqldbmotorpromocprd

## Resumen de la Base de Datos
- **Servidor**: persqlmotorpromocprd.database.windows.net
- **Base de Datos**: persqldbmotorpromocprd
- **Total de Tablas**: 12
- **Total de Columnas**: 114
- **Fecha de Análisis**: 2025-10-10

## Tablas Principales y Volumen de Datos

| Tabla | Registros | Descripción |
|-------|-----------|-------------|
| CuponesDigitales | 45,001,666 | Cupones digitales (tabla principal) |
| CuponesFisicoCorreccion | 12,010,500 | Cupones físicos con correcciones |
| GeneralEstadosCuyOpClientePromocion | 1,051,841 | Estados generales de promociones |
| SolicitudesEstados | 15 | Estados de solicitudes |
| Estados | 5 | Catálogo de estados |
| OpcionesDigitales | 4 | Opciones digitales disponibles |
| Campanna | 4 | Campañas activas |
| Usuarios | 2 | Usuarios del sistema |

## Estructura de Tablas

### 1. Campanna (Tabla Central)
```sql
campannaID (varchar(200)) [PK]
nombre (varchar(100))
fechaInicio (datetime2)
fechaFin (datetime2)
pais (varchar(50))
tipoCampanna (varchar(100))
fechaCreacion (datetime2) DEFAULT sysdatetime()
tieneCupones (bit) DEFAULT 1
ID (int) [PK]
```

### 2. CuponesDigitales (Tabla Principal - 45M registros)
```sql
IDCupon (varchar(50)) [PK]
campannaID (int) [FK → Campanna.ID]
fechaCreacion (datetime2) DEFAULT dateadd(hour,(-5),sysdatetimeoffset())
estadoCuponID (int) [FK → Estados.ID]
coorelativo (varchar(50))
IDSegmentado (varchar(50))
ID (int) [PK]
commerceCode (varchar(100))
taxIdentifier (nvarchar(50)) DEFAULT ''
identifier (nvarchar(20)) DEFAULT ''
```

### 3. CuponesFisicoCorreccion (12M registros)
```sql
IDCupon (varchar(50)) [PK]
campannaID (int) [FK → Campanna.ID]
fechaCreacion (datetime2)
estadoCuponID (int) [FK → Estados.ID]
coorelativo (varchar(50))
IDSegmentado (varchar(50))
ID (int) [PK]
commerceCode (varchar(100))
taxIdentifier (nvarchar(50))
identifier (nvarchar(20))
```

### 4. Estados (Catálogo)
```sql
ID (int) [PK]
nombre (varchar(100))
descripcion (varchar(500))
```

### 5. OpcionesDigitales
```sql
ID (int) [PK]
campannaID (int) [FK → Campanna.ID]
taxIdentifier (varchar(50))
identifier (varchar(50))
estadoOpcionID (int) [FK → Estados.ID]
fechaCreacion (datetime2) DEFAULT sysdatetime()
```

### 6. GeneralEstadosCuyOpClientePromocion (1M registros)
```sql
ID (int) [PK]
taxIdentifier (varchar(50))
identifier (varchar(50))
estadoID (int)
fechaCreacion (datetime2)
campannaID (varchar(100))
```

### 7. Usuarios
```sql
ID (int) [PK]
nombre (varchar(100))
email (varchar(200))
fechaCreacion (datetime2) DEFAULT sysdatetime()
activo (bit) DEFAULT 1
```

### 8. SolicitudesEstados
```sql
ID (int) [PK]
nombre (varchar(100))
descripcion (varchar(500))
```

## Tablas de Auditoría

### 9. Campanna_Auditoria
```sql
AuditID (int) [PK]
campannaID (int)
nombre (varchar(100))
fechaInicio (datetime2)
fechaFin (datetime2)
pais (varchar(50))
tipoCampanna (varchar(100))
fechaCreacion (datetime2)
tieneCupones (bit)
Operacion (varchar(15))
FechaAuditoria (datetime2) DEFAULT sysdatetime()
Usuario (varchar(100))
```

### 10-12. Tablas de Auditoría (Vacías)
- auditoria_c_digital
- auditoria_c_fisico_correccion  
- auditoria_opcion_digital

## Relaciones (Foreign Keys)

```
Campanna (1) ←→ (N) CuponesDigitales
├── FK: CuponesDigitales_Campanna_FK
├── Acción: CASCADE en DELETE/UPDATE

Campanna (1) ←→ (N) CuponesFisicoCorreccion  
├── FK: CuponesFisicoCorreccion_Campanna_FK
├── Acción: CASCADE en DELETE/UPDATE

Campanna (1) ←→ (N) OpcionesDigitales
├── FK: OpcionesDigitales_Campanna_FK
├── Acción: NO_ACTION en DELETE/UPDATE

Estados (1) ←→ (N) CuponesDigitales
├── FK: FK_CuponesDigitales_Estados
├── Acción: NO_ACTION en DELETE/UPDATE

Estados (1) ←→ (N) CuponesFisicoCorreccion
├── FK: FK_CuponesFisicoCorreccion_Estados  
├── Acción: NO_ACTION en DELETE/UPDATE

Estados (1) ←→ (N) OpcionesDigitales
├── FK: FK_OpcionesDigitales_Estados
├── Acción: NO_ACTION en DELETE/UPDATE
```

## Diagrama Visual

```
                    ┌─────────────┐
                    │   Campanna  │
                    │ (4 records) │
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │CuponesDigit.│ │CuponesFisico│ │OpcionesDigi.│
    │(45M records)│ │(12M records)│ │(4 records)  │
    └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
           │               │               │
           └───────────────┼───────────────┘
                           ▼
                    ┌─────────────┐
                    │   Estados   │
                    │ (5 records) │
                    └─────────────┘

    ┌─────────────────────────────────────────────┐
    │              Tablas Auxiliares              │
    ├─────────────┬─────────────┬─────────────────┤
    │   Usuarios  │SolicitudesE.│GeneralEstados...│
    │(2 records)  │(15 records) │(1M records)     │
    └─────────────┴─────────────┴─────────────────┘
```

## Análisis y Observaciones

### ✅ Fortalezas
- Todas las tablas tienen Primary Keys
- Relaciones bien definidas con Foreign Keys
- Sistema de auditoría implementado
- Uso de CASCADE apropiado para datos dependientes

### ⚠️ Áreas de Atención
- Tablas principales muy grandes (45M+ registros)
- Posible necesidad de particionamiento
- Tablas de auditoría vacías (no se están usando)
- Campos con valores por defecto vacíos

### 📊 Recomendaciones
1. Implementar índices en campos de búsqueda frecuente
2. Considerar particionamiento para CuponesDigitales
3. Activar el sistema de auditoría
4. Optimizar consultas en tablas grandes
5. Implementar archivado de datos históricos
