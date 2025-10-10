# dagster/test_connection.py
"""
Quick test to verify PostgreSQL connection works.
Run this before building assets.
"""

from resources.database import get_postgres_resource

def test_connection():
    """Test database connection and query Bronze schema."""
    
    db = get_postgres_resource()
    
    try:
        # Test connection
        result = db.fetch_query("""
            SELECT current_database(), current_user, version();
        """)
        
        print("✅ Database Connection Successful!")
        print(f"   Database: {result[0][0]}")
        print(f"   User: {result[0][1]}")
        print(f"   PostgreSQL Version: {result[0][2][:50]}...")
        
        # Check if Bronze tables exist
        tables = db.fetch_query("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'bronze'
            ORDER BY table_name;
        """)
        
        print("\n✅ Bronze Tables Found:")
        for table in tables:
            print(f"   - bronze.{table[0]}")
        
        print("\n🎉 Everything looks good! Ready to build assets.")
        
    except Exception as e:
        print(f"❌ Connection Failed: {e}")
        print("\nPlease check:")
        print("  1. PostgreSQL is running")
        print("  2. .env file has correct credentials")
        print("  3. Database 'financial_index_db' exists")


if __name__ == "__main__":
    test_connection()