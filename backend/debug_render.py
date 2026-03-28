#!/usr/bin/env python3
"""
Render Environment Diagnostic Script
Run this to check what environment variables are available in Render.
"""
import os
import sys

def main():
    print("=== Render Environment Diagnostics ===")
    print(f"Python version: {sys.version}")
    print(f"Current working directory: {os.getcwd()}")
    print()

    # Check for database-related environment variables
    db_vars = [
        'DATABASE_URL',
        'PGHOST', 'PGPORT', 'PGDATABASE', 'PGUSER', 'PGPASSWORD',
        'POSTGRES_URL', 'POSTGRES_PRISMA_URL', 'POSTGRES_URL_NO_SSL',
        'REDIS_URL'
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
        print("   Make sure your Render service has DATABASE_URL set.")
        print("   In Render dashboard: Service > Environment > Add DATABASE_URL")
    else:
        print(f"✅ Found {len(found_db_vars)} database-related environment variables")

    # Check PORT
    port = os.environ.get('PORT')
    if port:
        print(f"✅ PORT is set to: {port}")
    else:
        print("❌ PORT environment variable not set (Render should set this)")

    # Check Render-specific vars
    render_vars = ['RENDER', 'RENDER_SERVICE_ID', 'RENDER_INSTANCE_ID']
    print("\nRender Environment Variables:")
    for var in render_vars:
        value = os.environ.get(var)
        if value:
            print(f"  {var}: {value}")
        else:
            print(f"  {var}: NOT SET")

    print()
    print("=== Next Steps ===")
    if not found_db_vars:
        print("1. In Render dashboard, go to your web service")
        print("2. Go to 'Environment' tab")
        print("3. Add environment variable: DATABASE_URL")
        print("4. Value: Copy from your PostgreSQL database connection string")
        print("5. Redeploy the service")
    else:
        print("1. Check that DATABASE_URL looks correct (should start with postgresql://)")
        print("2. Redeploy and check /health endpoint")
        print("3. If still failing, check Render service logs for more details")

if __name__ == "__main__":
    main()