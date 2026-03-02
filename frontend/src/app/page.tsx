"use client";

import React, { useEffect, useRef, useState, useCallback } from "react";
import { supabase } from "@/lib/supabaseClient";
import { useRouter } from "next/navigation";

interface Video {
  id: string;
  video_url: string;
  username: string;
  description: string;
  music_title: string;
  likes: number;
  comments: number;
  shares: number;
  author_id?: string;
}

interface HotZone {
  name: string;
  latitude: number;
  longitude: number;
  intensity: number;
  trending_count: number;
  color: string;
  controller_handle: string;
}

interface CountryDominance {
  country_code: string;
  latitude: number;
  longitude: number;
  controller_handle: string;
  dominance_score: number;
  flag_emoji: string;
}

type TabType = "HOME" | "EYE" | "NOTIF" | "PROFILE";

export default function Home() {
  const [session, setSession] = useState<any>(null);
  const [userProfile, setUserProfile] = useState<any>(null);
  const [videos, setVideos] = useState<Video[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<TabType>("HOME");
  const [preRegisterEmail, setPreRegisterEmail] = useState("");
  const [preRegisterUser, setPreRegisterUser] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [regMessage, setRegMessage] = useState<string | null>(null);
  const router = useRouter();

  const fetchVideos = useCallback(async () => {
    try {
      const { data, error } = await supabase.from("videos").select("*").limit(10);
      if (!error) setVideos(data || []);
    } catch (err) {
      console.error("Neural Video Fetch Fail:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchUserProfile = useCallback(async (userId: string) => {
    try {
      const { data, error } = await supabase.from("profiles").select("*").eq("id", userId).single();
      if (!error) setUserProfile(data);
    } catch (err) {
      console.error("Profile Link Fail:", err);
    }
  }, []);

  useEffect(() => {
    let mounted = true;

    async function checkSession() {
      try {
        const { data: { session: currentSession } } = await supabase.auth.getSession();
        if (mounted) {
          setSession(currentSession);
          if (currentSession) {
            await Promise.all([
              fetchVideos(),
              fetchUserProfile(currentSession.user.id)
            ]);
          } else {
            setLoading(false);
          }
        }
      } catch (err) {
        if (mounted) setLoading(false);
      }
    }

    checkSession();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, newSession) => {
      if (mounted) {
        setSession(newSession);
        if (newSession) {
          fetchVideos();
          fetchUserProfile(newSession.user.id);
        } else {
          setLoading(false);
        }
      }
    });

    // Real-Time Neural Sync: Listen for Video Updates (Likes/Comments/Shares)
    const videoChannel = supabase
      .channel('video_sync')
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'videos' },
        (payload) => {
          if (payload.new) {
            setVideos((prev) =>
              prev.map((v) => (v.id === payload.new.id ? { ...v, ...payload.new } : v))
            );
          }
        }
      )
      .subscribe();

    // Real-Time Profile Sync: Listen for XP/Follower changes
    let profileChannel: any = null;
    if (session?.user?.id) {
      profileChannel = supabase
        .channel(`profile_sync_${session.user.id}`)
        .on(
          'postgres_changes',
          { event: 'UPDATE', schema: 'public', table: 'profiles', filter: `id=eq.${session.user.id}` },
          (payload) => {
            if (payload.new) {
              setUserProfile(payload.new);
            }
          }
        )
        .subscribe();
    }

    // Failsafe: Force stop loading after 8s
    const failsafe = setTimeout(() => {
      if (mounted) setLoading(false);
    }, 8000);

    return () => {
      mounted = false;
      subscription.unsubscribe();
      supabase.removeChannel(videoChannel);
      if (profileChannel) supabase.removeChannel(profileChannel);
      clearTimeout(failsafe);
    };
  }, [fetchVideos, fetchUserProfile, session?.user?.id]);

  const handleLike = async (videoId: string, isLiked: boolean) => {
    if (!session) {
      router.push('/auth');
      return;
    }

    try {
      if (isLiked) {
        await supabase.from('likes').delete().match({ user_id: session.user.id, video_id: videoId });
        await supabase.rpc('decrement_like_count', { v_id: videoId });
      } else {
        await supabase.from('likes').insert({ user_id: session.user.id, video_id: videoId });
        await supabase.rpc('increment_like_count', { v_id: videoId });
      }
    } catch (err) {
      console.error("Neural Like Fail:", err);
    }
  };

  const handlePreRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    const { error } = await supabase.from("pre_registrations").insert([
      { email: preRegisterEmail, username: preRegisterUser }
    ]);
    if (error) {
      setRegMessage("ALREADY_IN_NEURAL_DATABASE");
    } else {
      setRegMessage("NEURAL_SYNC_COMPLETE");
      setPreRegisterEmail("");
      setPreRegisterUser("");
    }
    setIsSubmitting(false);
  };

  if (loading) {
    return (
      <div className="h-screen w-full bg-black flex items-center justify-center">
        <div className="animate-pulse flex flex-col items-center gap-6">
          <div className="h-16 w-16 bg-red-600 rounded-full blur-2xl opacity-40 animate-pulse"></div>
          <div className="flex flex-col items-center gap-2">
            <span className="text-[10px] font-black tracking-[0.5em] text-white uppercase italic">Initialising Neural Link...</span>
            <span className="text-[8px] font-bold text-white/20 uppercase tracking-widest italic">Scanning Planetary Nodes</span>
          </div>
          <button
            onClick={() => setLoading(false)}
            className="mt-8 text-[8px] font-black text-red-600/40 hover:text-red-600 uppercase tracking-widest border border-red-600/10 px-4 py-2 rounded-full transition-all"
          >
            Bypass Synchronization
          </button>
        </div>
      </div>
    );
  }

  // LOGGED IN: High-Fidelity App Feed
  if (session) {
    return (
      <main className="h-screen w-full bg-black overflow-hidden relative">
        <div className="h-full w-full">
          {activeTab === "HOME" && (
            <div className="h-full w-full overflow-y-scroll snap-y snap-mandatory scrollbar-hide">
              {videos.length > 0 ? (
                videos.map((video) => (
                  <VideoCard
                    key={video.id}
                    video={video}
                    currentUserId={session.user.id}
                    onLike={(isLiked) => handleLike(video.id, isLiked)}
                  />
                ))
              ) : (
                <div className="h-screen w-full flex flex-col items-center justify-center text-white gap-4 italic opacity-30">
                  <span>NO_BROADCASTS_DETECTED</span>
                  <button onClick={() => fetchVideos()} className="text-xs uppercase font-bold tracking-widest border border-white/20 px-6 py-2 rounded-full">Refresh Node</button>
                </div>
              )}
            </div>
          )}

          {activeTab === "EYE" && (
            <EyeWorld session={session} />
          )}

          {activeTab === "PROFILE" && (
            <div className="h-full w-full bg-zinc-950 flex flex-col items-center justify-center">
              <div className="text-center space-y-6">
                <div className="w-24 h-24 mx-auto rounded-[32px] bg-white/5 border border-white/10 flex items-center justify-center overflow-hidden shadow-2xl">
                  {userProfile?.avatar_url ? (
                    <img src={userProfile.avatar_url} className="w-full h-full object-cover" alt="" />
                  ) : (
                    <span className="text-4xl">👤</span>
                  )}
                </div>
                <div>
                  <h2 className="text-2xl font-black text-white italic uppercase tracking-[0.1em]">@{userProfile?.username || "NODE_ID"}</h2>
                  <p className="text-zinc-500 text-[10px] font-black tracking-[0.5em] uppercase italic mt-2">Verified Planetary Resident</p>
                </div>
                <div className="flex gap-8 justify-center">
                  <div className="flex flex-col items-center">
                    <span className="text-lg font-black text-white">{userProfile?.follower_count || 0}</span>
                    <span className="text-[8px] font-black text-zinc-500 uppercase tracking-widest">Followers</span>
                  </div>
                  <div className="flex flex-col items-center">
                    <span className="text-lg font-black text-white">{userProfile?.following_count || 0}</span>
                    <span className="text-[8px] font-black text-zinc-500 uppercase tracking-widest">Following</span>
                  </div>
                </div>
                <button
                  onClick={() => router.push(`/u/${userProfile?.username}`)}
                  className="px-8 py-3 bg-white/5 border border-white/10 text-white font-black text-[10px] uppercase tracking-[0.4em] rounded-2xl hover:bg-white/10 transition-all font-bold"
                >
                  View Neural Grid
                </button>
                <button
                  onClick={() => supabase.auth.signOut()}
                  className="block mx-auto text-[8px] font-black text-red-600/50 hover:text-red-500 uppercase tracking-[0.5em] italic transition-colors"
                >
                  Terminate Session
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Neural Navigation Bar (Bottom Center) */}
        <div className="fixed bottom-10 left-1/2 -translate-x-1/2 z-50 flex items-center gap-1 p-2 bg-zinc-900/60 backdrop-blur-3xl border border-white/10 rounded-[32px] shadow-[0_20px_50px_rgba(0,0,0,0.5)]">
          <NavButton icon="🏠" label="HOME" active={activeTab === "HOME"} onClick={() => setActiveTab("HOME")} />
          <NavButton icon="🌍" label="EYE" active={activeTab === "EYE"} onClick={() => setActiveTab("EYE")} />
          <div className="relative group mx-2">
            <div className="absolute inset-0 bg-red-600 rounded-2xl blur-lg opacity-40 group-hover:opacity-60 transition-opacity"></div>
            <button className="relative w-14 h-14 bg-red-600 rounded-2xl flex items-center justify-center shadow-xl active:scale-95 transition-all">
              <span className="text-2xl">➕</span>
              <div className="absolute -top-1 -right-1 bg-white text-[8px] font-black text-black px-1.5 py-0.5 rounded-md italic">AI</div>
            </button>
          </div>
          <NavButton icon="🔔" label="NOTIF" active={activeTab === "NOTIF"} onClick={() => setActiveTab("NOTIF")} />
          <NavButton icon="👤" label="PROFILE" active={activeTab === "PROFILE"} onClick={() => setActiveTab("PROFILE")} />
        </div>
      </main>
    );
  }

  // NOT LOGGED IN: Premium Staging / Pre-Registration Landing
  return (
    <div className="min-h-screen bg-black overflow-hidden relative flex items-center justify-center">
      {/* Immersive Background */}
      <div className="absolute inset-0 z-0">
        <div className="absolute inset-0 bg-gradient-to-br from-red-600/10 via-black to-cyan-600/10 opacity-50"></div>
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-red-600/5 rounded-full blur-[120px] animate-pulse"></div>
        {/* Simulated Grid Overlay */}
        <div className="absolute inset-0 opacity-[0.03]" style={{ backgroundImage: 'radial-gradient(circle, white 1px, transparent 1px)', backgroundSize: '40px 40px' }}></div>
      </div>

      <div className="relative z-10 w-full max-w-4xl px-8 flex flex-col items-center text-center">
        <div className="mb-12 space-y-4">
          <div className="inline-block px-4 py-1.5 bg-red-600/10 border border-red-500/20 rounded-full mb-6">
            <span className="text-[10px] font-black tracking-[0.3em] text-red-500 uppercase italic">Phase 2.0 Alpha Incoming</span>
          </div>
          <h1 className="text-6xl md:text-8xl font-black text-white tracking-tighter uppercase italic leading-none">
            TRUEWORLD<span className="text-red-600 text-3xl align-top ml-2">2.0</span>
          </h1>
          <p className="text-zinc-500 max-w-xl mx-auto text-sm md:text-base font-medium leading-relaxed mt-6">
            The next generation of planetary social infrastructure.
            Real-time territory control. Neural XP. Eye World Dominance.
          </p>
        </div>

        {/* Pre-Registration Manifest */}
        <div className="w-full max-w-md bg-zinc-900/40 backdrop-blur-3xl border border-white/5 p-8 rounded-[40px] shadow-2xl">
          <h2 className="text-xs font-black tracking-[0.4em] text-white uppercase mb-8 opacity-50 italic">Manifest Reservation</h2>

          <form onSubmit={handlePreRegister} className="space-y-4">
            <input
              type="text"
              placeholder="ASSIGN_USERNAME"
              required
              className="w-full bg-white/5 border border-white/10 rounded-2xl px-6 py-4 text-white text-xs font-bold focus:outline-none focus:ring-2 focus:ring-red-600 focus:bg-white/10 transition-all uppercase tracking-widest"
              value={preRegisterUser}
              onChange={(e) => setPreRegisterUser(e.target.value.toUpperCase())}
            />
            <input
              type="email"
              placeholder="NEURAL_EMAIL_NODE"
              required
              className="w-full bg-white/5 border border-white/10 rounded-2xl px-6 py-4 text-white text-xs font-bold focus:outline-none focus:ring-2 focus:ring-red-600 focus:bg-white/10 transition-all uppercase tracking-widest"
              value={preRegisterEmail}
              onChange={(e) => setPreRegisterEmail(e.target.value)}
            />

            <button
              disabled={isSubmitting}
              type="submit"
              className="w-full bg-red-600 hover:bg-red-700 text-white font-black py-4 rounded-2xl text-[10px] uppercase tracking-[0.5em] transition-all shadow-xl shadow-red-600/20 active:scale-95 disabled:opacity-50"
            >
              {isSubmitting ? "SYNCING..." : "RESERVE_BLOCK_ACCESS"}
            </button>
          </form>

          {regMessage && (
            <div className="mt-6 text-[10px] font-black tracking-[0.2em] text-red-500 animate-pulse uppercase italic">
              {regMessage}
            </div>
          )}

          <div className="mt-8 pt-8 border-t border-white/5">
            <button onClick={() => router.push("/auth")} className="text-[10px] font-black tracking-[0.3em] text-zinc-500 hover:text-white uppercase transition-colors italic">
              Already Synchronized? Access Node
            </button>
          </div>
        </div>
      </div>

      {/* Footer Decoration */}
      <div className="absolute bottom-10 w-full px-12 flex justify-between items-end z-10 pointer-events-none">
        <div className="space-y-1">
          <div className="h-0.5 w-12 bg-red-600 opacity-50"></div>
          <span className="text-[8px] font-black text-white/20 tracking-[1em] uppercase block">Planetary Node: 0x992</span>
        </div>
        <div className="text-right">
          <span className="text-[8px] font-black text-white/20 tracking-[0.5em] uppercase block">V2.0.0A</span>
          <span className="text-[8px] font-black text-white/20 tracking-[0.5em] uppercase block">© 2026 TRUEWORLD NETWORK</span>
        </div>
      </div>
    </div>
  );
}

