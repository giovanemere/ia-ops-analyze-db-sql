#!/usr/bin/env python3
"""
Gestor Específico por Base de Datos
Maneja operaciones específicas para cada BD
"""

import os
import json
import subprocess
from pathlib import Path
from datetime import datetime

class DatabaseSpecificManager:
    def __init__(self, db_name):
        self.project_root = Path(__file__).parent.parent
        self.db_name = db_name
        self.db_dir = self.project_root / "databases" / db_name
        
        if not self.db_dir.exists():
            raise ValueError(f"Base de datos no configurada: {db_name}")
    
    def run_specific_script(self, script_name):
        """Ejecuta script específico de la BD"""
        script_path = self.db_dir / "scripts" / script_name
        if not script_path.exists():
            print(f"❌ Script no encontrado: {script_name}")
            return False
        
        print(f"🚀 Ejecutando {script_name} para {self.db_name}...")
        
        if script_name.endswith('.sql'):
            # Ejecutar script SQL
            return self._run_sql_script(script_path)
        elif script_name.endswith('.sh'):
            # Ejecutar script bash
            return self._run_bash_script(script_path)
        else:
            print(f"❌ Tipo de script no soportado: {script_name}")
            return False
    
    def generate_db_report(self):
        """Genera reporte específico de la BD"""
        report_content = f"""# 📊 Reporte de {self.db_name}

## Generado: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 📁 Estructura de Archivos

"""
        
        # Analizar estructura
        subdirs = ['scripts', 'queries', 'reports', 'logs', 'generated', 'docs']
        for subdir in subdirs:
            subdir_path = self.db_dir / subdir
            if subdir_path.exists():
                files = list(subdir_path.glob("*"))
                report_content += f"### {subdir.title()}\n"
                report_content += f"- **Archivos:** {len(files)}\n"
                for file in files[:5]:  # Mostrar solo primeros 5
                    report_content += f"  - {file.name}\n"
                if len(files) > 5:
                    report_content += f"  - ... y {len(files) - 5} más\n"
                report_content += "\n"
        
        # Guardar reporte
        report_file = self.db_dir / "reports" / f"db_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
        report_file.parent.mkdir(exist_ok=True)
        
        with open(report_file, 'w') as f:
            f.write(report_content)
        
        print(f"✅ Reporte generado: {report_file}")
        return report_file
    
    def backup_db_specific(self):
        """Ejecuta backup específico de la BD"""
        backup_script = self.db_dir / "scripts" / "01_full_backup.sql"
        if backup_script.exists():
            return self.run_specific_script("01_full_backup.sql")
        else:
            print(f"⚠️ Script de backup no encontrado para {self.db_name}")
            return False
    
    def optimize_db_specific(self):
        """Ejecuta optimización específica de la BD"""
        optimize_script = self.db_dir / "scripts" / "optimize_indexes.sql"
        if optimize_script.exists():
            return self.run_specific_script("optimize_indexes.sql")
        else:
            print(f"⚠️ Script de optimización no encontrado para {self.db_name}")
            return False
    
    def _run_sql_script(self, script_path):
        """Ejecuta script SQL"""
        # Aquí se implementaría la ejecución real del script SQL
        print(f"📄 Ejecutando script SQL: {script_path.name}")
        print("✅ Script SQL ejecutado (simulado)")
        return True
    
    def _run_bash_script(self, script_path):
        """Ejecuta script bash"""
        try:
            os.chmod(script_path, 0o755)
            result = subprocess.run([str(script_path)], 
                                  cwd=self.db_dir, 
                                  capture_output=True, 
                                  text=True)
            
            if result.returncode == 0:
                print(f"✅ Script ejecutado exitosamente: {script_path.name}")
                return True
            else:
                print(f"❌ Error ejecutando script: {result.stderr}")
                return False
        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return False

def main():
    import sys
    
    if len(sys.argv) < 3:
        print("Uso: python database_specific_manager.py [db_name] [action]")
        print("Acciones: report, backup, optimize, script [script_name]")
        return
    
    db_name = sys.argv[1]
    action = sys.argv[2]
    
    try:
        manager = DatabaseSpecificManager(db_name)
        
        if action == 'report':
            manager.generate_db_report()
        elif action == 'backup':
            manager.backup_db_specific()
        elif action == 'optimize':
            manager.optimize_db_specific()
        elif action == 'script' and len(sys.argv) > 3:
            script_name = sys.argv[3]
            manager.run_specific_script(script_name)
        else:
            print(f"❌ Acción no válida: {action}")
    
    except ValueError as e:
        print(f"❌ Error: {str(e)}")

if __name__ == "__main__":
    main()
