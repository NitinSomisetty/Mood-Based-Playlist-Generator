-- Verify the extensions required by relational and vector features.
SELECT extname, extversion FROM pg_extension WHERE extname IN ('pgcrypto','vector') ORDER BY extname;
