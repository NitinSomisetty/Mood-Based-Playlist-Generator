-- RLS is enabled as defense in depth. API routes also enforce ownership.
ALTER TABLE users ENABLE ROW LEVEL SECURITY; ALTER TABLE playlists ENABLE ROW LEVEL SECURITY; ALTER TABLE playlist_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS users_self_or_admin ON users;
CREATE POLICY users_self_or_admin ON users
  USING(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid OR current_setting('app.role',true)='ADMIN')
  WITH CHECK(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid OR current_setting('app.role',true)='ADMIN');
DROP POLICY IF EXISTS playlists_owner_or_admin ON playlists;
CREATE POLICY playlists_owner_or_admin ON playlists
  USING(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid OR current_setting('app.role',true)='ADMIN')
  WITH CHECK(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid OR current_setting('app.role',true)='ADMIN');
DROP POLICY IF EXISTS history_owner_or_admin ON playlist_history;
CREATE POLICY history_owner_or_admin ON playlist_history
  USING(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid OR current_setting('app.role',true)='ADMIN')
  WITH CHECK(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid OR current_setting('app.role',true)='ADMIN');
