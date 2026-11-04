# Migration location

The canonical migration files now live in
[`../../supabase/migrations/`](../../supabase/migrations/) so that the
Supabase CLI can manage them. They were moved from this directory without
copying or changing their SQL.

Do not add a second migration copy here. Use `supabase migration list` and
`supabase db push` from the repository root after linking and verifying the
remote migration history.
