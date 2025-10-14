#!/usr/bin/env python3
"""
Suite de Pruebas - SQL Analysis Project
Validación integral de funcionalidades
"""

import subprocess
import sys
from pathlib import Path
from datetime import datetime

class TestSuite:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.passed = 0
        self.failed = 0
        
    def run_all_tests(self):
        """Ejecuta suite completa de pruebas"""
        print("🧪 Suite de Pruebas - SQL Analysis Project")
        print("=" * 45)
        
        tests = [
            ("CLI Status", self._test_cli_status),
            ("CLI Help", self._test_cli_help),
            ("ERD Generator", self._test_erd_generator),
            ("Repo Analyzer", self._test_repo_analyzer),
            ("Database Comparator", self._test_database_comparator),
            ("Pipeline Level 1", self._test_pipeline_level1),
            ("Template Generator", self._test_template_generator),
            ("Monitoring Setup", self._test_monitoring_setup),
            ("File Structure", self._test_file_structure),
            ("Configuration Files", self._test_configuration)
        ]
        
        for test_name, test_func in tests:
            self._run_test(test_name, test_func)
        
        self._print_summary()
        
        return self.failed == 0
    
    def _run_test(self, test_name, test_func):
        """Ejecuta prueba individual"""
        print(f"\n🔍 {test_name}...")
        
        try:
            result = test_func()
            if result:
                print(f"✅ {test_name} - PASSED")
                self.passed += 1
            else:
                print(f"❌ {test_name} - FAILED")
                self.failed += 1
        except Exception as e:
            print(f"❌ {test_name} - ERROR: {str(e)}")
            self.failed += 1
    
    def _test_cli_status(self):
        """Prueba comando CLI status"""
        result = subprocess.run([sys.executable, "cli.py", "status"], 
                              cwd=self.project_root, capture_output=True, text=True)
        return result.returncode == 0 and "Estado del Sistema" in result.stdout
    
    def _test_cli_help(self):
        """Prueba ayuda del CLI"""
        result = subprocess.run([sys.executable, "cli.py"], 
                              cwd=self.project_root, capture_output=True, text=True)
        return result.returncode == 0 and "Comandos:" in result.stdout
    
    def _test_erd_generator(self):
        """Prueba generador ERD"""
        result = subprocess.run([sys.executable, "tools/enhanced_erd_generator.py"], 
                              cwd=self.project_root, capture_output=True, text=True)
        return result.returncode == 0 and "ERD completo generado" in result.stdout
    
    def _test_repo_analyzer(self):
        """Prueba analizador de repositorios"""
        result = subprocess.run([sys.executable, "tools/repo_analyzer.py"], 
                              cwd=self.project_root, capture_output=True, text=True)
        return result.returncode == 0 and "Análisis de repositorios completado" in result.stdout
    
    def _test_database_comparator(self):
        """Prueba comparador de BD"""
        result = subprocess.run([sys.executable, "tools/database_comparator.py"], 
                              cwd=self.project_root, capture_output=True, text=True)
        return result.returncode == 0 and "Comparación de estados completada" in result.stdout
    
    def _test_pipeline_level1(self):
        """Prueba pipeline nivel 1"""
        result = subprocess.run([sys.executable, "cli.py", "pipeline", "1"], 
                              cwd=self.project_root, capture_output=True, text=True)
        return result.returncode == 0 and "Nivel 1 completado" in result.stdout
    
    def _test_template_generator(self):
        """Prueba generador de templates"""
        result = subprocess.run([sys.executable, "tools/template_generator.py"], 
                              cwd=self.project_root, capture_output=True, text=True)
        return result.returncode == 0 and "Templates generados exitosamente" in result.stdout
    
    def _test_monitoring_setup(self):
        """Prueba configuración de monitoreo"""
        result = subprocess.run([sys.executable, "workflows/monitoring_setup.py"], 
                              cwd=self.project_root, capture_output=True, text=True)
        return result.returncode == 0 and "Sistema de monitoreo listo" in result.stdout
    
    def _test_file_structure(self):
        """Prueba estructura de archivos"""
        required_dirs = ["modules", "tools", "workflows", "shared", "config", "docs"]
        for dir_name in required_dirs:
            if not (self.project_root / dir_name).exists():
                return False
        return True
    
    def _test_configuration(self):
        """Prueba archivos de configuración"""
        required_files = [".env", "requirements.txt", "cli.py"]
        for file_name in required_files:
            if not (self.project_root / file_name).exists():
                return False
        return True
    
    def _print_summary(self):
        """Imprime resumen de pruebas"""
        total = self.passed + self.failed
        success_rate = (self.passed / total * 100) if total > 0 else 0
        
        print("\n" + "=" * 45)
        print("📊 RESUMEN DE PRUEBAS")
        print("=" * 45)
        print(f"✅ Pruebas exitosas: {self.passed}")
        print(f"❌ Pruebas fallidas: {self.failed}")
        print(f"📈 Tasa de éxito: {success_rate:.1f}%")
        
        if self.failed == 0:
            print("\n🎉 ¡Todas las pruebas pasaron exitosamente!")
        else:
            print(f"\n⚠️ {self.failed} pruebas requieren atención")

def main():
    test_suite = TestSuite()
    success = test_suite.run_all_tests()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
