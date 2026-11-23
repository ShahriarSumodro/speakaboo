"""
Automated Database Backup Script for Speakaboo.

Creates timestamped SQLite backups, runs PRAGMA integrity_check,
and rotates out older archives (retaining the last N backups).
"""

import os
import sys
import shutil
import sqlite3
import datetime
from pathlib import Path

DEFAULT_DB_PATH = os.environ.get("DATABASE_PATH", "speakaboo.db")
DEFAULT_BACKUP_DIR = os.environ.get("BACKUP_DIR", "backups")
MAX_RETAINED_BACKUPS = 14  # Retain 14 daily backups


def backup_database(db_path: str = DEFAULT_DB_PATH, backup_dir: str = DEFAULT_BACKUP_DIR) -> str:
    """Create a verified snapshot backup of the SQLite database."""
    source = Path(db_path)
    if not source.exists():
        print(f"[ERROR] Source database not found at {source}")
        sys.exit(1)

    backup_folder = Path(backup_dir)
    backup_folder.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    target_filename = f"speakaboo_backup_{timestamp}.db"
    target_path = backup_folder / target_filename

    print(f"[*] Starting backup from {source} to {target_path}...")

    # Use SQLite online backup API to ensure ACID consistency without locks
    src_conn = sqlite3.connect(str(source))
    dest_conn = sqlite3.connect(str(target_path))

    with dest_conn:
        src_conn.backup(dest_conn)

    dest_conn.close()
    src_conn.close()

    # Integrity verification on backup copy
    verify_conn = sqlite3.connect(str(target_path))
    cursor = verify_conn.cursor()
    cursor.execute("PRAGMA integrity_check;")
    result = cursor.fetchone()
    verify_conn.close()

    if result and result[0] == "ok":
        size_kb = target_path.stat().st_size / 1024
        print(f"[SUCCESS] Database backup verified successfully ({size_kb:.1f} KB): {target_path}")
    else:
        print(f"[FATAL] Backup integrity check failed: {result}")
        if target_path.exists():
            target_path.unlink()
        sys.exit(2)

    # Rotate old backups
    all_backups = sorted(backup_folder.glob("speakaboo_backup_*.db"))
    if len(all_backups) > MAX_RETAINED_BACKUPS:
        excess = len(all_backups) - MAX_RETAINED_BACKUPS
        for old_b in all_backups[:excess]:
            print(f"[-] Pruning old backup: {old_b.name}")
            old_b.unlink()

    return str(target_path)


if __name__ == "__main__":
    db = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DB_PATH
    dest = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_BACKUP_DIR
    backup_database(db, dest)
