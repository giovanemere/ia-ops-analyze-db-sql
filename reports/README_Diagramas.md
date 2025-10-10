# 📊 Diagramas EDR - Base de Datos persqldbmotorpromocprd

## 📋 Índice de Diagramas

### 1. [EDR Completo](./EDR_Mermaid.md)
- Diagrama de relaciones completo
- Vista simplificada de negocio  
- Flujo de datos

### 2. [Tablas Individuales](./Tablas_Individuales_Mermaid.md)
- Estructura detallada de cada tabla
- Campos y tipos de datos
- Diagrama de volumen de datos
- Dependencias entre tablas

### 3. [Arquitectura del Sistema](./Arquitectura_Sistema_Mermaid.md)
- Arquitectura de capas
- Flujo de datos principal
- Modelo por dominios
- Análisis de rendimiento

## 🎯 Vista Rápida del Sistema

```mermaid
mindmap
  root((EDR Sistema))
    Campañas
      Campanna (4)
      Campanna_Auditoria (0)
    Cupones
      CuponesDigitales (45M)
      CuponesFisicoCorreccion (12M)
      OpcionesDigitales (4)
    Estados
      Estados (5)
      SolicitudesEstados (15)
      GeneralEstados... (1M)
    Usuarios
      Usuarios (2)
    Auditoría
      auditoria_c_digital (0)
      auditoria_c_fisico_correccion (0)
      auditoria_opcion_digital (0)
```

## 📈 Métricas Clave

| Métrica | Valor |
|---------|-------|
| **Total Tablas** | 12 |
| **Total Registros** | ~58M |
| **Tabla más grande** | CuponesDigitales (45M) |
| **Relaciones FK** | 6 |
| **Tablas con CASCADE** | 2 |

## 🔍 Análisis Visual

### Distribución de Datos
```mermaid
pie title Distribución de Registros
    "CuponesDigitales (77%)" : 45001666
    "CuponesFisicoCorreccion (21%)" : 12010500
    "GeneralEstados... (2%)" : 1051841
    "Otras (<1%)" : 50
```

### Criticidad por Volumen
```mermaid
quadrantChart
    title Análisis de Tablas por Volumen vs Criticidad
    x-axis Bajo Volumen --> Alto Volumen
    y-axis Baja Criticidad --> Alta Criticidad
    
    CuponesDigitales: [0.9, 0.9]
    CuponesFisicoCorreccion: [0.7, 0.8]
    GeneralEstados: [0.5, 0.6]
    Campanna: [0.1, 0.9]
    Estados: [0.1, 0.8]
    OpcionesDigitales: [0.1, 0.5]
    Usuarios: [0.1, 0.3]
    SolicitudesEstados: [0.1, 0.2]
```

## 🚀 Cómo Usar los Diagramas

1. **Para Desarrolladores**: Consulta [Tablas Individuales](./Tablas_Individuales_Mermaid.md)
2. **Para Arquitectos**: Revisa [Arquitectura del Sistema](./Arquitectura_Sistema_Mermaid.md)
3. **Para Analistas**: Usa [EDR Completo](./EDR_Mermaid.md)

## 📝 Notas Importantes

- Los diagramas Mermaid se pueden visualizar en GitHub, GitLab, o herramientas compatibles
- Para editar: usa [Mermaid Live Editor](https://mermaid.live/)
- Los volúmenes de datos son aproximados al momento del análisis

## 🔧 Herramientas Recomendadas

- **Visualización**: GitHub/GitLab (nativo)
- **Edición**: Mermaid Live Editor
- **Documentación**: Markdown + Mermaid
- **Exportación**: mermaid-cli para PNG/SVG
