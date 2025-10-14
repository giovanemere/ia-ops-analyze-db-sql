#!/usr/bin/env python3
"""
Generador ERD Avanzado con Mermaid para SQL Azure Database
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime

# Agregar shared al path
sys.path.append(str(Path(__file__).parent.parent / "shared"))

class EnhancedERDGenerator:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.output_dir = self.project_root / "global" / "docs"
        
    def generate_complete_erd(self):
        """Genera ERD completo con diagramas Mermaid"""
        print("🚀 Generando ERD completo para SQL Azure Database")
        
        # Simular análisis de estructura (en implementación real conectaría a BD)
        tables_info = self._get_tables_structure()
        
        # Generar diagrama Mermaid
        mermaid_diagram = self._generate_mermaid_diagram(tables_info)
        
        # Crear documentación completa
        documentation = self._generate_documentation(tables_info, mermaid_diagram)
        
        # Guardar archivos
        self._save_files(documentation, mermaid_diagram)
        
        print("✅ ERD completo generado exitosamente")
        
    def _get_tables_structure(self):
        """Obtiene estructura de tablas (simulado)"""
        return {
            "CuponesDigitales": {
                "columns": ["Id", "CodigoPromocion", "FechaCreacion", "Estado"],
                "primary_key": "Id",
                "relationships": ["Promociones"]
            },
            "CuponesFisicoCorreccion": {
                "columns": ["Id", "CodigoCupon", "FechaCorreccion", "Motivo"],
                "primary_key": "Id", 
                "relationships": ["CuponesDigitales"]
            },
            "Promociones": {
                "columns": ["Id", "Nombre", "FechaInicio", "FechaFin"],
                "primary_key": "Id",
                "relationships": []
            }
        }
    
    def _generate_mermaid_diagram(self, tables_info):
        """Genera diagrama Mermaid"""
        diagram = "erDiagram\n"
        
        for table, info in tables_info.items():
            diagram += f"    {table} {{\n"
            for col in info["columns"]:
                key_type = "PK" if col == info["primary_key"] else ""
                diagram += f"        {col} {key_type}\n"
            diagram += "    }\n"
        
        # Agregar relaciones
        for table, info in tables_info.items():
            for rel in info["relationships"]:
                diagram += f"    {table} ||--o{{ {rel} : references\n"
        
        return diagram
    
    def _generate_documentation(self, tables_info, mermaid_diagram):
        """Genera documentación completa"""
        doc = f"""# 📊 ERD - SQL Analysis Project

## Generado: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 🗄️ Diagrama de Entidad-Relación

```mermaid
{mermaid_diagram}
```

## 📋 Estructura de Tablas

"""
        
        for table, info in tables_info.items():
            doc += f"### {table}\n"
            doc += f"- **Primary Key:** {info['primary_key']}\n"
            doc += f"- **Columnas:** {len(info['columns'])}\n"
            doc += f"- **Relaciones:** {len(info['relationships'])}\n\n"
            
            doc += "| Columna | Tipo | Descripción |\n"
            doc += "|---------|------|-------------|\n"
            for col in info["columns"]:
                doc += f"| {col} | - | - |\n"
            doc += "\n"
        
        return doc
    
    def _save_files(self, documentation, mermaid_diagram):
        """Guarda archivos generados"""
        self.output_dir.mkdir(exist_ok=True)
        
        # Guardar documentación
        doc_file = self.output_dir / "database_erd.md"
        with open(doc_file, 'w') as f:
            f.write(documentation)
        
        # Guardar diagrama Mermaid separado
        mermaid_file = self.output_dir / "database_diagram.mmd"
        with open(mermaid_file, 'w') as f:
            f.write(mermaid_diagram)
        
        print(f"📄 Documentación: {doc_file}")
        print(f"📊 Diagrama: {mermaid_file}")

def main():
    generator = EnhancedERDGenerator()
    generator.generate_complete_erd()

if __name__ == "__main__":
    main()