function EyeWorld({ session }: { session: any }) {
  const [hotZones, setHotZones] = useState<HotZone[]>([]);
  const [countryDominance, setCountryDominance] = useState<CountryDominance[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchEyeWorldData() {
      try {
        const [{ data: zones }, { data: countries }] = await Promise.all([
          supabase.rpc('get_active_hot_zones'),
          supabase.rpc('get_country_dominance')
        ]);
        if (zones) setHotZones(zones);
        if (countries) setCountryDominance(countries);
      } catch (err) {
        console.error("Eye World Link Fail:", err);
      } finally {
        setLoading(false);
      }
    }
    fetchEyeWorldData();
  }, []);

  return (
    <div className="h-full w-full bg-zinc-950 relative overflow-hidden flex flex-col items-center justify-center">
      {/* Tactical Grid Background */}
      <div className="absolute inset-0 opacity-20 pointer-events-none">
        <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&q=80')] bg-cover bg-center grayscale invert scale-110 blur-sm"></div>
        <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-black"></div>
        <div className="absolute inset-0" style={{ backgroundImage: 'linear-gradient(rgba(255,255,255,0.05) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.05) 1px, transparent 1px)', backgroundSize: '50px 50px' }}></div>
      </div>

      {loading ? (
        <div className="relative z-10 animate-pulse text-[10px] font-black text-red-600 uppercase tracking-[0.5em] italic">Synchronizing Tactical Data...</div>
      ) : (
        <div className="relative z-10 w-full max-w-6xl px-8 flex flex-col md:flex-row gap-8 items-center justify-center">
          {/* Active Hot Zones List (Tactical HUD Style) */}
          <div className="w-full md:w-80 bg-black/40 backdrop-blur-3xl border border-white/5 p-6 rounded-[32px] space-y-6">
            <div className="flex items-center justify-between border-b border-white/10 pb-4">
              <span className="text-[10px] font-black text-white uppercase italic tracking-widest">Active_Zones</span>
              <span className="text-[10px] font-black text-red-600 animate-pulse">LIVE</span>
            </div>
            <div className="space-y-4">
              {hotZones.length > 0 ? hotZones.map((zone, i) => (
                <div key={i} className="flex items-center justify-between group cursor-pointer">
                  <div>
                    <div className="text-[10px] font-black text-white italic group-hover:text-red-500 transition-colors uppercase">{zone.name}</div>
                    <div className="text-[8px] font-bold text-zinc-500 uppercase tracking-tighter">Controller: @{zone.controller_handle}</div>
                  </div>
                  <div className="h-1 w-12 bg-zinc-800 rounded-full overflow-hidden">
                    <div className="h-full bg-red-600" style={{ width: `${zone.intensity * 100}%` }}></div>
                  </div>
                </div>
              )) : (
                <div className="text-[8px] font-black text-zinc-600 uppercase italic">No Active Deployments Detected</div>
              )}
            </div>
          </div>

          {/* Central Tactical Display */}
          <div className="relative flex-1 aspect-square max-w-[500px] flex items-center justify-center">
            <div className="absolute inset-0 border border-red-600/10 rounded-full animate-ping opacity-20"></div>
            <div className="absolute inset-10 border border-white/5 rounded-full"></div>
            <div className="absolute inset-20 border border-white/5 rounded-full animate-spin-slow"></div>

            {/* Dynamic Markers Placeholder */}
            <div className="relative z-20 text-center">
              <div className="w-24 h-24 mx-auto rounded-full bg-red-600/10 border border-red-600/50 flex items-center justify-center shadow-[0_0_50px_rgba(220,38,38,0.2)]">
                <span className="text-4xl animate-pulse">🌍</span>
              </div>
              <div className="mt-6 space-y-1">
                <h3 className="text-2xl font-black text-white uppercase italic tracking-tighter">Planetary_Grid</h3>
                <p className="text-[8px] font-black text-zinc-500 uppercase tracking-[0.5em] italic">V3.0 Orbital Visualization</p>
              </div>
            </div>

            {/* Orbital Nodes */}
            {countryDominance.map((c, i) => (
              <div key={i} className="absolute" style={{ transform: `rotate(${i * 120}deg) translateY(-180px) rotate(-${i * 120}deg)` }}>
                <div className="bg-black/80 backdrop-blur-xl border border-white/10 px-4 py-2 rounded-2xl flex items-center gap-3 shadow-2xl">
                  <span className="text-lg">{c.flag_emoji}</span>
                  <div className="text-left">
                    <div className="text-[8px] font-black text-white uppercase italic">{c.country_code}</div>
                    <div className="text-[6px] font-bold text-red-500 uppercase tracking-tighter">@{c.controller_handle}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Tactical Stats HUD */}
          <div className="w-full md:w-80 bg-black/40 backdrop-blur-3xl border border-white/5 p-6 rounded-[32px] space-y-6">
            <div className="flex items-center justify-between border-b border-white/10 pb-4">
              <span className="text-[10px] font-black text-white uppercase italic tracking-widest">Global_Status</span>
            </div>
            <div className="space-y-6">
              <div className="space-y-2">
                <div className="flex justify-between text-[8px] font-black uppercase text-zinc-500 italic">
                  <span>Neural_Bandwidth</span>
                  <span>98.2%</span>
                </div>
                <div className="h-1 bg-zinc-800 rounded-full overflow-hidden">
                  <div className="h-full bg-cyan-500" style={{ width: '98.2%' }}></div>
                </div>
              </div>
              <div className="space-y-2">
                <div className="flex justify-between text-[8px] font-black uppercase text-zinc-500 italic">
                  <span>Planetary_Sync</span>
                  <span>ACTIVE</span>
                </div>
                <div className="h-1 bg-zinc-800 rounded-full overflow-hidden">
                  <div className="h-full bg-green-500" style={{ width: '100%' }}></div>
                </div>
              </div>
              <button className="w-full py-4 bg-white/5 border border-white/10 rounded-2xl text-[8px] font-black text-white uppercase tracking-[0.3em] hover:bg-white/10 transition-all italic">Launch Orbital Scan</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function NavButton({ icon, label, active, onClick }: { icon: string; label: string; active?: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={`w-14 h-14 flex flex-col items-center justify-center rounded-2xl transition-all ${active ? "bg-white/10 text-white" : "text-white/40 hover:text-white hover:bg-white/5"}`}
    >
      <span className="text-xl">{icon}</span>
      <span className="text-[8px] font-black tracking-widest mt-1 italic leading-none">{label}</span>
      {active && <div className="mt-1 h-0.5 w-4 bg-red-600 rounded-full"></div>}
    </button>
  );
}

function VideoCard({
  video,
  currentUserId,
  onLike
}: {
  video: Video;
  currentUserId?: string;
  onLike?: (isLiked: boolean) => void;
}) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isLiked, setIsLiked] = useState(false);
  const [likeCount, setLikeCount] = useState(video.likes);

  useEffect(() => {
    setLikeCount(video.likes);
  }, [video.likes]);

  useEffect(() => {
    async function checkLikeStatus() {
      if (currentUserId && video.id) {
        const { data } = await supabase
          .from('likes')
          .select('*')
          .match({ user_id: currentUserId, video_id: video.id })
          .single();
        setIsLiked(!!data);
      }
    }
    checkLikeStatus();
  }, [currentUserId, video.id]);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          videoRef.current?.play().catch(() => { });
          setIsPlaying(true);
        } else {
          videoRef.current?.pause();
          setIsPlaying(false);
        }
      },
      { threshold: 0.6 }
    );

    if (videoRef.current) observer.observe(videoRef.current);
    return () => observer.disconnect();
  }, []);

  const togglePlay = () => {
    if (videoRef.current) {
      if (isPlaying) {
        videoRef.current.pause();
      } else {
        videoRef.current.play().catch(() => { });
      }
      setIsPlaying(!isPlaying);
    }
  };

  const handleLikeClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    const newIsLiked = !isLiked;
    setIsLiked(newIsLiked);
    setLikeCount(prev => newIsLiked ? prev + 1 : Math.max(0, prev - 1));
    onLike?.(isLiked); // Call API with OLD state
  };

  return (
    <div className="h-screen w-full relative snap-start flex items-center justify-center bg-black overflow-hidden">
      <video
        ref={videoRef}
        src={video.video_url}
        loop
        playsInline
        className="h-full w-full object-cover cursor-pointer"
        onClick={togglePlay}
      />

      {/* High-Fidelity App Overlay */}
      <div className="absolute inset-x-0 bottom-0 p-8 pb-32 flex justify-between items-end bg-gradient-to-t from-black/80 via-black/20 to-transparent pointer-events-none z-10">
        <div className="space-y-4 max-w-[70%]">
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 rounded-2xl bg-white/5 backdrop-blur-md border border-white/10 flex items-center justify-center shadow-lg">
              <span className="text-sm">👤</span>
            </div>
            <h3 className="font-black text-xl text-white italic tracking-tight uppercase">@{video.username}</h3>
          </div>
          <p className="text-sm text-white/80 font-medium leading-relaxed line-clamp-2 max-w-sm">{video.description}</p>
          <div className="flex items-center gap-3 bg-white/5 backdrop-blur-md border border-white/10 rounded-full px-5 py-2.5 w-fit">
            <div className="w-6 h-6 rounded-full bg-red-600/20 flex items-center justify-center animate-spin-slow">
              <span className="text-[10px]">🎵</span>
            </div>
            <span className="text-[10px] font-black text-white italic uppercase tracking-widest">{video.music_title || "Original Audio"}</span>
          </div>
        </div>

        <div className="flex flex-col gap-8 items-center flex-shrink-0 pointer-events-auto">
          <div
            onClick={handleLikeClick}
            className="flex flex-col items-center group cursor-pointer"
          >
            <div className={`w-14 h-14 ${isLiked ? 'bg-red-600' : 'bg-white/5 backdrop-blur-2xl border border-white/10'} rounded-2xl flex items-center justify-center shadow-2xl group-hover:scale-110 active:scale-95 transition-all`}>
              <span className="text-2xl">{isLiked ? '❤️' : '🤍'}</span>
            </div>
            <span className="text-[10px] font-black text-white mt-3 italic tracking-widest">{likeCount}</span>
          </div>

          <div className="flex flex-col items-center group cursor-pointer">
            <div className="w-14 h-14 bg-white/5 backdrop-blur-2xl border border-white/10 rounded-2xl flex items-center justify-center shadow-2xl group-hover:bg-white/10 group-hover:scale-110 active:scale-95 transition-all">
              <span className="text-2xl">💬</span>
            </div>
            <span className="text-[10px] font-black text-white mt-3 italic tracking-widest">{video.comments}</span>
          </div>

          <div className="flex flex-col items-center group cursor-pointer">
            <div className="w-14 h-14 bg-white/5 backdrop-blur-2xl border border-white/10 rounded-2xl flex items-center justify-center shadow-2xl group-hover:bg-white/10 group-hover:scale-110 active:scale-95 transition-all">
              <span className="text-2xl">🔗</span>
            </div>
            <span className="text-[10px] font-black text-white mt-3 italic tracking-widest">{video.shares}</span>
          </div>

          {/* Rotating Vinyl/NFT Element */}
          <div className="w-14 h-14 rounded-full border-2 border-white/5 p-1 animate-spin-slow shadow-xl">
            <div className="w-full h-full bg-gradient-to-br from-zinc-800 to-black rounded-full border border-white/10 flex items-center justify-center overflow-hidden">
              <div className="w-6 h-6 bg-white/10 rounded-full blur-[4px]"></div>
            </div>
          </div>
        </div>
      </div>

      {/* Top Protocol Status Layer */}
      <div className="absolute top-0 inset-x-0 p-10 flex justify-between items-start pointer-events-none z-20">
        <div className="space-y-1">
          <span className="text-[9px] font-black text-white/30 tracking-[0.5em] uppercase italic bg-black/40 backdrop-blur-xl px-3 py-1 rounded-full border border-white/5">Neural Network</span>
          <div className="flex items-center gap-2 pl-3">
            <div className="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse shadow-[0_0_10px_#22c55e]"></div>
            <span className="text-[9px] font-black text-white tracking-[0.2em] uppercase italic">LIVE_SATELLITE_FEED</span>
          </div>
        </div>
        <div className="group pointer-events-auto cursor-pointer">
          <div className="w-12 h-12 bg-white/5 backdrop-blur-2xl border border-white/10 rounded-2xl flex items-center justify-center shadow-2xl hover:bg-white/10 transition-all">
            <span className="text-white text-lg">🔔</span>
          </div>
        </div>
      </div>
    </div>
  );
}
