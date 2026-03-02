-- Migration: Create support_tickets table
-- Date: 2026-03-01

-- Ensure required extension for UUID generation exists (Supabase uses pgcrypto)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create support_tickets table
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    subject text NOT NULL,
    message text NOT NULL,
    status text NOT NULL DEFAULT 'open',
    priority text DEFAULT 'normal',
    assigned_to uuid,
    metadata jsonb DEFAULT '{}'::jsonb,
    response text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Optional foreign key constraints (uncomment if your users table exists in public.users)
-- ALTER TABLE public.support_tickets
--     ADD CONSTRAINT fk_support_user FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE SET NULL;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON public.support_tickets (user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets (status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON public.support_tickets (created_at);

-- Trigger to keep updated_at current on row updates
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_support_tickets_updated_at ON public.support_tickets;
CREATE TRIGGER trg_support_tickets_updated_at
BEFORE UPDATE ON public.support_tickets
FOR EACH ROW
EXECUTE PROCEDURE public.update_updated_at_column();
