-- Projects are the primary construction-work tracking entity.
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  client_name text,
  project_code text,
  address text,
  budget numeric(14, 2) not null default 0,
  estimated_cost numeric(14, 2) not null default 0,
  current_cost numeric(14, 2) not null default 0,
  spent numeric(14, 2) not null default 0,
  status text not null default 'planning'
    check (status in ('planning', 'active', 'completed', 'delayed')),
  start_date date,
  expected_completion date,
  supervisor_id uuid,
  notes text,
  description text,
  is_archived boolean not null default false,
  deadline date,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now())
);

create index if not exists projects_status_idx on public.projects (status);
create index if not exists projects_created_at_idx on public.projects (created_at desc);

alter table public.projects enable row level security;

drop policy if exists "Authenticated users can view projects" on public.projects;
create policy "Authenticated users can view projects"
  on public.projects for select
  to authenticated
  using (true);

drop policy if exists "Authenticated users can create projects" on public.projects;
create policy "Authenticated users can create projects"
  on public.projects for insert
  to authenticated
  with check (true);

drop policy if exists "Authenticated users can update projects" on public.projects;
create policy "Authenticated users can update projects"
  on public.projects for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Authenticated users can delete projects" on public.projects;
create policy "Authenticated users can delete projects"
  on public.projects for delete
  to authenticated
  using (true);
