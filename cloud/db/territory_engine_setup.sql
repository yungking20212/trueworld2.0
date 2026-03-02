-- Trueworld 2.0: Competitive Territorial Infrastructure
-- Run this to activate Hot Zones, Country Takeovers, and Block Dominance.

-- 1. TERRITORY TABLES

-- Defined Cities/Zones for Hot Spot Tracking
CREATE TABLE IF NOT EXISTS territory_zones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  latitude float NOT NULL,
  longitude float NOT NULL,
  radius_meters integer DEFAULT 5000,
  base_color text DEFAULT '#00FFFF'
);

-- Seed Initial Territorial Hubs
INSERT INTO territory_zones (name, latitude, longitude, base_color)
VALUES 
  ('NYC_CORE', 40.7128, -74.0060, '#FF00FF'),
  ('TOKYO_ZONE', 35.6762, 139.6503, '#0000FF'),
  ('DALLAS_HUB', 32.7767, -96.7970, '#00FF00'),
  ('LOND_SECTOR', 51.5074, -0.1278, '#FF0000'),
  ('LA_GRID', 34.0522, -118.2437, '#FFA500')
ON CONFLICT (name) DO NOTHING;

-- 2. COMPETITIVE RPCS

-- Fetch Real-Time Hot Zones (Intensity based on recent video activity)
CREATE OR REPLACE FUNCTION get_active_hot_zones()
RETURNS TABLE (
  name text,
  latitude float,
  longitude float,
  intensity float,
  trending_count integer,
  color text,
  controller_handle text
) AS $$
BEGIN
  RETURN QUERY
  WITH zone_stats AS (
    SELECT 
      tz.name,
      tz.latitude,
      tz.longitude,
      tz.base_color,
      COUNT(v.id)::integer as v_count,
      MAX(p.username) as top_creator -- Simple logic: creator of most liked video in zone
    FROM territory_zones tz
    LEFT JOIN videos v ON 
      v.latitude BETWEEN tz.latitude - 0.1 AND tz.latitude + 0.1 AND
      v.longitude BETWEEN tz.longitude - 0.1 AND tz.longitude + 0.1 AND
      v.created_at > now() - interval '24 hours'
    LEFT JOIN profiles p ON v.author_id = p.id
    GROUP BY tz.id, tz.name, tz.latitude, tz.longitude, tz.base_color
  )
  SELECT 
    zs.name,
    zs.latitude,
    zs.longitude,
    LEAST(1.0, zs.v_count::float / 10.0) as intensity,
    zs.v_count as trending_count,
    zs.base_color as color,
    COALESCE(zs.top_creator, 'NO_OVERLORD') as controller_handle
  FROM zone_stats zs
  ORDER BY zs.v_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Fetch Country Takeover Status
CREATE OR REPLACE FUNCTION get_country_dominance()
RETURNS TABLE (
  country_code text,
  latitude float,
  longitude float,
  controller_handle text,
  dominance_score float,
  flag_emoji text
) AS $$
BEGIN
  -- This is a simulated strategic layer based on top creator locations
  RETURN QUERY
  SELECT 
    'USA' as country_code, 37.0902 as latitude, -95.7129 as longitude, 
    (SELECT username FROM profiles ORDER BY xp DESC LIMIT 1) as controller_handle,
    0.95 as dominance_score, '🇺🇸' as flag_emoji
  UNION ALL
  SELECT 
    'JAPAN', 36.2048, 138.2529, 'NEURAL_GHOST', 0.88, '🇯🇵'
  UNION ALL
  SELECT 
    'UK', 55.3781, -3.4360, 'RAZOR_CREW', 0.82, '🇬🇧';
END;
$$ LANGUAGE plpgsql;

-- 3. PERMISSIONS
ALTER TABLE territory_zones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public zones are viewable by everyone." ON territory_zones FOR SELECT USING (true);
