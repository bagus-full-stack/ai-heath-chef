-- Étend l'analyse nutritionnelle au-delà des macros de base
-- (protéines/glucides/lipides) : fibres, sucres et graisses saturées.
alter table health_chef.meals
  add column if not exists total_fiber   numeric(7, 2) not null default 0 check (total_fiber >= 0),
  add column if not exists total_sugar   numeric(7, 2) not null default 0 check (total_sugar >= 0),
  add column if not exists total_sat_fat numeric(7, 2) not null default 0 check (total_sat_fat >= 0);
