#!/usr/bin/env python3
"""
Generador de Templates - Crea código SQL personalizado
"""

from pathlib import Path
from datetime import datetime
import json

class TemplateGenerator:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.templates_dir = self.project_root / "shared" / "templates"
        self.output_dir = self.project_root / "global" / "generated"
        
    def generate_optimization_script(self, config=None):
        """Genera script de optimización personalizado"""
        print("🔧 Generando script de optimización...")
        
        # Configuración por defecto
        default_config = {
            "database_name": "persqldbmotorpromocprd",
            "fragmentation_threshold": 30,
            "fill_factor": 90,
            "indexes": [
                {
                    "index_name": "IX_CuponesDigitales_FechaCreacion",
                    "table_name": "CuponesDigitales", 
                    "columns": "FechaCreacion, Estado",
                    "include_columns": "CodigoPromocion"
                }
            ]
        }
        
        config = config or default_config
        
        # Leer template
        template_path = self.templates_dir / "scripts" / "optimization_template.sql"
        if not template_path.exists():
            print(f"❌ Template no encontrado: {template_path}")
            return
        
        with open(template_path, 'r') as f:
            template_content = f.read()
        
        # Reemplazar variables
        generated_content = template_content.replace("{{timestamp}}", datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        generated_content = generated_content.replace("{{database_name}}", config["database_name"])
        generated_content = generated_content.replace("{{fragmentation_threshold}}", str(config["fragmentation_threshold"]))
        
        # Generar sección de índices
        indexes_section = ""
        for idx in config["indexes"]:
            index_sql = f"""CREATE NONCLUSTERED INDEX [{idx['index_name']}] 
ON [{idx['table_name']}] ({idx['columns']})"""
            if idx.get('include_columns'):
                index_sql += f"\nINCLUDE ({idx['include_columns']})"
            index_sql += f"\nWITH (ONLINE = ON, FILLFACTOR = {config['fill_factor']});\n\n"
            indexes_section += index_sql
        
        generated_content = generated_content.replace("{{#indexes}}", "").replace("{{/indexes}}", "")
        generated_content = generated_content.replace("{{index_name}}", "").replace("{{table_name}}", "").replace("{{columns}}", "").replace("{{include_columns}}", "").replace("{{fill_factor}}", "")
        
        # Insertar índices generados
        generated_content = generated_content.replace("-- Crear índices optimizados", f"-- Crear índices optimizados\n{indexes_section}")
        
        # Guardar archivo generado
        self.output_dir.mkdir(exist_ok=True)
        output_file = self.output_dir / f"optimization_script_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"
        
        with open(output_file, 'w') as f:
            f.write(generated_content)
        
        print(f"✅ Script generado: {output_file}")
        return output_file
    
    def generate_analysis_query(self, top_count=10, impact_threshold=1000):
        """Genera query de análisis personalizada"""
        print("📊 Generando query de análisis...")
        
        template_path = self.templates_dir / "queries" / "performance_analysis.sql"
        if not template_path.exists():
            print(f"❌ Template no encontrado: {template_path}")
            return
        
        with open(template_path, 'r') as f:
            template_content = f.read()
        
        # Reemplazar variables
        generated_content = template_content.replace("{{database_name}}", "persqldbmotorpromocprd")
        generated_content = generated_content.replace("{{top_count}}", str(top_count))
        generated_content = generated_content.replace("{{impact_threshold}}", str(impact_threshold))
        
        # Guardar archivo generado
        output_file = self.output_dir / f"analysis_query_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"
        
        with open(output_file, 'w') as f:
            f.write(generated_content)
        
        print(f"✅ Query generada: {output_file}")
        return output_file

def main():
    generator = TemplateGenerator()
    
    print("🛠️ Generador de Templates SQL")
    print("=" * 30)
    
    # Generar script de optimización
    generator.generate_optimization_script()
    
    # Generar query de análisis
    generator.generate_analysis_query(top_count=20, impact_threshold=500)
    
    print("✅ Templates generados exitosamente")

if __name__ == "__main__":
    main()
