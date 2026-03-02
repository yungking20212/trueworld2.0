"use client";

import { useEffect, useRef, useState } from "react";
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

export default function Home() {
  const [session, setSession] = useState<any>(null);
  const [videos, setVideos] = useState<Video[]>([]);
  const [loading, setLoading] = useState(true);
  const [preRegisterEmail, setPreRegisterEmail] = useState("");
  const [preRegisterUser, setPreRegisterUser] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [regMessage, setRegMessage] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    async function initAuth() {
      const { data: { session } } = await supabase.auth.getSession();
      setSession(session);
      if (session) {
        fetchVideos();
      } else {
        setLoading(false);
      }
    }
    initAuth();
  }, []);

  const fetchVideos = async () => {
    const { data, error } = await supabase.from("videos").select("*").limit(10);
    if (!error) setVideos(data || []);
    setLoading(false);
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
        <div className="animate-pulse flex flex-col items-center gap-4">
          <div className="h-12 w-12 bg-red-600 rounded-full blur-xl opacity-50"></div>
          <span className="text-[10px] font-black tracking-[0.5em] text-white uppercase italic">Initializing Neutral Link...</span>
        </div>
      </div>
    );
  }

  // LOGGED IN: High-Fidelity App Feed
  if (session) {
    return (
      <main className="h-screen w-full bg-black overflow-y-scroll snap-y snap-mandatory scrollbar-hide">
        {videos.length > 0 ? (
          videos.map((video) => (
            <VideoCard key={video.id} video={video} />
          ))
        ) : (
          <div className="h-screen w-full flex flex-col items-center justify-center text-white gap-4 italic opacity-30">
            <span>NO_BROADCASTS_DETECTED</span>
            <button onClick={() => router.push("/auth")} className="text-xs uppercase font-bold tracking-widest border border-white/20 px-6 py-2 rounded-full">Refresh Node</button>
          </div>
        )}

        {/* Navigation Sidebar (Simulated App Style) */}
        <div className="fixed right-6 top-1/2 -translate-y-1/2 flex flex-col gap-8 z-50 pointer-events-none">
          <div className="w-12 h-12 bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl flex items-center justify-center shadow-2xl pointer-events-auto cursor-pointer hover:bg-white/10 transition-all">
            <span className="text-xl">🗺️</span>
          </div>
          <div className="w-12 h-12 bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl flex items-center justify-center shadow-2xl pointer-events-auto cursor-pointer hover:bg-white/10 transition-all">
            <span className="text-xl">👁️</span>
          </div>
          <div onClick={() => router.push("/auth")} className="w-12 h-12 bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl flex items-center justify-center shadow-2xl pointer-events-auto cursor-pointer hover:bg-white/10 transition-all">
            <span className="text-xl text-red-500">⚙️</span>
          </div>
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

function VideoCard({ video }: { video: Video }) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          videoRef.current?.play();
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
        videoRef.current.play();
      }
      setIsPlaying(!isPlaying);
    }
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

      {/* High-Fidelity App Overlay (Matching Video exactly) */}
      <div className="absolute inset-x-0 bottom-0 p-8 flex justify-between items-end bg-gradient-to-t from-black/80 to-transparent pointer-events-none">
        <div className="space-y-4 max-w-[70%]">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-white/10 backdrop-blur-md border border-white/20 flex items-center justify-center">
              <span className="text-[10px]">👤</span>
            </div>
            <h3 className="font-black text-lg text-white italic tracking-tight uppercase">@{video.username}</h3>
          </div>
          <p className="text-sm text-white/80 font-medium leading-relaxed line-clamp-2">{video.description}</p>
          <div className="flex items-center gap-3 bg-black/40 backdrop-blur-md border border-white/5 rounded-full px-4 py-2 w-fit">
            <span className="text-sm animate-pulse">🎵</span>
            <span className="text-[10px] font-black text-white italic uppercase tracking-wider">{video.music_title || "Original Audio"}</span>
          </div>
        </div>

        <div className="flex flex-col gap-6 items-center flex-shrink-0 pointer-events-auto">
          <div className="flex flex-col items-center group cursor-pointer">
            <div className="w-14 h-14 bg-red-600 rounded-2xl flex items-center justify-center shadow-2xl shadow-red-600/30 group-hover:scale-110 transition-transform">
              <span className="text-2xl">❤️</span>
            </div>
            <span className="text-[10px] font-black text-white mt-2 italic">{video.likes}</span>
          </div>

          <div className="flex flex-col items-center group cursor-pointer">
            <div className="w-14 h-14 bg-white/10 backdrop-blur-xl border border-white/10 rounded-2xl flex items-center justify-center shadow-2xl group-hover:bg-white/20 transition-all group-hover:scale-110">
              <span className="text-2xl">💬</span>
            </div>
            <span className="text-[10px] font-black text-white mt-2 italic">{video.comments}</span>
          </div>

          <div className="flex flex-col items-center group cursor-pointer">
            <div className="w-14 h-14 bg-white/10 backdrop-blur-xl border border-white/10 rounded-2xl flex items-center justify-center shadow-2xl group-hover:bg-white/20 transition-all group-hover:scale-110">
              <span className="text-2xl">🔗</span>
            </div>
            <span className="text-[10px] font-black text-white mt-2 italic">{video.shares}</span>
          </div>

          {/* Rotating Dynamic Element */}
          <div className="w-12 h-12 rounded-full border-2 border-white/20 p-1 animate-spin-slow">
            <div className="w-full h-full bg-zinc-800 rounded-full border border-white/10 flex items-center justify-center overflow-hidden">
              <div className="w-4 h-4 bg-white/20 rounded-full blur-[2px]"></div>
            </div>
          </div>
        </div>
      </div>

      {/* Top Banner (Neural Network Status) */}
      <div className="absolute top-0 inset-x-0 p-8 flex justify-between items-start pointer-events-none z-20">
        <div className="flex flex-col">
          <span className="text-[10px] font-black text-white/40 tracking-[0.5em] uppercase italic">Neural Network</span>
          <div className="flex items-center gap-2">
            <div className="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse"></div>
            <span className="text-[10px] font-black text-white tracking-widest uppercase italic">LIVE_FEED</span>
          </div>
        </div>
        <div className="w-10 h-10 border border-white/20 rounded-xl flex items-center justify-center backdrop-blur-md">
          <span className="text-white text-xs">🔔</span>
        </div>
      </div>
    </div>
  );
}
