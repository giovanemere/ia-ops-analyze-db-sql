import os
import pyodbc
from dotenv import load_dotenv

class UniversalSQLConnection:
    def __init__(self):
        load_dotenv()
        self.connection = None
        
        # Configuración desde .env
        self.config = {
            'server': os.getenv('SQL_SERVER'),
            'database': os.getenv('SQL_DATABASE'),
            'username': os.getenv('SQL_USERNAME'),
            'password': os.getenv('SQL_PASSWORD')
        }
    
    def get_connection(self):
        """Obtiene conexión a SQL Azure"""
        if not self.connection:
            connection_string = (
                f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                f"SERVER={self.config['server']};"
                f"DATABASE={self.config['database']};"
                f"UID={self.config['username']};"
                f"PWD={self.config['password']};"
                f"Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
            )
            
            try:
                self.connection = pyodbc.connect(connection_string)
                return self.connection
            except Exception as e:
                raise ConnectionError(f"Error conectando a SQL Azure: {str(e)}")
        
        return self.connection
    
    def execute_query(self, query):
        """Ejecuta query y retorna resultados"""
        conn = self.get_connection()
        cursor = conn.cursor()
        
        try:
            cursor.execute(query)
            if query.strip().upper().startswith('SELECT'):
                return cursor.fetchall()
            else:
                conn.commit()
                return cursor.rowcount
        except Exception as e:
            conn.rollback()
            raise Exception(f"Error ejecutando query: {str(e)}")
        finally:
            cursor.close()
    
    def test_connection(self):
        """Prueba conexión a la base de datos"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            cursor.close()
            return True, "Conexión exitosa"
        except Exception as e:
            return False, f"Error de conexión: {str(e)}"
    
    def close(self):
        """Cierra conexión"""
        if self.connection:
            self.connection.close()
            self.connection = None
