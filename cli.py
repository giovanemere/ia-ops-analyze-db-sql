#!/usr/bin/env python3
"""
CLI Avanzado - SQL Analysis Project
Comandos completos para análisis y optimización
"""

import os
import sys
import subprocess
from pathlib import Path

class SQLAnalysisCLI:
    def __init__(self):
        self.project_root = Path(__file__).parent
        self.modules_dir = self.project_root / "modules"
        self.tools_dir = self.project_root / "tools"
        
    def status(self):
        """Muestra estado del sistema"""
        print("🗄️ SQL Analysis Project - Estado del Sistema")
        print("=" * 50)
        
        # Verificar módulos base
        modules = ['backup', 'optimization', 'dictionary', 'infrastructure']
        for module in modules:
            module_path = self.modules_dir / module
            status = "✅" if module_path.exists() else "❌"
            count = len(list(module_path.glob("*"))) if module_path.exists() else 0
            print(f"{status} Módulo {module}: {count} archivos")
        
        # Verificar herramientas
        tools_count = len(list(self.tools_dir.glob("*.py"))) if self.tools_dir.exists() else 0
        print(f"✅ Herramientas: {tools_count} archivos")
        
        # Verificar bases de datos
        databases_dir = self.project_root / "databases"
        if databases_dir.exists():
            db_count = len([d for d in databases_dir.iterdir() if d.is_dir()])
            print(f"🗄️ Bases de datos: {db_count} configuradas")
        
        # Verificar estructura global
        global_dir = self.project_root / "global"
        if global_dir.exists():
            logs_count = len(list((global_dir / "logs").glob("*"))) if (global_dir / "logs").exists() else 0
            reports_count = len(list((global_dir / "reports").glob("*"))) if (global_dir / "reports").exists() else 0
            print(f"📋 Logs globales: {logs_count} archivos")
            print(f"📊 Reportes globales: {reports_count} archivos")
    
    def test(self):
        """Prueba conexión"""
        print("🔍 Probando conexión a SQL Azure...")
        
        try:
            sys.path.append(str(self.project_root / "shared"))
            from universal_connection import UniversalSQLConnection
            
            conn = UniversalSQLConnection()
            success, message = conn.test_connection()
            
            if success:
                print(f"✅ {message}")
            else:
                print(f"❌ {message}")
                
        except ImportError:
            print("⚠️ Módulo de conexión no disponible. Instalar: pip install pyodbc python-dotenv")
        except Exception as e:
            print(f"❌ Error: {str(e)}")
    
    def erd(self):
        """Genera ERD con Mermaid"""
        print("📊 Generando ERD avanzado...")
        script = self.tools_dir / "enhanced_erd_generator.py"
        self._run_python_script(script)
    
    def backup(self):
        """Ejecuta backup"""
        print("💾 Ejecutando backup...")
        script = self.modules_dir / "backup" / "04_backup_azure_cli.sh"
        self._run_script(script)
    
    def optimize(self):
        """Ejecuta optimización"""
        print("⚡ Ejecutando optimización...")
        script = self.modules_dir / "optimization" / "run_optimization.sh"
        self._run_script(script)
    
    def dictionary(self):
        """Genera diccionario"""
        print("📚 Generando diccionario...")
        script = self.modules_dir / "dictionary" / "run_dictionary.sh"
        self._run_script(script)
    
    def repos(self):
        """Analiza repositorios de código"""
        print("🔍 Analizando repositorios...")
        script = self.tools_dir / "repo_analyzer.py"
        self._run_python_script(script)
    
    def workflow(self, phase=None):
        """Ejecuta workflow completo o fase específica"""
        script = self.project_root / "workflows" / "complete_analysis.py"
        if phase:
            print(f"🎯 Ejecutando Fase {phase}...")
            subprocess.run([sys.executable, str(script), "--phase", str(phase)], cwd=self.project_root)
        else:
            print("🚀 Ejecutando workflow completo...")
            subprocess.run([sys.executable, str(script)], cwd=self.project_root)
    
    def monitor(self):
        """Configura y ejecuta monitoreo"""
        print("📊 Configurando monitoreo...")
        script = self.project_root / "workflows" / "monitoring_setup.py"
        self._run_python_script(script)
    
    def list_databases(self):
        """Lista bases de datos configuradas"""
        print("🗄️ Bases de Datos Configuradas:")
        print("=" * 35)
        
        databases_dir = self.project_root / "databases"
        if databases_dir.exists():
            for db_dir in databases_dir.iterdir():
                if db_dir.is_dir():
                    config_file = db_dir / "config" / "database_config.json"
                    if config_file.exists():
                        import json
                        with open(config_file, 'r') as f:
                            config = json.load(f)
                        
                        db_info = config.get('database_info', {})
                        print(f"📊 {db_info.get('name', db_dir.name)}")
                        print(f"   Server: {db_info.get('server', 'N/A')}")
                        print(f"   Edition: {db_info.get('edition', 'N/A')}")
                        print(f"   Size: {db_info.get('size_gb', 'N/A')} GB")
                        print(f"   Status: {db_info.get('status', 'unknown')}")
                        print()
                    else:
                        print(f"📊 {db_dir.name} (sin configuración)")
        else:
            print("❌ No hay bases de datos configuradas")
    
    def database_status(self, db_name):
        """Muestra estado específico de una base de datos"""
        db_dir = self.project_root / "databases" / db_name
        if not db_dir.exists():
            print(f"❌ Base de datos no encontrada: {db_name}")
            return
        
        print(f"🗄️ Estado de: {db_name}")
        print("=" * 40)
        
        # Verificar estructura completa por BD
        subdirs = ['scripts', 'queries', 'reports', 'logs', 'generated', 'docs', 'config']
        for subdir in subdirs:
            subdir_path = db_dir / subdir
            status = "✅" if subdir_path.exists() else "❌"
            count = len(list(subdir_path.glob("*"))) if subdir_path.exists() else 0
            print(f"{status} {subdir}: {count} archivos")
        
        # Mostrar configuración si existe
        config_file = db_dir / "config" / "database_config.json"
        if config_file.exists():
            import json
            with open(config_file, 'r') as f:
                config = json.load(f)
            
            db_info = config.get('database_info', {})
            print(f"\n📊 Información:")
            print(f"   Servidor: {db_info.get('server', 'N/A')}")
            print(f"   Tamaño: {db_info.get('size_gb', 'N/A')} GB")
            print(f"   Estado: {db_info.get('status', 'unknown')}")
            print(f"   Descripción: {db_info.get('description', 'N/A')}")
    
    def test_suite(self):
        """Ejecuta suite de pruebas"""
        print("🧪 Ejecutando suite de pruebas...")
        script = self.project_root / "tools" / "test_suite.py"
        self._run_python_script(script)
    
    def _run_script(self, script_path):
        """Ejecuta script bash si existe"""
        if script_path.exists():
            print(f"🚀 Ejecutando: {script_path.name}")
            os.chmod(script_path, 0o755)
            subprocess.run([str(script_path)], cwd=self.project_root)
        else:
            print(f"❌ Script no encontrado: {script_path}")
    
    def _run_python_script(self, script_path):
        """Ejecuta script Python si existe"""
        if script_path.exists():
            print(f"🚀 Ejecutando: {script_path.name}")
            subprocess.run([sys.executable, str(script_path)], cwd=self.project_root)
        else:
            print(f"❌ Script no encontrado: {script_path}")

