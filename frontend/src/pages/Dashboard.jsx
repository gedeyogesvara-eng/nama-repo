import React, { useState } from 'react';
import Header from '../components/Header';

export default function Dashboard({ onNavigate }) {
  const [showHistoryModal, setShowHistoryModal] = useState(false);

  const historyRecords = [
    { date: 'Hari ini, 09:30', status: 'Prima (Normal)', score: '98%', color: 'text-emerald-600 bg-emerald-50 border-emerald-200' },
    { date: 'Kemarin, 21:15', status: 'Kelelahan Ringan', score: '72%', color: 'text-amber-600 bg-amber-50 border-amber-200' },
    { date: '8 Okt 2026, 14:00', status: 'Prima (Normal)', score: '94%', color: 'text-emerald-600 bg-emerald-50 border-emerald-200' },
  ];

  return (
    <div className="flex-1 flex flex-col justify-between p-4 select-none bg-[#F1F0EA] relative">
      <div>
        <Header showNotification={true} />

        {/* Middle Signature Offset Canvas (3D Shadow Effect from Google Stitch) */}
        <div className="relative w-64 h-64 mx-auto mt-4 mb-4">
          {/* Border outline (shadow) */}
          <div className="absolute inset-0 border-[3px] border-[#3046B4] rounded-[32px] translate-x-3 translate-y-3"></div>

          {/* Main colored canvas */}
          <div className="absolute inset-0 bg-[#3046B4] rounded-[32px] p-5 flex flex-col justify-between z-10 overflow-hidden shadow-sm text-white border-2 border-slate-900">
            <div className="flex justify-between items-center text-white/80">
              <span className="text-[11px] tracking-wider font-semibold uppercase">Daily Mood</span>
              <div className="flex gap-1.5 items-center">
                <span className="w-2.5 h-2.5 rounded-full bg-[#FFC436] animate-pulse"></span>
                <span className="w-2 h-2 rounded-full bg-white/40"></span>
              </div>
            </div>

            {/* Inner Night / Emotional Balance Illustration */}
            <div className="relative flex-1 flex flex-col items-center justify-center my-2">
              <div className="w-24 h-24 rounded-full bg-white/10 flex items-center justify-center relative backdrop-blur-sm border border-white/20">
                {/* Crescent Moon */}
                <svg className="w-14 h-14 text-[#FFC436] drop-shadow-md" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12.3 2a10 10 0 0 0-1.9 20 10 10 0 0 0 9.6-7.3 1 1 0 0 0-1.2-1.2 8 8 0 1 1-7.7-12.7 1 1 0 0 0 1.2-1.2A10 10 0 0 0 12.3 2z" />
                </svg>
                {/* Sparkle Stars */}
                <span className="absolute top-2 right-3 text-[#FFC436] text-xs font-bold animate-pulse">✦</span>
                <span className="absolute bottom-3 left-3 text-white text-[10px] animate-pulse">★</span>
              </div>
            </div>

            <div className="text-center">
              <p className="text-xs text-white/95 font-semibold tracking-wide">Siklus Emosi: Tenang & Terjaga</p>
              <p className="text-[10px] text-white/70">Terakhir diperbarui 2 jam yang lalu</p>
            </div>
          </div>
        </div>

        {/* Text Below Canvas */}
        <div className="text-center mt-3">
          <h2 className="text-xl font-black text-[#3046B4] tracking-tight">Nama Aplikasi</h2>
          <p className="text-xs text-[#3046B4] font-medium tracking-wide mt-0.5">Maintain your emotions & mental wellbeing</p>
        </div>

        {/* Quick Biomarker Status Indicator Bar */}
        <div className="grid grid-cols-3 gap-2 px-6 mt-4">
          <div className="bg-white/80 border border-[#3046B4]/20 rounded-xl p-2 text-center shadow-sm">
            <span className="text-[10px] text-[#5C5C5C] block">Gait IMU</span>
            <span className="text-xs font-bold text-emerald-600">Stabil</span>
          </div>
          <div className="bg-white/80 border border-[#3046B4]/20 rounded-xl p-2 text-center shadow-sm">
            <span className="text-[10px] text-[#5C5C5C] block">Prosodi Suara</span>
            <span className="text-xs font-bold text-emerald-600">Jernih</span>
          </div>
          <div className="bg-white/80 border border-[#3046B4]/20 rounded-xl p-2 text-center shadow-sm">
            <span className="text-[10px] text-[#5C5C5C] block">Mikro-Sklera</span>
            <span className="text-xs font-bold text-[#3046B4]">Siap Scan</span>
          </div>
        </div>
      </div>

      {/* Bottom: 2 Stacked Pill Buttons (Neo-brutalist Offset Styling) */}
      <div className="flex flex-col items-center gap-3.5 mb-4 w-full">
        {/* Tombol Raksasa Mulai Skrining */}
        <button
          onClick={() => onNavigate('stage1')}
          className="w-4/5 max-w-xs bg-[#3046B4] hover:bg-[#273a96] active:scale-95 text-white font-black py-4 px-6 rounded-full text-base transition-all flex items-center justify-center gap-3 border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a]"
        >
          <span className="tracking-wide">Mulai Skrining</span>
          <svg className="w-5 h-5 animate-pulse" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M14 5l7 7m0 0l-7 7m7-7H3" />
          </svg>
        </button>

        <button
          onClick={() => setShowHistoryModal(true)}
          className="w-4/5 max-w-xs bg-[#5C5C5C] hover:bg-[#4b4b4b] active:scale-95 text-white font-bold py-3.5 rounded-full text-sm transition-all border-2 border-slate-900 shadow-[4px_4px_0px_#0f172a] flex items-center justify-center gap-2"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>Riwayat Skrining</span>
        </button>
      </div>

      {/* Bottom Logout icon */}
      <button
        onClick={() => onNavigate('auth')}
        className="absolute bottom-5 right-6 text-[#3046B4] hover:opacity-75 transition p-2 bg-white/60 rounded-full border border-slate-300 shadow-sm"
        title="Keluar / Ganti Akun"
      >
        <svg className="w-5 h-5 stroke-[2]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
        </svg>
      </button>

      {/* History Modal Dialog */}
      {showHistoryModal && (
        <div className="absolute inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-[#F1F0EA] border-2 border-slate-900 rounded-3xl p-5 shadow-[8px_8px_0px_#0f172a] w-full max-w-sm">
            <div className="flex justify-between items-center mb-4">
              <h3 className="font-bold text-base text-[#3046B4]">Riwayat Biomarker</h3>
              <button
                onClick={() => setShowHistoryModal(false)}
                className="w-7 h-7 rounded-full bg-slate-200 hover:bg-slate-300 flex items-center justify-center text-slate-700 font-bold"
              >
                ✕
              </button>
            </div>

            <div className="flex flex-col gap-2.5 max-h-60 overflow-y-auto no-scrollbar">
              {historyRecords.map((item, idx) => (
                <div key={idx} className={`p-3 rounded-2xl border ${item.color} flex justify-between items-center`}>
                  <div>
                    <span className="text-xs font-bold block">{item.status}</span>
                    <span className="text-[10px] text-gray-600">{item.date}</span>
                  </div>
                  <span className="text-xs font-black bg-white/80 px-2.5 py-1 rounded-full border border-current">
                    {item.score}
                  </span>
                </div>
              ))}
            </div>

            <button
              onClick={() => setShowHistoryModal(false)}
              className="w-full mt-4 bg-[#3046B4] text-white py-2.5 rounded-xl font-bold text-xs border border-slate-900 shadow-[3px_3px_0px_#0f172a]"
            >
              Tutup
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
