import React from 'react';
import Header from '../components/Header';

export default function ResultHealthy({ onNavigate }) {
  return (
    <div className="flex-1 flex flex-col justify-between p-6 select-none bg-gradient-to-b from-[#F1F0EA] via-[#ecfdf5] to-[#F1F0EA]">
      <div>
        <Header
          title="Hasil Skrining"
          subtitle="Kondisi Prima"
          onNavigate={onNavigate}
        />

        <div className="flex flex-col items-center text-center mt-2 px-3">
          {/* Avatar of happy fit person with 100% bugar badge */}
          <div className="w-24 h-24 rounded-full bg-emerald-100 border-4 border-emerald-500 shadow-xl flex items-center justify-center text-emerald-600 mb-3 relative">
            <svg className="w-14 h-14" fill="currentColor" viewBox="0 0 24 24">
              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm3.88-11.71L10 14.17l-1.88-1.88a.996.996 0 1 0-1.41 1.41l2.59 2.59c.39.39 1.02.39 1.41 0L17.3 9.7a.996.996 0 1 0-1.42-1.41z" />
            </svg>
            <span className="absolute -bottom-2 bg-emerald-600 text-white text-[10px] font-black px-2.5 py-0.5 rounded-full shadow-md border border-white">
              100% Bugar
            </span>
          </div>

          <h2 className="text-2xl font-black text-emerald-800 tracking-tight">Kondisi Anda Prima!</h2>
          <p className="text-xs text-emerald-700 mt-1 font-medium">
            Tidak terdeteksi indikator depresi maupun burnout signifikan pada seluruh sensor.
          </p>

          {/* Biomarker Breakdown Grid */}
          <div className="grid grid-cols-2 gap-2 w-full mt-4">
            <div className="bg-white/90 p-2.5 rounded-xl border border-emerald-200 text-left">
              <span className="text-[10px] text-gray-500 block">Biomarker Mental</span>
              <span className="text-xs font-bold text-emerald-700">Tekanan Goresan Rileks</span>
            </div>
            <div className="bg-white/90 p-2.5 rounded-xl border border-emerald-200 text-left">
              <span className="text-[10px] text-gray-500 block">Biomarker Fisik</span>
              <span className="text-xs font-bold text-emerald-700">Gait Ritmis & Simetris</span>
            </div>
            <div className="bg-white/90 p-2.5 rounded-xl border border-emerald-200 text-left">
              <span className="text-[10px] text-gray-500 block">Biomarker Audio</span>
              <span className="text-xs font-bold text-emerald-700">Prosodi Dinamis Normal</span>
            </div>
            <div className="bg-white/90 p-2.5 rounded-xl border border-emerald-200 text-left">
              <span className="text-[10px] text-gray-500 block">Biomarker Visual</span>
              <span className="text-xs font-bold text-emerald-700">Fiksasi Pupil Segar</span>
            </div>
          </div>

          {/* Tips Card: Neo-brutalist Offset Design */}
          <div className="bg-white rounded-[24px] p-4.5 shadow-sm border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a] w-full mt-4 text-left">
            <div className="flex items-center gap-2 text-emerald-700 font-bold text-xs uppercase tracking-wider mb-2">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span>Rekomendasi Preservasi</span>
            </div>
            <p className="text-sm font-bold text-gray-900">"Pertahankan ritme kerja dan hidrasi tubuh."</p>
            <ul className="text-xs text-[#5C5C5C] mt-2 space-y-1.5 list-disc list-inside font-medium">
              <li>Pertahankan waktu tidur berkualitas 7-8 jam per malam.</li>
              <li>Lakukan peregangan ringan setiap 90 menit bekerja.</li>
              <li>Jaga interaksi sosial yang hangat bersama keluarga & sahabat.</li>
            </ul>
          </div>
        </div>
      </div>

      {/* Bottom Button: Selesai -> onNavigate('dashboard') */}
      <div className="flex flex-col items-center pb-4 mt-4">
        <button
          onClick={() => onNavigate('dashboard')}
          className="w-3/4 max-w-xs bg-emerald-600 hover:bg-emerald-700 active:scale-95 text-white font-bold py-3.5 rounded-full text-sm transition-all flex items-center justify-center gap-2 border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a]"
        >
          <span>Selesai & Simpan Hasil</span>
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7" />
          </svg>
        </button>
      </div>
    </div>
  );
}