def main():
    if len(sys.argv) < 2:
        print("Uso: python cli.py [comando] [opciones]")
        print("Comandos:")
        print("  status                    - Estado del sistema")
        print("  list                      - Lista bases de datos")
        print("  db-status [nombre]        - Estado de BD específica")
        print("  test                      - Prueba conexión")
        print("  erd                       - Genera ERD")
        print("  repos                     - Analiza repositorios")
        print("  compare                   - Compara estados")
        print("  workflow [fase]           - Ejecuta workflow (1-4)")
        print("  pipeline [nivel]          - Pipeline optimización (1-3)")
        print("  monitor                   - Configura monitoreo")
        print("  test-suite                - Ejecuta pruebas")
        print("  backup                    - Ejecuta backup")
        print("  optimize                  - Optimización")
        print("  dictionary                - Diccionario")
        print("  infrastructure            - Análisis infraestructura")
        return
    
    command = sys.argv[1]
    cli = SQLAnalysisCLI()
    
    if command == 'status':
        cli.status()
    elif command == 'list':
        cli.list_databases()
    elif command == 'db-status':
        db_name = sys.argv[2] if len(sys.argv) > 2 else 'persqldbmotorpromocprd'
        cli.database_status(db_name)
    elif command == 'test':
        cli.test()
    elif command == 'erd':
        cli.erd()
    elif command == 'repos':
        cli.repos()
    elif command == 'compare':
        cli.compare()
    elif command == 'workflow':
        phase = int(sys.argv[2]) if len(sys.argv) > 2 else None
        cli.workflow(phase)
    elif command == 'pipeline':
        level = sys.argv[2] if len(sys.argv) > 2 else "all"
        cli.pipeline(level)
    elif command == 'monitor':
        cli.monitor()
    elif command == 'test-suite':
        cli.test_suite()
    elif command == 'backup':
        cli.backup()
    elif command == 'optimize':
        cli.optimize()
    elif command == 'dictionary':
        cli.dictionary()
    elif command == 'infrastructure':
        cli.infrastructure()
    else:
        print(f"❌ Comando desconocido: {command}")
        print("Usar 'python cli.py' para ver comandos disponibles")

if __name__ == "__main__":
    main()
