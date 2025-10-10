# dagster/resources/database.py
"""
Database resource for PostgreSQL connection.
Provides a reusable connection to the financial_index_db.
"""

import os
from contextlib import contextmanager
import psycopg2
from psycopg2.extras import execute_values
from dagster import ConfigurableResource
from dotenv import load_dotenv

# Load environment variables
load_dotenv()


class PostgresResource(ConfigurableResource):
    """
    PostgreSQL database resource for Dagster.
    
    Provides connection management and helper methods for
    database operations in the Bronze layer.
    """
    
    host: str
    port: int
    database: str
    user: str
    password: str
    
    @contextmanager
    def get_connection(self):
        """
        Context manager for database connections.
        Automatically handles connection cleanup.
        """
        conn = psycopg2.connect(
            host=self.host,
            port=self.port,
            database=self.database,
            user=self.user,
            password=self.password
        )
        try:
            yield conn
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            conn.close()
    
    def execute_query(self, query: str, params: tuple = None):
        """Execute a single query (INSERT, UPDATE, DELETE)."""
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(query, params)
                return cur.rowcount
    
    def fetch_query(self, query: str, params: tuple = None):
        """Execute a SELECT query and return all results."""
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(query, params)
                return cur.fetchall()
    
    def bulk_insert(self, table: str, columns: list, data: list):
        """
        Bulk insert data using execute_values for performance.
        
        Args:
            table: Table name (e.g., 'bronze.raw_index_constituents_current')
            columns: List of column names
            data: List of tuples with values
        """
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                query = f"""
                    INSERT INTO {table} ({', '.join(columns)})
                    VALUES %s
                """
                execute_values(cur, query, data)
                return cur.rowcount


def get_postgres_resource() -> PostgresResource:
    """
    Factory function to create PostgreSQL resource from environment variables.
    """
    return PostgresResource(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", 5432)),
        database=os.getenv("DB_NAME", "financial_index_db"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )