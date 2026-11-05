$ErrorActionPreference = "Stop"

if (-not $env:DATABASE_URL) {
  throw "DATABASE_URL is not set. Load it from .env.local before running this script."
}

$files = @(
  "db/00_extensions_check.sql",
  "db/01_schema.sql",
  "db/02_seed_data.sql",
  "db/04_advanced.sql",
  "db/06_rls_policies.sql"
)

foreach ($file in $files) {
  Write-Host "Applying $file..."
  & psql $env:DATABASE_URL -v ON_ERROR_STOP=1 -f $file
  if ($LASTEXITCODE -ne 0) {
    throw "Failed while applying $file."
  }
}

Write-Host "Database setup complete."
