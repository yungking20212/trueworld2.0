-- Trueworld 2.0: Planetary Resource Security (RLS)
-- Run this in your Supabase SQL Editor to authorize Neural XP Events.

-- 1. XP EVENTS SECURITY
-- Ensure the xp_events table exists (internal log of neural transactions)
CREATE TABLE IF NOT EXISTS xp_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id),
  type text NOT NULL, -- 'LIKE_AWARD', 'VIEW_AWARD', 'STORY_AWARD'
  amount integer NOT NULL,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

-- Activate Global RLS for XP
ALTER TABLE xp_events ENABLE ROW LEVEL SECURITY;

-- 2. ACCESS POLICIES
-- Policy: Allow users to see their own Neural XP history
DROP POLICY IF EXISTS "Users can view their own XP events" ON xp_events;
CREATE POLICY "Users can view their own XP events" 
ON xp_events FOR SELECT 
USING (auth.uid() = user_id);

-- Policy: Allow the system to generate XP events when social triggers fire
-- Since triggers run as the performing user, we must allow the user to 'INSERT' their contribution to the author's XP
DROP POLICY IF EXISTS "Authenticated users can trigger XP events" ON xp_events;
CREATE POLICY "Authenticated users can trigger XP events" 
ON xp_events FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- 3. BROADCAST VERIFICATION
-- Grant Public access to view aggregate XP (if needed for leaderboards)
-- (Leave disabled for now for privacy, can be toggled later)
