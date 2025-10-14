import json
import os
from pathlib import Path
from .universal_connection import UniversalSQLConnection

class DatabaseManager:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.config_file = self.project_root / "config" / "databases.json"
        self.databases_dir = self.project_root / "databases"
        self.config = self._load_config()
    
    def _load_config(self):
        """Carga configuración de bases de datos"""
        if self.config_file.exists():
            with open(self.config_file, 'r') as f:
                return json.load(f)
        return {"databases": {}, "default_database": None}
    
    def get_databases(self):
        """Obtiene lista de bases de datos configuradas"""
        return self.config.get("databases", {})
    
    def get_database_config(self, db_name):
        """Obtiene configuración de una BD específica"""
        return self.config.get("databases", {}).get(db_name)
    
    def get_default_database(self):
        """Obtiene BD por defecto"""
        return self.config.get("default_database")
    
    def create_database_structure(self, db_name, db_config):
        """Crea estructura de directorios para nueva BD"""
        db_dir = self.databases_dir / db_name
        
        # Crear directorios
        subdirs = ['scripts', 'config', 'reports', 'queries', 'docs', 'data']
        for subdir in subdirs:
            (db_dir / subdir).mkdir(parents=True, exist_ok=True)
        
        # Crear README específico
        readme_content = f"""# 🗄️ Base de Datos: {db_name}

## 📊 Información General

- **Servidor:** {db_config.get('server', 'N/A')}
- **Base de Datos:** {db_config.get('name', db_name)}
- **Edición:** {db_config.get('edition', 'N/A')}
- **Tier:** {db_config.get('tier', 'N/A')}
- **Tamaño:** {db_config.get('size_gb', 'N/A')} GB
- **Estado:** {db_config.get('status', 'unknown')}
- **Descripción:** {db_config.get('description', 'N/A')}

## 🚀 Comandos Específicos

```bash
# Estado de esta BD
python3 cli.py db-status {db_name}

# Análisis específico
python3 cli.py erd --database {db_name}
python3 cli.py pipeline --database {db_name}
```

## 📊 Estructura de Archivos

```
{db_name}/
├── scripts/          # Scripts específicos de esta BD
├── config/           # Configuraciones específicas
├── reports/          # Reportes generados
├── queries/          # Queries de análisis
├── docs/             # Documentación específica
└── data/             # Datos de análisis
```
"""
        
        readme_file = db_dir / "README.md"
        with open(readme_file, 'w') as f:
            f.write(readme_content)
        
        # Crear configuración específica
        db_specific_config = {
            "database_info": db_config,
            "optimization_settings": {
                "max_degree_parallelism": 4,
                "cost_threshold_parallelism": 50,
                "fill_factor": 90,
                "fragmentation_threshold": 30
            },
            "monitoring_thresholds": {
                "cpu_warning": 70,
                "cpu_critical": 85,
                "memory_warning": 75,
                "memory_critical": 90
            }
        }
        
        config_file = db_dir / "config" / "database_config.json"
        with open(config_file, 'w') as f:
            json.dump(db_specific_config, f, indent=2)
        
        return db_dir
    
    def setup_new_database(self, db_name, server, username, password, **kwargs):
        """Configura nueva base de datos"""
        # Crear configuración
        db_config = {
            "name": db_name,
            "server": server,
            "username": username,
            "password": password,
            "edition": kwargs.get("edition", "Standard"),
            "tier": kwargs.get("tier", "S1"),
            "size_gb": kwargs.get("size_gb", 1),
            "status": kwargs.get("status", "development"),
            "description": kwargs.get("description", f"Base de datos {db_name}")
        }
        
        # Agregar a configuración
        self.config["databases"][db_name] = db_config
        
        # Guardar configuración
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f, indent=2)
        
        # Crear estructura
        db_dir = self.create_database_structure(db_name, db_config)
        
        return db_dir
    
    def get_connection(self, db_name=None):
        """Obtiene conexión para BD específica"""
        if not db_name:
            db_name = self.get_default_database()
        
        db_config = self.get_database_config(db_name)
        if not db_config:
            raise ValueError(f"Base de datos no configurada: {db_name}")
        
        # Crear conexión específica
        conn = UniversalSQLConnection()
        # Aquí se podría personalizar la conexión por BD
        return conn
