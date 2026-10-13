#!/bin/bash
set -e

for db in meridian_api_production_cache meridian_api_production_queue meridian_api_production_cable
do
  exists=$(psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_database WHERE datname = '$db'")
  if [ "$exists" != "1" ]; then
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE \"$db\" OWNER \"$POSTGRES_USER\""
  fi
done
