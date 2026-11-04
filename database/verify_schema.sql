-- Phase 4 verification. Run in a disposable database or transaction.
-- Each DO block must raise an exception if the expected constraint is absent.

BEGIN;

CREATE TEMPORARY TABLE ddl_test_user (
    user_id BIGINT
);

DO $$
DECLARE
    existing_user_id BIGINT;
    existing_mood_id BIGINT;
    existing_song_id BIGINT;
BEGIN
    INSERT INTO app_users (username, email, password_hash)
    VALUES ('ddl_verify_user', 'ddl_verify@example.com', 'not-a-real-password')
    RETURNING user_id INTO existing_user_id;

    BEGIN
        INSERT INTO app_users (username, email, password_hash)
        VALUES ('ddl_verify_user', 'ddl_duplicate@example.com', 'x');
        RAISE EXCEPTION 'Duplicate username was accepted';
    EXCEPTION
        WHEN unique_violation THEN
            NULL;
    END;

    BEGIN
        INSERT INTO app_users (username, email, password_hash, role)
        VALUES ('ddl_invalid_role', 'ddl_invalid_role@example.com', 'x', 'MODERATOR');
        RAISE EXCEPTION 'Invalid role was accepted';
    EXCEPTION
        WHEN check_violation THEN
            NULL;
    END;

    BEGIN
        INSERT INTO playlists (user_id, mood_id, title)
        VALUES (existing_user_id, -999999, 'Invalid foreign key');
        RAISE EXCEPTION 'Invalid foreign key was accepted';
    EXCEPTION
        WHEN foreign_key_violation THEN
            NULL;
    END;

    BEGIN
        INSERT INTO songs (title, artist, duration)
        VALUES ('Invalid duration', 'DDL Verification', -1);
        RAISE EXCEPTION 'Negative duration was accepted';
    EXCEPTION
        WHEN check_violation THEN
            NULL;
    END;

    INSERT INTO moods (mood_name, description)
    VALUES ('DDL Cascade Verification', 'Temporary verification mood')
    RETURNING mood_id INTO existing_mood_id;

    INSERT INTO songs (title, artist, duration)
    VALUES ('DDL Cascade Verification', 'DDL Verification', 180)
    RETURNING song_id INTO existing_song_id;

    INSERT INTO song_moods (song_id, mood_id, relevance_score)
    VALUES (existing_song_id, existing_mood_id, 0.500);

    DELETE FROM moods WHERE mood_id = existing_mood_id;

    IF EXISTS (SELECT 1 FROM song_moods WHERE mood_id = existing_mood_id) THEN
        RAISE EXCEPTION 'Mood deletion did not cascade to song_moods';
    END IF;
END;
$$;

ROLLBACK;
