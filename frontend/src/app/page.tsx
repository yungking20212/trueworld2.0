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
}

export default function Home() {
  const [videos, setVideos] = useState<Video[]>([]);
  const [loading, setLoading] = useState(true);
  const [session, setSession] = useState<any>(null);
  const router = useRouter();

  useEffect(() => {
    async function initAuth() {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        router.push("/auth");
      } else {
        setSession(session);
        fetchVideos();
      }
    }

    async function fetchVideos() {
      const { data, error } = await supabase
        .from('videos')
        .select('*');

      if (error) {
        console.error('Error fetching videos:', error);
      } else {
        setVideos(data || []);
      }
      setLoading(false);
    }

    initAuth();
  }, [router]);

  if (loading || !session) {
    return (
      <div className="h-screen w-full bg-black flex items-center justify-center text-white">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-white"></div>
      </div>
    );
  }

  return (
    <main className="h-screen w-full bg-black overflow-y-scroll snap-y snap-mandatory scrollbar-hide">
      {videos.length > 0 ? (
        videos.map((video) => (
          <VideoCard key={video.id} video={video} />
        ))
      ) : (
        <div className="h-screen w-full flex items-center justify-center text-white">
          No videos found
        </div>
      )}
    </main>
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

    if (videoRef.current) {
      observer.observe(videoRef.current);
    }

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
    <div className="h-screen w-full relative snap-start flex items-center justify-center">
      <video
        ref={videoRef}
        src={video.video_url}
        loop
        className="h-full w-full object-cover cursor-pointer"
        onClick={togglePlay}
      />

      {/* Overlay */}
      <div className="absolute bottom-0 left-0 w-full p-6 bg-gradient-to-t from-black/60 to-transparent text-white flex justify-between items-end">
        <div className="space-y-4">
          <h3 className="font-bold text-lg">{video.username}</h3>
          <p className="text-sm max-w-[80%]">{video.description}</p>
          <div className="flex items-center space-x-2">
            <span className="animate-pulse">🎵</span>
            <span className="text-xs">{video.music_title}</span>
          </div>
        </div>

        <div className="flex flex-col space-y-6 items-center">
          <div className="flex flex-col items-center">
            <div className="bg-red-500 rounded-full p-3 text-xl">❤️</div>
            <span className="text-xs font-bold">{video.likes}</span>
          </div>
          <div className="flex flex-col items-center">
            <div className="bg-gray-700/50 rounded-full p-3 text-xl">💬</div>
            <span className="text-xs font-bold">{video.comments}</span>
          </div>
          <div className="flex flex-col items-center">
            <div className="bg-gray-700/50 rounded-full p-3 text-xl">🔗</div>
            <span className="text-xs font-bold">{video.shares}</span>
          </div>
          <div className="w-12 h-12 bg-black rounded-full border-4 border-gray-800 animate-spin-slow flex items-center justify-center">
            <div className="w-6 h-6 bg-gray-400 rounded-full"></div>
          </div>
        </div>
      </div>
    </div>
  );
}
