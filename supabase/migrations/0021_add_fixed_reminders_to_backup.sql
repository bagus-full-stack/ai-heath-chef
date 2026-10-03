-- ============================================================================
-- Sauvegarde des créneaux fixes (petit-déjeuner/déjeuner/dîner) en plus des
-- rappels personnalisés déjà sauvegardés (0011_add_weight_hydration_reminder_sync.sql)
-- ============================================================================
-- Jusqu'ici seuls les rappels personnalisés survivaient à une réinstallation ;
-- les créneaux fixes devaient être réactivés manuellement (voir README).
alter table public.custom_reminders_backup
  add column if not exists fixed_reminders jsonb;

comment on column public.custom_reminders_backup.fixed_reminders is
  'Réglages des 3 créneaux fixes (breakfast/lunch/dinner) : {slot: {enabled, hour, minute}}. Null si jamais sauvegardé.';
