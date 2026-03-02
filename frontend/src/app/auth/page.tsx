"use client";

import { useState } from "react";
import { supabase } from "@/lib/supabaseClient";
import { useRouter } from "next/navigation";

export default function AuthPage() {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [loading, setLoading] = useState(false);
    const [isSignUp, setIsSignUp] = useState(false);
    const [message, setMessage] = useState<{ type: "error" | "success"; text: string } | null>(null);
    const router = useRouter();

    const handleAuth = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setMessage(null);

        try {
            if (isSignUp) {
                const { error } = await supabase.auth.signUp({ email, password });
                if (error) throw error;
                setMessage({ type: "success", text: "NEURAL_CONFIRMATION_SENT" });
                setIsSignUp(false);
            } else {
                const { error } = await supabase.auth.signInWithPassword({ email, password });
                if (error) throw error;
                router.push("/");
            }
        } catch (error: any) {
            setMessage({ type: "error", text: error.message.toUpperCase() });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-black flex flex-col items-center justify-center p-6 relative overflow-hidden">
            {/* Background Aesthetics */}
            <div className="absolute inset-0 z-0">
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-red-600/5 rounded-full blur-[100px]"></div>
                <div className="absolute inset-0 opacity-[0.02]" style={{ backgroundImage: 'radial-gradient(circle, white 1px, transparent 1px)', backgroundSize: '30px 30px' }}></div>
            </div>

            <div className="w-full max-w-md space-y-12 relative z-10 text-center">
                <div className="space-y-4">
                    <h1 className="text-5xl font-black text-white tracking-tighter uppercase italic leading-none">
                        AUTH<span className="text-red-600">NODE</span>
                    </h1>
                    <p className="text-[10px] font-black tracking-[0.5em] text-zinc-500 uppercase italic">
                        Planetary Access Protocol
                    </p>
                </div>

                <div className="bg-zinc-900/40 backdrop-blur-3xl border border-white/5 p-10 rounded-[40px] shadow-2xl">
                    <form onSubmit={handleAuth} className="space-y-6">
                        <div className="space-y-4 text-left">
                            <div>
                                <label className="text-[10px] font-black text-white/40 uppercase tracking-widest block mb-3 ml-2 italic">Neural Node ID (Email)</label>
                                <input
                                    type="email"
                                    required
                                    className="w-full bg-white/5 border border-white/10 rounded-2xl px-6 py-4 text-white text-xs font-bold focus:outline-none focus:ring-2 focus:ring-red-600 focus:bg-white/10 transition-all uppercase tracking-widest"
                                    placeholder="YOU@EXAMPLE.COM"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                />
                            </div>
                            <div>
                                <label className="text-[10px] font-black text-white/40 uppercase tracking-widest block mb-3 ml-2 italic">Access Key (Password)</label>
                                <input
                                    type="password"
                                    required
                                    className="w-full bg-white/5 border border-white/10 rounded-2xl px-6 py-4 text-white text-xs font-bold focus:outline-none focus:ring-2 focus:ring-red-600 focus:bg-white/10 transition-all uppercase tracking-widest"
                                    placeholder="••••••••"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                />
                            </div>
                        </div>

                        {message && (
                            <div className={`p-4 rounded-2xl text-[10px] font-black tracking-widest uppercase italic ${message.type === "error" ? "bg-red-500/10 text-red-500 border border-red-500/20" : "bg-green-500/10 text-green-500 border border-green-500/20"}`}>
                                {message.text}
                            </div>
                        )}

                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full bg-red-600 hover:bg-red-700 text-white font-black py-4 rounded-2xl text-[10px] uppercase tracking-[0.5em] transition-all shadow-xl shadow-red-600/20 active:scale-95 disabled:opacity-50"
                        >
                            {loading ? "SYNCHRONIZING..." : (isSignUp ? "INITIALIZE_NODE" : "ESTABLISH_LINK")}
                        </button>
                    </form>

                    <div className="mt-10 pt-8 border-t border-white/5">
                        <button
                            onClick={() => {
                                setIsSignUp(!isSignUp);
                                setMessage(null);
                            }}
                            className="text-[10px] font-black tracking-[0.3em] text-zinc-500 hover:text-white uppercase transition-colors italic"
                        >
                            {isSignUp ? "Already In Segment? established Link" : "No Node Assigned? Initialize"}
                        </button>
                    </div>
                </div>

                <div className="flex flex-col gap-2 opacity-20">
                    <span className="text-[8px] font-black text-white tracking-[1em] uppercase block">Secure Planetary Bridge</span>
                    <span className="text-[8px] font-black text-white tracking-[0.5em] uppercase block">0x00A1-44-BEEF</span>
                </div>
            </div>
        </div>
    );
}
