-- Additional database-level validation for existing Supabase tables.
-- Safe to run repeatedly; constraints are added only when absent.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'users_username_length_check'
      AND conrelid = 'users'::regclass
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_username_length_check
      CHECK (char_length(btrim(username)) BETWEEN 2 AND 50);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'users_email_format_check'
      AND conrelid = 'users'::regclass
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_email_format_check
      CHECK (email = lower(btrim(email)) AND position('@' IN email) > 1);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'playlists_name_check'
      AND conrelid = 'playlists'::regclass
  ) THEN
    ALTER TABLE playlists
      ADD CONSTRAINT playlists_name_check
      CHECK (char_length(btrim(name)) BETWEEN 1 AND 255);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'playlists_mood_input_check'
      AND conrelid = 'playlists'::regclass
  ) THEN
    ALTER TABLE playlists
      ADD CONSTRAINT playlists_mood_input_check
      CHECK (mood_input IS NULL OR char_length(btrim(mood_input)) <= 1000);
  END IF;
END;
$$;
