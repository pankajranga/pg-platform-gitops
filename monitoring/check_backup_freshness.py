#!/usr/bin/env python3
"""
check_backup_freshness.py

Checks the GCS bucket used for WAL-G/Zalando Postgres backups and verifies
that a base backup has completed successfully within the last N hours.
Exits 0 (OK) or 1 (ALERT) so this can be wired into cron, a monitoring
check, or a CI job.

Auth: uses Application Default Credentials - run
`gcloud auth application-default login` first (same credentials already
used for Terraform in this project), or set GOOGLE_APPLICATION_CREDENTIALS
to a service account key with storage.objectViewer on the bucket.
"""

import sys
import argparse
from datetime import datetime, timezone

from google.cloud import storage

# A completed WAL-G base backup always produces a "*_backup_stop_sentinel.json"
# marker file once the backup finishes successfully - an in-progress or failed
# backup will not have one. Using this marker (rather than just "any object
# exists") is what actually confirms a *completed* backup, not a partial one.
SENTINEL_SUFFIX = "_backup_stop_sentinel.json"


def find_latest_backup(bucket_name: str, prefix: str):
    """Return (blob_name, updated_datetime) for the most recent completed
    base backup under the given prefix, or None if none exist."""
    client = storage.Client()
    bucket = client.bucket(bucket_name)

    latest_blob = None
    latest_time = None

    for blob in bucket.list_blobs(prefix=prefix):
        if blob.name.endswith(SENTINEL_SUFFIX):
            if latest_time is None or blob.updated > latest_time:
                latest_time = blob.updated
                latest_blob = blob.name

    if latest_blob is None:
        return None
    return latest_blob, latest_time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bucket", default="panka-pg-backups-2026",
                         help="GCS bucket holding WAL-G backups")
    parser.add_argument("--prefix",
                         default="spilo/acid-day2-cluster/620a0148-d72a-4815-8606-71d281e5653d/wal/16/basebackups_005/",
                         help="Prefix under the bucket where base backups live")
    parser.add_argument("--max-age-hours", type=float, default=24.0,
                         help="Alert if the most recent completed backup is older than this")
    args = parser.parse_args()

    result = find_latest_backup(args.bucket, args.prefix)

    if result is None:
        print(f"ALERT: No completed base backup found at all under "
              f"gs://{args.bucket}/{args.prefix}")
        sys.exit(1)

    blob_name, updated = result
    age_hours = (datetime.now(timezone.utc) - updated).total_seconds() / 3600

    if age_hours > args.max_age_hours:
        print(f"ALERT: Most recent backup is {age_hours:.1f} hours old "
              f"(threshold: {args.max_age_hours} hours)")
        print(f"       Last completed backup: {blob_name} (at {updated.isoformat()})")
        sys.exit(1)

    print(f"OK: Most recent backup is {age_hours:.1f} hours old "
          f"(within {args.max_age_hours}-hour threshold)")
    print(f"    Last completed backup: {blob_name} (at {updated.isoformat()})")
    sys.exit(0)


if __name__ == "__main__":
    main()