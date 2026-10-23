-- ============================================================================
-- Signalement d'une réponse du coach IA jugée problématique — exigence Google
-- Play (voir docs/AUDIT_CHATBOT.md étape 7, correctif #7).
-- ============================================================================
-- `message_id` référence l'id client (ChatMessage.id, généré localement),
-- pas une clé étrangère vers chat_messages.id (généré côté serveur à
-- l'insertion) : les deux ids ne coïncident jamais aujourd'hui (voir
-- chat_provider.dart, _storeMessage n'a pas de .select()). `excerpt`
-- conserve donc le texte signalé indépendamment de toute jointure.
create table if not exists public.chat_reports (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users (id) on delete cascade,
  message_id     text not null,
  motif          text not null check (motif in ('dangerous', 'incorrect', 'inappropriate', 'other')),
  commentaire    text,
  excerpt        text not null,
  prompt_version integer not null,
  engine         text,
  created_at     timestamptz not null default now()
);

comment on table public.chat_reports is
  'Signalements utilisateur d''une réponse du coach IA (docs/AUDIT_CHATBOT.md étape 7).';

create index if not exists idx_chat_reports_user_id_created_at
  on public.chat_reports (user_id, created_at desc);

alter table public.chat_reports enable row level security;

-- Lecture/écriture limitées au propriétaire — ni update ni delete : un
-- signalement envoyé ne doit pas pouvoir être modifié ou effacé par
-- l'utilisateur qui l'a soumis (preuve de modération).
drop policy if exists "chat_reports_select_own" on public.chat_reports;
create policy "chat_reports_select_own" on public.chat_reports
  for select using (auth.uid() = user_id);

drop policy if exists "chat_reports_insert_own" on public.chat_reports;
create policy "chat_reports_insert_own" on public.chat_reports
  for insert with check (auth.uid() = user_id);
