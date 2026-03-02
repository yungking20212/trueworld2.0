"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabaseClient";

interface AINews {
    id: string;
    title: string;
    content: string;
    category: string;
    is_prediction: boolean;
    created_at: string;
}

export default function AINewsPage() {
    const [news, setNews] = useState<AINews[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchNews() {
            const { data, error } = await supabase
                .from("ai_news")
                .select("*")
                .order("created_at", { ascending: false });

            if (error) {
                console.error("Error fetching news:", error);
                // Fallback sample data
                setNews([
                    {
                        id: "1",
                        title: "AI Predicts: Virtual Cities by 2030",
                        content: "Our AI engine analyzes urban development trends and suggests the first fully autonomous virtual twin cities will emerge within this decade, revolutionizing remote work and social interaction.",
                        category: "Future Tech",
                        is_prediction: true,
                        created_at: new Date().toISOString(),
                    },
                    {
                        id: "2",
                        title: "Celebrity AI clones are the new reality",
                        content: "Today's data shows a 300% increase in licensed AI voice and image usage for major A-list stars. Experts predict a shift from physical appearances to digital presence by late next year.",
                        category: "Celebrity",
                        is_prediction: false,
                        created_at: new Date().toISOString(),
                    }
                ]);
            } else {
                setNews(data || []);
            }
            setLoading(false);
        }
        fetchNews();
    }, []);

    return (
        <div className="min-h-screen bg-black text-white p-6 font-sans">
            <div className="max-w-4xl mx-auto">
                <header className="mb-12 flex justify-between items-end">
                    <div>
                        <h1 className="text-4xl font-black italic tracking-tighter bg-gradient-to-r from-pink-500 to-purple-600 bg-clip-text text-transparent">
                            VANTAGE AI NEWS
                        </h1>
                        <p className="text-gray-400 font-medium">Predictive Intelligence Social Hub</p>
                    </div>
                    <div className="text-right">
                        <span className="text-[10px] font-bold text-pink-500 animate-pulse">● LIVE DATA FEED</span>
                    </div>
                </header>

                {loading ? (
                    <div className="flex justify-center items-center h-64">
                        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-pink-500"></div>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        {news.map((item) => (
                            <div
                                key={item.id}
                                className="group relative bg-white/5 border border-white/10 p-8 rounded-3xl backdrop-blur-xl hover:border-pink-500/30 transition-all duration-500"
                            >
                                <div className="flex justify-between items-start mb-6">
                                    <span className={`text-[10px] font-black px-3 py-1 rounded-full border ${item.is_prediction ? "text-cyan-400 border-cyan-400/30" : "text-gray-500 border-white/10"
                                        }`}>
                                        {item.category.toUpperCase()}
                                    </span>
                                    {item.is_prediction && (
                                        <span className="text-[9px] font-black bg-gradient-to-r from-pink-500 to-purple-600 px-3 py-1 rounded-full shadow-lg shadow-pink-500/20">
                                            AI PREDICTION
                                        </span>
                                    )}
                                </div>

                                <h2 className="text-2xl font-bold mb-4 group-hover:text-pink-400 transition-colors">
                                    {item.title}
                                </h2>

                                <p className="text-gray-400 leading-relaxed mb-6">
                                    {item.content}
                                </p>

                                <div className="flex justify-between items-center mt-auto pt-6 border-t border-white/5">
                                    <time className="text-[10px] text-gray-600 uppercase tracking-widest font-bold">
                                        {new Date(item.created_at).toLocaleDateString()}
                                    </time>
                                    <button className="text-[11px] font-bold hover:text-pink-500 transition-colors">
                                        READ ANALYSIS →
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}
