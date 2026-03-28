#!/usr/bin/env python3
"""
Railway Environment Diagnostic Script
Run this to check what environment variables are available in Railway.
"""
import os
import sys

def main():
    print("=== Railway Environment Diagnostics ===")
    print(f"Python version: {sys.version}")
    print(f"Current working directory: {os.getcwd()}")
    print()

    # Check for database-related environment variables
    db_vars = [
        'DATABASE_URL',
        'PGHOST', 'PGPORT', 'PGDATABASE', 'PGUSER', 'PGPASSWORD',
        'POSTGRES_URL', 'POSTGRES_PRISMA_URL', 'POSTGRES_URL_NO_SSL',
        'RAILWAY_STATIC_URL', 'RAILWAY_PROJECT_ID', 'RAILWAY_ENVIRONMENT_ID'
    ]

    print("Database Environment Variables:")
    found_db_vars = []
    for var in db_vars:
        value = os.environ.get(var)
        if value:
            # Mask password for security
            if 'PASSWORD' in var.upper() or 'URL' in var.upper():
                display_value = value[:20] + "..." if len(value) > 20 else value
            else:
                display_value = value
            print(f"  {var}: {display_value}")
            found_db_vars.append(var)
        else:
            print(f"  {var}: NOT SET")

    print()
    if not found_db_vars:
        print("❌ No database environment variables found!")
        print("   Make sure your Railway service is connected to a Postgres database.")
        print("   In Railway dashboard: Project > Database > Connect to service")
    else:
        print(f"✅ Found {len(found_db_vars)} database-related environment variables")

    # Check PORT
    port = os.environ.get('PORT')
    if port:
        print(f"✅ PORT is set to: {port}")
    else:
        print("❌ PORT environment variable not set (Railway should set this)")

    print()
    print("=== Next Steps ===")
    if not found_db_vars:
        print("1. In Railway dashboard, go to your project")
        print("2. Click on your web service")
        print("3. Go to the 'Database' tab")
        print("4. Click 'Connect' next to your Postgres database")
        print("5. Redeploy the service")
    else:
        print("1. Check that DATABASE_URL looks correct (should start with postgresql:// or ppostgresql://)")
        print("2. Redeploy and check /health endpoint")
        print("3. If still failing, check Railway service logs for more details")

if __name__ == "__main__":
    main()