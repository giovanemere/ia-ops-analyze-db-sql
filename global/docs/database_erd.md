# 📊 ERD - SQL Analysis Project

## Generado: 2025-10-12 13:24:48

## 🗄️ Diagrama de Entidad-Relación

```mermaid
erDiagram
    CuponesDigitales {
        Id PK
        CodigoPromocion 
        FechaCreacion 
        Estado 
    }
    CuponesFisicoCorreccion {
        Id PK
        CodigoCupon 
        FechaCorreccion 
        Motivo 
    }
    Promociones {
        Id PK
        Nombre 
        FechaInicio 
        FechaFin 
    }
    CuponesDigitales ||--o{ Promociones : references
    CuponesFisicoCorreccion ||--o{ CuponesDigitales : references

```

## 📋 Estructura de Tablas

### CuponesDigitales
- **Primary Key:** Id
- **Columnas:** 4
- **Relaciones:** 1

| Columna | Tipo | Descripción |
|---------|------|-------------|
| Id | - | - |
| CodigoPromocion | - | - |
| FechaCreacion | - | - |
| Estado | - | - |

### CuponesFisicoCorreccion
- **Primary Key:** Id
- **Columnas:** 4
- **Relaciones:** 1

| Columna | Tipo | Descripción |
|---------|------|-------------|
| Id | - | - |
| CodigoCupon | - | - |
| FechaCorreccion | - | - |
| Motivo | - | - |

### Promociones
- **Primary Key:** Id
- **Columnas:** 4
- **Relaciones:** 0

| Columna | Tipo | Descripción |
|---------|------|-------------|
| Id | - | - |
| Nombre | - | - |
| FechaInicio | - | - |
| FechaFin | - | - |

