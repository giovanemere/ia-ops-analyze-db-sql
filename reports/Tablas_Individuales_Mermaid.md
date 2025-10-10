# Tablas Individuales - Diagramas Mermaid

## 1. Tabla Campanna (Central)

```mermaid
erDiagram
    Campanna {
        varchar campannaID PK "ID único de campaña"
        varchar nombre "Nombre de la campaña"
        datetime2 fechaInicio "Fecha de inicio"
        datetime2 fechaFin "Fecha de finalización"
        varchar pais "País de la campaña"
        varchar tipoCampanna "Tipo de campaña"
        datetime2 fechaCreacion "Fecha de creación"
        bit tieneCupones "Indica si tiene cupones"
        int ID PK "ID numérico"
    }
```

## 2. Tabla CuponesDigitales (45M registros)

```mermaid
erDiagram
    CuponesDigitales {
        varchar IDCupon PK "Identificador único del cupón"
        int campannaID FK "Referencia a Campanna.ID"
        datetime2 fechaCreacion "Fecha de creación del cupón"
        int estadoCuponID FK "Estado actual del cupón"
        varchar coorelativo "Número correlativo"
        varchar IDSegmentado "ID segmentado"
        int ID PK "ID numérico único"
        varchar commerceCode "Código de comercio"
        nvarchar taxIdentifier "Identificador fiscal"
        nvarchar identifier "Identificador adicional"
    }
```

## 3. Tabla CuponesFisicoCorreccion (12M registros)

```mermaid
erDiagram
    CuponesFisicoCorreccion {
        varchar IDCupon PK "Identificador único del cupón"
        int campannaID FK "Referencia a Campanna.ID"
        datetime2 fechaCreacion "Fecha de creación"
        int estadoCuponID FK "Estado del cupón"
        varchar coorelativo "Número correlativo"
        varchar IDSegmentado "ID segmentado"
        int ID PK "ID numérico único"
        varchar commerceCode "Código de comercio"
        nvarchar taxIdentifier "Identificador fiscal"
        nvarchar identifier "Identificador adicional"
    }
```

## 4. Tabla Estados (Catálogo)

```mermaid
erDiagram
    Estados {
        int ID PK "ID único del estado"
        varchar nombre "Nombre del estado"
        varchar descripcion "Descripción del estado"
    }
```

## 5. Tabla OpcionesDigitales

```mermaid
erDiagram
    OpcionesDigitales {
        int ID PK "ID único"
        int campannaID FK "Referencia a Campanna.ID"
        varchar taxIdentifier "Identificador fiscal"
        varchar identifier "Identificador"
        int estadoOpcionID FK "Estado de la opción"
        datetime2 fechaCreacion "Fecha de creación"
    }
```

## 6. Tabla GeneralEstadosCuyOpClientePromocion (1M registros)

```mermaid
erDiagram
    GeneralEstadosCuyOpClientePromocion {
        int ID PK "ID único"
        varchar taxIdentifier "Identificador fiscal"
        varchar identifier "Identificador"
        int estadoID "ID del estado"
        datetime2 fechaCreacion "Fecha de creación"
        varchar campannaID "ID de campaña"
    }
```

## 7. Tabla Usuarios

```mermaid
erDiagram
    Usuarios {
        int ID PK "ID único del usuario"
        varchar nombre "Nombre del usuario"
        varchar email "Email del usuario"
        datetime2 fechaCreacion "Fecha de creación"
        bit activo "Usuario activo"
    }
```

## 8. Tabla SolicitudesEstados

```mermaid
erDiagram
    SolicitudesEstados {
        int ID PK "ID único"
        varchar nombre "Nombre del estado"
        varchar descripcion "Descripción"
    }
```

## Diagrama de Volumen de Datos

```mermaid
pie title Distribución de Registros por Tabla
    "CuponesDigitales" : 45001666
    "CuponesFisicoCorreccion" : 12010500
    "GeneralEstados..." : 1051841
    "Otras tablas" : 50
```

## Diagrama de Dependencias

```mermaid
graph TD
    A[Campanna<br/>Tabla Maestra] --> B[CuponesDigitales<br/>CASCADE]
    A --> C[CuponesFisicoCorreccion<br/>CASCADE]
    A --> D[OpcionesDigitales<br/>NO_ACTION]
    
    E[Estados<br/>Catálogo] --> B
    E --> C
    E --> D
    
    F[Usuarios<br/>Independiente]
    G[SolicitudesEstados<br/>Independiente]
    H[GeneralEstados...<br/>Independiente]
    
    style A fill:#4CAF50,color:#fff
    style E fill:#2196F3,color:#fff
    style B fill:#FF5722,color:#fff
    style C fill:#FF5722,color:#fff
```
