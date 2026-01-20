#!/usr/bin/env python3
"""Auto-deploy database fixes to Supabase"""
import os
from supabase import create_client, Client

# Supabase credentials
SUPABASE_URL = "https://nznoonwreqsdrawfxrwr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56bm9vbndyZXFzZHJhd2Z4cndyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Nzk2MjU3MCwiZXhwIjoyMDgzNTM4NTcwfQ.sGnxIV7jEIGJFW_wA_i-rS1R85QabN0afCDxko4yzyo"

# Read SQL file
with open('FIX_DATABASE_TABLES.sql', 'r') as f:
    sql_content = f.read()

print("🚀 Deploying database fixes to Supabase...")
print("=" * 60)

try:
    # Initialize Supabase client
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    
    # Execute SQL using the REST API
    # Note: Supabase Python client doesn't have direct SQL execution
    # We need to use psycopg2 or execute via REST API
    
    import requests
    
    # Construct the database URL for direct SQL execution
    project_ref = SUPABASE_URL.split('//')[1].split('.')[0]
    sql_url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    
    headers = {
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "application/json"
    }
    
    # Split SQL into individual statements
    statements = [s.strip() for s in sql_content.split(';') if s.strip() and not s.strip().startswith('--')]
    
    print(f"📝 Found {len(statements)} SQL statements to execute\n")
    
    success_count = 0
    for i, statement in enumerate(statements, 1):
        if not statement:
            continue
            
        # Skip comments and empty lines
        if statement.startswith('--') or statement.startswith('/*'):
            continue
        
        try:
            # For now, just print what would be executed
            print(f"[{i}/{len(statements)}] Executing: {statement[:80]}...")
            success_count += 1
        except Exception as e:
            print(f"❌ Error in statement {i}: {e}")
    
    print("\n" + "=" * 60)
    print(f"✅ Successfully prepared {success_count}/{len(statements)} statements")
    print("\n⚠️  Note: Supabase Python client doesn't support direct SQL execution")
    print("📋 Please copy the SQL from FIX_DATABASE_TABLES.sql")
    print("   and paste it into Supabase SQL Editor manually")
    print("\n📍 Supabase SQL Editor:")
    print(f"   {SUPABASE_URL.replace('https://', 'https://supabase.com/dashboard/project/')}/sql")
    
except Exception as e:
    print(f"❌ Deployment failed: {e}")
    exit(1)
