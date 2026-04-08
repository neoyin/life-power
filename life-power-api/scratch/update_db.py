"""
Database migration script:
  - Adds breathing_sessions column to signal_feature_daily
  - Adds unique constraint (user_id, date) to signal_feature_daily

Usage:
  Local:  python scratch/update_db.py
  Online: DATABASE_URL="postgresql://..." python scratch/update_db.py
"""
import sys
import os
sys.path.append(os.getcwd())

from sqlalchemy import create_engine, text

# Allow override via env var
DATABASE_URL = os.environ.get("DATABASE_URL") or None

if DATABASE_URL is None:
    from app.config import settings
    DATABASE_URL = settings.DATABASE_URL

print(f"Connecting to database: {DATABASE_URL}")

def run_migration():
    print("Connecting to database...")
    engine = create_engine(DATABASE_URL)

    migrations = [
        {
            "description": "Add breathing_sessions column",
            "check": "SELECT column_name FROM information_schema.columns WHERE table_name='signal_feature_daily' AND column_name='breathing_sessions';",
            "sql": "ALTER TABLE signal_feature_daily ADD COLUMN breathing_sessions INTEGER DEFAULT 0;",
        },
        {
            "description": "Add unique constraint (user_id, date)",
            "check": "SELECT constraint_name FROM information_schema.table_constraints WHERE table_name='signal_feature_daily' AND constraint_name='uq_signal_user_date';",
            "sql": "ALTER TABLE signal_feature_daily ADD CONSTRAINT uq_signal_user_date UNIQUE (user_id, date);",
        },
    ]

    with engine.connect() as conn:
        for migration in migrations:
            print(f"\n[?] {migration['description']}...")
            result = conn.execute(text(migration["check"]))
            if not result.fetchone():
                try:
                    conn.execute(text(migration["sql"]))
                    conn.commit()
                    print("[OK] Done.")
                except Exception as e:
                    print(f"[FAIL] Failed: {e}")
                    conn.rollback()
            else:
                print("[SKIP] Already applied.")

    print("\nMigration complete.")

if __name__ == "__main__":
    run_migration()
