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
                <div key={comment.id} className={`flex flex-col ${depth > 0 ? "ml-8 mt-4 border-l border-white/10 pl-4" : "mt-6"}`}>
                    <div className="flex gap-3">
                        <div className="w-8 h-8 rounded-full overflow-hidden flex-shrink-0 bg-white/10">
                            {comment.author?.avatar_url && (
                                <img src={comment.author.avatar_url} className="w-full h-full object-cover" alt="" />
                            )}
                        </div>
                        <div className="flex-1">
                            <div className="flex items-center gap-1.5">
                                <span className="font-bold text-sm text-white/90">
                                    {comment.author?.username || "user"}
                                </span>
                            </div>
                            <p className="text-sm text-white/70 mt-0.5">{comment.text}</p>
                            <div className="flex items-center gap-4 mt-2 text-[10px] font-bold text-white/40 uppercase tracking-widest">
                                <span>{new Date(comment.created_at).toLocaleDateString()}</span>
                                <button
                                    onClick={() => handleLikeComment(comment.id, comment.likes)}
                                    className="hover:text-pink-500 transition-colors flex items-center gap-1"
                                >
                                    ❤️ {comment.likes}
                                </button>
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
                <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-white"></div>
            </div>
        );
    }

    if (!video) {
        return (
            <div className="min-h-screen bg-black flex flex-col items-center justify-center text-white gap-4">
                <h1 className="text-2xl font-bold">Broadcast Lost</h1>
                <button onClick={() => router.push("/")} className="px-6 py-2 bg-white/10 rounded-xl font-bold text-sm">Return to Command</button>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-black text-white flex flex-col items-center justify-center p-4">
            <div className="w-full max-w-5xl aspect-[16/9] bg-black border border-white/10 rounded-3xl overflow-hidden flex shadow-2xl">
                <div className="flex-1 bg-black relative">
                    <video src={video.video_url} className="w-full h-full object-contain" autoPlay loop controls />
                </div>
                <div className="w-80 sm:w-96 flex flex-col bg-zinc-900/50 backdrop-blur-xl border-l border-white/10">
                    <div className="p-6 border-b border-white/10">
                        <h2 className="text-xl font-bold tracking-tight italic uppercase mb-2">@{video.username}</h2>
                        <p className="text-sm text-white/60 mb-4">{video.description}</p>
                        <div className="flex items-center gap-4 text-xs font-bold text-white/40 uppercase tracking-[0.2em]">
                            <span>❤️ {video.likes}</span>
                            <span>💬 {video.comments || comments.length}</span>
                        </div>
                    </div>
                    <div className="flex-1 overflow-y-auto px-6 py-4 custom-scrollbar">
                        {commentsLoading ? (
                            <div className="h-full flex items-center justify-center opacity-20 italic font-bold">Loading...</div>
                        ) : (
                            <>
                                {comments.length === 0 ? (
                                    <div className="h-full flex flex-col items-center justify-center text-white/20 italic font-bold text-sm tracking-widest text-center px-10">No whispers yet.</div>
                                ) : (
                                    renderComments()
                                )}
                            </>
                        )}
                    </div>
                    <div className="p-6 border-t border-white/10">
                        <button onClick={() => router.push("/")} className="w-full py-3 bg-white/5 border border-white/10 rounded-xl font-bold text-xs uppercase tracking-[0.2em] hover:bg-white/10 transition-all">Download Trueworld App</button>
                    </div>
                </div>
            </div>
        </div>
    );
}
