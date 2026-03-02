"use client";

import React, { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";

interface Video {
    id: string;
    video_url: string;
    username: string;
    description: string;
    music_title: string;
    likes: number;
    comments: number;
    author_id: string;
}

interface Comment {
    id: string;
    video_id: string;
    user_id: string;
    text: string;
    likes: number;
    parent_id: string | null;
    created_at: string;
    author?: {
        username: string;
        avatar_url: string | null;
        follower_count: number;
    };
}

export default function VideoDetailPage() {
    const params = useParams();
    const router = useRouter();
    const id = params?.id as string;
    const [video, setVideo] = useState<Video | null>(null);
    const [comments, setComments] = useState<Comment[]>([]);
    const [loading, setLoading] = useState(true);
    const [commentsLoading, setCommentsLoading] = useState(false);

    useEffect(() => {
        if (!id) return;

        async function fetchVideoData() {
            const { data, error } = await supabase
                .from("videos")
                .select("*")
                .eq("id", id)
                .single();

            if (error) {
                console.error("Error fetching video:", error);
                setLoading(false);
                return;
            }

            setVideo(data);
            setLoading(false);
            fetchComments(id);
        }

        fetchVideoData();
    }, [id]);

    const fetchComments = async (videoId: string) => {
        setCommentsLoading(true);
        const { data, error } = await supabase
            .from("comments")
            .select(`
                *,
                author:profiles(username, avatar_url, follower_count)
            `)
            .eq("video_id", videoId)
            .order("created_at", { ascending: true });

        if (error) {
            console.error("Error fetching comments:", error);
        } else {
            setComments(data || []);
        }
        setCommentsLoading(false);
    };

    const handleLikeComment = async (commentId: string, currentLikes: number) => {
        setComments((prev: Comment[]) => prev.map((c: Comment) => c.id === commentId ? { ...c, likes: c.likes + 1 } : c));
        const { error } = await supabase.rpc('increment_comment_likes', { comment_id: commentId });
        if (error) {
            setComments((prev: Comment[]) => prev.map((c: Comment) => c.id === commentId ? { ...c, likes: currentLikes } : c));
        }
    };

    const renderComments = (parentId: string | null = null, depth = 0): React.ReactNode[] => {
        return comments
            .filter((c: Comment) => c.parent_id === parentId)
            .map((comment: Comment) => (
                <div key={comment.id} className={`flex flex-col ${depth > 0 ? "ml-8 mt-5 border-l border-white/5 pl-4" : "mt-8"}`}>
                    <div className="flex gap-4">
                        <div className="w-10 h-10 rounded-2xl overflow-hidden flex-shrink-0 bg-white/5 border border-white/10 flex items-center justify-center">
                            {comment.author?.avatar_url ? (
                                <img src={comment.author.avatar_url} className="w-full h-full object-cover" alt="" />
                            ) : (
                                <span className="text-xs">👤</span>
                            )}
                        </div>
                        <div className="flex-1">
                            <div className="flex items-center gap-2">
                                <span className="font-black text-xs text-white uppercase italic tracking-wider">
                                    @{comment.author?.username || "ANONYMOUS_NODE"}
                                </span>
                            </div>
                            <p className="text-sm text-white/70 mt-1 leading-relaxed">{comment.text}</p>
                            <div className="flex items-center gap-6 mt-3 text-[9px] font-black text-white/30 uppercase tracking-[0.2em] italic">
                                <span>{new Date(comment.created_at).toLocaleDateString()}</span>
                                <button
                                    onClick={() => handleLikeComment(comment.id, comment.likes)}
                                    className="hover:text-red-500 transition-colors flex items-center gap-1.5"
                                >
                                    ❤️ {comment.likes}
                                </button>
                                <button className="hover:text-white transition-colors">REPLY</button>
                            </div>
                        </div>
                    </div>
                    {renderComments(comment.id, depth + 1)}
                </div>
            ));
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-black flex items-center justify-center">
                <div className="animate-pulse flex flex-col items-center gap-4">
                    <div className="h-10 w-10 bg-red-600 rounded-full blur-xl opacity-50"></div>
                    <span className="text-[9px] font-black tracking-[0.5em] text-zinc-500 uppercase italic">Intercepting Broadcast...</span>
                </div>
            </div>
        );
    }

    if (!video) {
        return (
            <div className="min-h-screen bg-black flex flex-col items-center justify-center text-white gap-6">
                <div className="text-4xl">📡</div>
                <h1 className="text-xs font-black tracking-[0.4em] uppercase italic text-red-500">BROADCAST_NOT_FOUND</h1>
                <button onClick={() => router.push("/")} className="px-8 py-3 bg-white/5 border border-white/10 rounded-full font-black text-[10px] uppercase tracking-widest hover:bg-white/10 transition-all">Return to Node</button>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-black text-white flex flex-col items-center justify-center p-4 relative overflow-hidden">
            {/* Background Aesthetics */}
            <div className="absolute inset-0 z-0">
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-red-600/5 rounded-full blur-[120px]"></div>
                <div className="absolute inset-0 opacity-[0.02]" style={{ backgroundImage: 'radial-gradient(circle, white 1px, transparent 1px)', backgroundSize: '40px 40px' }}></div>
            </div>

            <div className="w-full max-w-6xl aspect-[16/9] bg-zinc-900/40 backdrop-blur-3xl border border-white/5 rounded-[48px] overflow-hidden flex shadow-2xl relative z-10 transition-all hover:border-white/10">
                {/* Immersive Player Area */}
                <div className="flex-1 bg-black relative flex items-center justify-center group">
                    <video src={video.video_url} className="w-full h-full object-contain" autoPlay loop controls />

                    {/* Floating Info Tag */}
                    <div className="absolute top-8 left-8 bg-black/40 backdrop-blur-xl border border-white/10 px-4 py-2 rounded-2xl flex items-center gap-3">
                        <div className="w-2 h-2 bg-red-600 rounded-full animate-pulse"></div>
                        <span className="text-[9px] font-black tracking-[0.2em] uppercase italic">Neural Feed: LIVE</span>
                    </div>
                </div>

                {/* Interactive Sidebar */}
                <div className="w-96 flex flex-col bg-zinc-900/40 backdrop-blur-3xl border-l border-white/5 font-medium">
                    <div className="p-8 border-b border-white/5 space-y-6">
                        <div className="flex items-center gap-4">
                            <div className="w-12 h-12 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center shadow-lg">
                                <span className="text-lg">👤</span>
                            </div>
                            <div className="flex flex-col">
                                <h2 className="text-lg font-black tracking-tight italic uppercase block leading-none">@{video.username}</h2>
                                <span className="text-[9px] font-black text-zinc-500 tracking-widest uppercase mt-1">Verified Author</span>
                            </div>
                        </div>

                        <p className="text-sm text-white/70 leading-relaxed font-medium line-clamp-3">{video.description}</p>

                        <div className="flex items-center gap-8 py-2">
                            <div className="flex flex-col items-center gap-1">
                                <span className="text-red-500 text-lg">❤️</span>
                                <span className="text-[10px] font-black italic">{video.likes}</span>
                            </div>
                            <div className="flex flex-col items-center gap-1">
                                <span className="text-white text-lg">💬</span>
                                <span className="text-[10px] font-black italic">{video.comments}</span>
                            </div>
                            <div className="flex flex-col items-center gap-1 opacity-40">
                                <span className="text-white text-lg">🔗</span>
                                <span className="text-[10px] font-black italic">SHR</span>
                            </div>
                        </div>

                        <div className="bg-white/5 border border-white/5 rounded-2xl p-4 flex items-center gap-4 transition-all hover:bg-white/10">
                            <div className="w-8 h-8 rounded-full bg-red-600/20 flex items-center justify-center animate-spin-slow">
                                <span className="text-xs">🎵</span>
                            </div>
                            <div className="flex flex-col">
                                <span className="text-[9px] font-black text-zinc-500 uppercase tracking-widest">Audio Profile</span>
                                <span className="text-[10px] font-black text-white italic truncate w-40 uppercase">{video.music_title || "ORIGINAL_BROADCAST"}</span>
                            </div>
                        </div>
                    </div>

                    {/* Infinite Scroll Comments */}
                    <div className="flex-1 overflow-y-auto px-8 py-6 custom-scrollbar scroll-smooth">
                        {commentsLoading ? (
                            <div className="h-full flex flex-col items-center justify-center gap-4 opacity-20">
                                <div className="h-4 w-4 border-2 border-white/40 border-t-white rounded-full animate-spin"></div>
                                <span className="text-[10px] font-black tracking-widest uppercase italic">Syncing Whispers...</span>
                            </div>
                        ) : (
                            <>
                                {comments.length === 0 ? (
                                    <div className="h-full flex flex-col items-center justify-center text-center opacity-20 italic">
                                        <span className="text-3xl mb-4">😶</span>
                                        <span className="text-[10px] font-black tracking-widest uppercase">The silence is neural.</span>
                                    </div>
                                ) : (
                                    renderComments()
                                )}
                            </>
                        )}
                    </div>

                    {/* Footer Actions */}
                    <div className="p-8 border-t border-white/5 bg-black/20">
                        <button onClick={() => router.push("/auth")} className="w-full py-4 bg-red-600 rounded-2xl font-black text-[10px] uppercase tracking-[0.4em] hover:bg-red-700 transition-all shadow-xl shadow-red-600/10 active:scale-95">Download Neural Link</button>
                    </div>
                </div>
            </div>

            {/* Global Context Decorations */}
            <div className="absolute top-12 left-12 flex flex-col gap-1 opacity-20 pointer-events-none">
                <span className="text-[8px] font-black tracking-[1em] uppercase">Visual Node Intercept</span>
                <div className="h-0.5 w-full bg-white/20"></div>
            </div>
            <div className="absolute bottom-12 right-12 text-right opacity-20 pointer-events-none">
                <span className="text-[8px] font-black tracking-[0.5em] uppercase">Phase 2.0.7X</span>
                <span className="text-[8px] font-black tracking-[0.5em] uppercase block mt-1 italic">Authorized Viewing Terminal</span>
            </div>
        </div>
    );
}
