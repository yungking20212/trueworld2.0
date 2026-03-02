-- Trueworld 2.0: Planetary Social & Territorial Engine
-- Run this in your Supabase SQL Editor to activate full v2.0 functionality.

-- 1. SOCIAL INTERACTION RPCS

-- Increment/Decrement Video Likes
CREATE OR REPLACE FUNCTION increment_like_count(v_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE videos SET likes = likes + 1 WHERE id = v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_like_count(v_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE videos SET likes = GREATEST(0, likes - 1) WHERE id = v_id;
END;
$$ LANGUAGE plpgsql;

-- Increment Comment Likes
CREATE OR REPLACE FUNCTION increment_comment_likes(c_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE video_comments SET likes = likes + 1 WHERE id = c_id;
END;
$$ LANGUAGE plpgsql;

-- Register Video View & Accumulate Neural XP
CREATE OR REPLACE FUNCTION register_video_view(v_id uuid)
RETURNS void AS $$
DECLARE
  v_author_id uuid;
BEGIN
  UPDATE videos SET views_count = views_count + 1 WHERE id = v_id
  RETURNING author_id INTO v_author_id;
  
  -- Grant Author 5 XP for every view
  UPDATE profiles SET xp = xp + 5 WHERE id = v_author_id;
END;
$$ LANGUAGE plpgsql;

-- 2. PLANETARY DISCOVERY ENGINE (WORLD PULSE V2)

CREATE OR REPLACE FUNCTION get_world_pulse_v2(
  min_lat float,
  max_lat float,
  min_long float,
  max_long float
)
RETURNS TABLE (
  id uuid,
  video_url text,
  username text,
  description text,
  music_title text,
  likes integer,
  comments integer,
  views_count integer,
  author_id uuid,
  latitude float,
  longitude float,
  is_location_protected boolean,
  global_rank integer,
  neural_score integer,
  follower_count integer,
  following_count integer,
  xp integer,
  monetization_enabled boolean,
  revenue_cents integer,
  momentum_score float,
  is_rising_star boolean,
  city_name text,
  created_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    v.id,
    v.video_url,
    p.username,
    v.description,
    v.music_title,
    v.likes,
    v.comments,
    v.views_count,
    v.author_id,
    v.latitude,
    v.longitude,
    v.is_location_protected,
    p.daily_rank as global_rank,
    v.neural_score,
    p.follower_count,
    p.following_count,
    p.xp,
    p.monetization_enabled,
    p.revenue_cents,
    (v.likes::float / GREATEST(1, EXTRACT(EPOCH FROM (now() - v.created_at))/3600)) as momentum_score,
    (v.likes > 100 AND EXTRACT(EPOCH FROM (now() - v.created_at)) < 86400) as is_rising_star,
    v.city as city_name,
    v.created_at
  FROM videos v
  JOIN profiles p ON v.author_id = p.id
  WHERE v.latitude BETWEEN min_lat AND max_lat
    AND v.longitude BETWEEN min_long AND max_long
    AND v.is_location_protected = false
  ORDER BY v.neural_score DESC, v.created_at DESC
  LIMIT 50;
END;
$$ LANGUAGE plpgsql;

-- 3. NEURAL XP & LEVELING TRIGGERS

-- Automatically gain XP on Like
CREATE OR REPLACE FUNCTION on_video_liked()
RETURNS TRIGGER AS $$
BEGIN
  -- Increment Author XP by 50 when a video is liked
  UPDATE profiles 
  SET xp = xp + 50 
  WHERE id = (SELECT author_id FROM videos WHERE id = NEW.video_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_video_liked ON likes;
CREATE TRIGGER tr_video_liked
AFTER INSERT ON likes
FOR EACH ROW EXECUTE FUNCTION on_video_liked();

-- 4. RLS PROTOCOLS (PLANETARY SECURITY)

-- Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone." ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile." ON profiles FOR UPDATE USING (auth.uid() = id);

-- Videos
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Videos are viewable by everyone if not protected." ON videos FOR SELECT USING (is_location_protected = false OR auth.uid() = author_id);
CREATE POLICY "Users can upload their own videos." ON videos FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Users can update their own videos." ON videos FOR UPDATE USING (auth.uid() = author_id);

-- Likes
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Likes are viewable by everyone." ON likes FOR SELECT USING (true);
CREATE POLICY "Authenticated users can toggle likes." ON likes FOR ALL USING (auth.uid() = user_id);

-- Notification Settings
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own notification settings." ON notification_settings FOR ALL USING (auth.uid() = user_id);
