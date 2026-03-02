-- Trueworld 2.0: Pre-Registration Infrastructure
CREATE TABLE IF NOT EXISTS pre_registrations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text UNIQUE NOT NULL,
    username text,
    created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE pre_registrations ENABLE ROW LEVEL SECURITY;

-- Allow public insertion (for pre-registration)
CREATE POLICY "Anyone can pre-register." ON pre_registrations FOR INSERT WITH CHECK (true);

-- Only service role can view (for privacy)
CREATE POLICY "Only admins can view pre-registrations." ON pre_registrations FOR SELECT USING (false);
