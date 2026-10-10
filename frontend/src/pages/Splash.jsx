import React, { useEffect, useState } from 'react';

export default function Splash({ onNavigate }) {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(timer);
          return 100;
        }
        return prev + 5;
      });
    }, 100);

    const redirect = setTimeout(() => {
      onNavigate('auth');
    }, 2000);

    return () => {
      clearInterval(timer);
      clearTimeout(redirect);
    };
  }, [onNavigate]);

  return (
    <div className="flex-1 flex flex-col justify-between p-8 select-none bg-[#F1F0EA]">
      {/* Top spacing & brand header */}
      <div className="flex flex-col items-center mt-12 text-center">
        {/* Signature 3D Offset Box Logo */}
        <div className="relative w-20 h-20 mb-5">
          <div className="absolute inset-0 border-2 border-[#3046B4] rounded-[28px] translate-x-1.5 translate-y-1.5 opacity-40"></div>
          <div className="absolute inset-0 bg-[#3046B4] rounded-[28px] shadow-lg flex items-center justify-center text-white">
            <svg className="w-10 h-10 text-white animate-pulse" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>

        <h1 className="text-2xl font-bold text-[#3046B4] tracking-tight">Nama Aplikasi</h1>
        <p className="text-xs text-[#3046B4]/70 mt-1.5 font-medium max-w-[260px] leading-relaxed">
          Multimodal AI Depression & Burnout Detection
        </p>

        <div className="mt-6 flex items-center gap-2 bg-[#3046B4]/10 text-[#3046B4] text-[11px] font-semibold px-3 py-1 rounded-full border border-[#3046B4]/20">
          <span className="w-2 h-2 rounded-full bg-[#3046B4] animate-ping"></span>
          <span>Inisialisasi Sistem Sensor AI</span>
        </div>
      </div>

      {/* Center illustration badge */}
      <div className="flex flex-col items-center justify-center my-auto py-8">
        <div className="w-44 h-44 rounded-full bg-white/70 border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a] flex flex-col items-center justify-center p-4 text-center">
          <div className="flex gap-2 mb-2">
            <span className="w-3 h-3 rounded-full bg-[#3046B4]"></span>
            <span className="w-3 h-3 rounded-full bg-[#FFC436]"></span>
            <span className="w-3 h-3 rounded-full bg-[#10B981]"></span>
          </div>
          <span className="text-xs font-bold text-slate-900">4 Biomarker Temporal</span>
          <span className="text-[10px] text-[#5C5C5C] mt-1">Motorik • Vokal • Visual • Kognitif</span>
        </div>
      </div>

      {/* Bottom CTA & Auto Redirect Progress */}
      <div className="flex flex-col items-center gap-3 mb-6">
        <div className="w-full max-w-xs bg-slate-200 h-1.5 rounded-full overflow-hidden mb-2">
          <div
            className="bg-[#3046B4] h-full transition-all duration-100 ease-out"
            style={{ width: `${progress}%` }}
          ></div>
        </div>

        <button
          onClick={() => onNavigate('auth')}
          className="w-full max-w-xs bg-[#3046B4] hover:bg-[#273a96] active:scale-95 text-white font-bold py-3.5 px-6 rounded-full shadow-lg transition-all flex items-center justify-center gap-2"
        >
          <span>Masuk Sekarang</span>
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
          </svg>
        </button>
        <p className="text-[11px] text-[#3046B4]/60 font-medium">Versi Prototipe Interaktif 1.0 (Otomatis dialihkan...)</p>
      </div>
    </div>
  );
}
