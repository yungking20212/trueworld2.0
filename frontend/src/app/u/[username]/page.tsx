"use client";

import React, { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";
import Image from "next/image";

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

interface Profile {
    id: string;
    username: string;
    full_name: string | null;
    avatar_url: string | null;
    bio: string | null;
    follower_count: number;
    following_count: number;
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

export default function ProfilePage() {
    const params = useParams();
    const username = params?.username as string;
    const [profile, setProfile] = useState<Profile | null>(null);
    const [videos, setVideos] = useState<Video[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedVideo, setSelectedVideo] = useState<Video | null>(null);
    const [comments, setComments] = useState<Comment[]>([]);
    const [commentsLoading, setCommentsLoading] = useState(false);

    useEffect(() => {
        if (!username) return;

        async function fetchProfileData() {
            // Fetch profile by username
            const { data: profileData, error: profileError } = await supabase
                .from("profiles")
                .select("*")
                .eq("username", username)
                .single();

            if (profileError) {
                console.error("Error fetching profile:", profileError);
                setLoading(false);
                return;
            }

            setProfile(profileData);

            // Fetch user videos
            const { data: videoData, error: videoError } = await supabase
                .from("videos")
                .select("*")
                .eq("author_id", profileData.id);

            if (videoError) {
                console.error("Error fetching videos:", videoError);
            } else {
                setVideos(videoData || []);
            }

            setLoading(false);
        }

        fetchProfileData();
    }, [username]);

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

    const handleVideoClick = (video: Video) => {
        setSelectedVideo(video);
        fetchComments(video.id);
    };

    const handleLikeComment = async (commentId: string, currentLikes: number) => {
        // Optimistic UI
        setComments((prev: Comment[]) => prev.map((c: Comment) => c.id === commentId ? { ...c, likes: c.likes + 1 } : c));

        const { error } = await supabase.rpc('increment_comment_likes', { comment_id: commentId });
        if (error) {
            console.error("Error liking comment:", error);
            // Revert on error
            setComments((prev: Comment[]) => prev.map((c: Comment) => c.id === commentId ? { ...c, likes: currentLikes } : c));
        }
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-black flex items-center justify-center">
                <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-white"></div>
            </div>
        );
    }

    if (!profile) {
        return (
            <div className="min-h-screen bg-black flex items-center justify-center text-white font-bold text-xl">
                User not found
            </div>
        );
    }

    // Helper to render comments recursively
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
                                {(comment.author?.follower_count || 0) >= 50 && (
                                    <span className="text-[10px] text-blue-400" title="Verified">✓</span>
                                )}
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
                                <button className="hover:text-white transition-colors">Reply</button>
                            </div>
                        </div>
                    </div>
                    {/* Recursive call for replies */}
                    {renderComments(comment.id, depth + 1)}
                </div>
            ));
    };

    return (
        <div className="min-h-screen bg-black text-white selection:bg-pink-500/30">
            {/* Hero Section */}
            <div className="relative pt-20 pb-10 px-6 flex flex-col items-center overflow-hidden">
                <div
                    className="absolute top-0 left-1/2 -translate-x-1/2 w-[300px] h-[300px] rounded-full blur-[100px] opacity-20 pointer-events-none"
                    style={{ background: 'linear-gradient(45deg, #FF0080, #7928CA)' }}
                />

                <div className="relative mb-6">
                    <div className="w-32 h-32 rounded-full overflow-hidden border-2 border-white/10 shadow-[0_0_50px_rgba(255,0,128,0.3)]">
                        {profile.avatar_url ? (
                            <img src={profile.avatar_url} alt={profile.username} className="w-full h-full object-cover" />
                        ) : (
                            <div className="w-full h-full bg-gradient-to-br from-gray-800 to-gray-900 flex items-center justify-center text-4xl font-bold">
                                {profile.username[0].toUpperCase()}
                            </div>
                        )}
                    </div>
                </div>

                <div className="text-center mb-8">
                    <h1 className="text-3xl font-bold tracking-tight mb-1 flex items-center justify-center gap-2">
                        {profile.full_name || "Trueworld User"}
                        {profile.follower_count >= 50 && (
                            <span className="text-blue-500 text-xl" title="Verified">✓</span>
                        )}
                    </h1>
                    <p className="text-white/50 font-semibold mb-4 text-lg">@{profile.username}</p>

                    <div className="flex justify-center gap-10 mb-6">
                        <div className="flex flex-col items-center">
                            <span className="text-xl font-bold">{profile.following_count}</span>
                            <span className="text-xs text-white/40 uppercase tracking-widest font-bold">Following</span>
                        </div>
                        <div className="flex flex-col items-center">
                            <span className="text-xl font-bold">{profile.follower_count}</span>
                            <span className="text-xs text-white/40 uppercase tracking-widest font-bold">Followers</span>
                        </div>
                        <div className="flex flex-col items-center">
                            <span className="text-xl font-bold">
                                {videos.reduce((acc: number, v: Video) => acc + v.likes, 0)}
                            </span>
                            <span className="text-xs text-white/40 uppercase tracking-widest font-bold">Likes</span>
                        </div>
                    </div>

                    {profile.bio && <p className="max-w-xs mx-auto text-white/70 leading-relaxed text-sm">{profile.bio}</p>}
                </div>

                <button className="px-10 py-3 bg-white/5 border border-white/10 rounded-2xl font-bold text-sm backdrop-blur-xl hover:bg-white/10 transition-all hover:scale-105 active:scale-95">
                    Follow on Trueworld
                </button>
            </div>

            {/* Grid Section */}
            <div className="px-1 py-8">
                <div className="grid grid-cols-3 gap-1">
                    {videos.map((video) => (
                        <div
                            key={video.id}
                            onClick={() => handleVideoClick(video)}
                            className="aspect-[9/16] relative bg-gray-900 group cursor-pointer overflow-hidden rounded-sm hover:opacity-80 transition-opacity"
                        >
                            <video
                                src={video.video_url}
                                className="w-full h-full object-cover"
                                muted
                                onMouseOver={(e: React.MouseEvent<HTMLVideoElement>) => (e.currentTarget.play())}
                                onMouseOut={(e: React.MouseEvent<HTMLVideoElement>) => { e.currentTarget.pause(); e.currentTarget.currentTime = 0; }}
                            />
                            <div className="absolute bottom-2 left-2 flex items-center gap-1 text-[10px] font-bold text-white shadow-sm">
                                <span>▶</span> {video.likes}
                            </div>
                        </div>
                    ))}
                </div>

                {videos.length === 0 && (
                    <div className="py-20 text-center text-white/20 font-bold uppercase tracking-widest italic">
                        No videos uploaded yet
                    </div>
                )}
            </div>

            {/* Comments Modal Upgrade v2 */}
            {selectedVideo && (
                <div className="fixed inset-0 z-50 flex items-center justify-center px-4 py-6 sm:p-10 backdrop-blur-3xl bg-black/80 animate-in fade-in duration-300">
                    <div className="relative w-full max-w-5xl aspect-[16/9] bg-black border border-white/10 rounded-3xl overflow-hidden flex shadow-2xl">
                        {/* Video Side */}
                        <div className="flex-1 bg-black relative">
                            <video
                                src={selectedVideo.video_url}
                                className="w-full h-full object-contain"
                                autoPlay
                                loop
                                controls
                            />
                        </div>

                        {/* Comments Side */}
                        <div className="w-80 sm:w-96 flex flex-col bg-zinc-900/50 backdrop-blur-xl border-l border-white/10">
                            <div className="p-6 border-b border-white/10">
                                <div className="flex items-center justify-between mb-4">
                                    <h2 className="text-xl font-bold tracking-tight italic uppercase">Comments</h2>
                                    <button
                                        onClick={() => setSelectedVideo(null)}
                                        className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center hover:bg-white/10 transition-all font-bold"
                                    >
                                        ✕
                                    </button>
                                </div>
                                <div className="flex items-center gap-4 text-xs font-bold text-white/40 uppercase tracking-[0.2em]">
                                    <span className="flex items-center gap-1.5"><span className="text-pink-500">❤️</span> {selectedVideo.likes}</span>
                                    <span>💬 {selectedVideo.comments || comments.length}</span>
                                </div>
                            </div>

                            <div className="flex-1 overflow-y-auto px-6 py-4 custom-scrollbar">
                                {commentsLoading ? (
                                    <div className="h-full flex items-center justify-center opacity-20 italic font-bold">
                                        Loading V2 Threads...
                                    </div>
                                ) : (
                                    <>
                                        {comments.length === 0 ? (
                                            <div className="h-full flex flex-col items-center justify-center text-white/20 italic font-bold text-sm tracking-widest text-center px-10">
                                                No whispers in the street yet.
                                            </div>
                                        ) : (
                                            renderComments()
                                        )}
                                    </>
                                )}
                            </div>

                            {/* Input Stub */}
                            <div className="p-6 border-t border-white/10">
                                <div className="flex items-center gap-3 bg-white/5 border border-white/10 rounded-xl px-4 py-3 opacity-50 cursor-not-allowed">
                                    <span className="text-xs font-bold uppercase tracking-widest text-white/30 italic">Comments Closed on Web</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

        </div>
    );
}
