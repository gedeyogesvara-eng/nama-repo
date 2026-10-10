import React, { useState } from 'react';
import Header from '../components/Header';

export default function ResultExtreme({ onNavigate }) {
  const [showTelemedicineModal, setShowTelemedicineModal] = useState(false);

  return (
    <div className="flex-1 flex flex-col justify-between p-6 select-none bg-red-50 relative">
      <div>
        <Header
          title="Peringatan Medis"
          subtitle="Kondisi Kritis"
          onNavigate={onNavigate}
        />

        <div className="flex flex-col items-center text-center mt-2 px-2">
          {/* Avatar / warning icon with urgent pulsing animation */}
          <div className="w-22 h-22 rounded-full bg-red-100 border-4 border-red-500 shadow-xl flex items-center justify-center text-red-600 mb-3 animate-pulse">
            <svg className="w-12 h-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>

          {/* Red Alert Title */}
          <h2 className="text-xl font-black text-red-600 tracking-tight">
            Peringatan Mode Zombi Akut
          </h2>
          <p className="text-xs text-red-700 mt-1 font-semibold leading-relaxed">
            Indikator depresi berat dan kelelahan saraf akut terdeteksi pada 4 multimodal sensor.
          </p>

          {/* Warning Alert Box: Neo-brutalist Offset Design */}
          <div className="bg-white rounded-[24px] p-4.5 border-2 border-slate-900 border-l-8 border-l-red-600 shadow-[6px_6px_0px_#0f172a] w-full mt-4 text-left">
            <h3 className="text-xs font-black text-red-700 uppercase tracking-wider mb-1 flex items-center gap-1.5">
              <span>⚠️ Tindakan Cepat Dibutuhkan:</span>
            </h3>
            <p className="text-xs text-gray-800 leading-relaxed font-medium">
              Tubuh dan pikiran Anda berada dalam ambang batas kelelahan neuro-kognitif kritis. Mohon hentikan semua aktivitas berat, jauhkan perangkat komputasi, dan jangan ragu berbicara dengan bantuan profesional.
            </p>

            <div className="mt-3 flex items-center gap-2 text-xs font-black text-red-700 bg-red-100 p-2.5 rounded-xl border border-red-300">
              <span className="text-base">🚨</span>
              <span>Hotline Darurat Sejiwa: 119 ext 8 (Bebas Pulsa)</span>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom: 2 Bold Triage Buttons */}
      <div className="flex flex-col items-center gap-3 pb-4 w-full mt-4">
        <button
          onClick={() => setShowTelemedicineModal(true)}
          className="w-full max-w-xs bg-red-600 hover:bg-red-700 active:scale-95 text-white font-black py-3.5 px-4 rounded-full text-xs tracking-wide transition-all flex items-center justify-center gap-2 border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a]"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
          </svg>
          <span>Konsultasi Telemedicine Segera</span>
        </button>

        <button
          onClick={() => onNavigate('dashboard')}
          className="w-full max-w-xs bg-[#5C5C5C] hover:bg-[#4a4a4a] active:scale-95 text-white font-bold py-3.5 px-4 rounded-full text-xs tracking-wide transition-all border-2 border-slate-900 shadow-[4px_4px_0px_#0f172a]"
        >
          Protokol Istirahat Penuh
        </button>
      </div>

      {/* Telemedicine Emergency Modal */}
      {showTelemedicineModal && (
        <div className="absolute inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white border-2 border-slate-900 rounded-3xl p-5 shadow-[8px_8px_0px_#0f172a] w-full max-w-sm text-left">
            <div className="flex justify-between items-center mb-3">
              <span className="text-xs font-black uppercase text-red-600 bg-red-100 px-2 py-0.5 rounded-full">
                Darurat 24/7
              </span>
              <button
                onClick={() => setShowTelemedicineModal(false)}
                className="w-7 h-7 rounded-full bg-slate-100 flex items-center justify-center font-bold text-slate-700"
              >
                ✕
              </button>
            </div>

            <h3 className="text-base font-black text-slate-900 mb-1">Menghubungkan ke Tim Medis</h3>
            <p className="text-xs text-slate-600 mb-4">
              Layanan siaga psikolog & psikiater klinis mitra Kemenkes RI siap mendampingi Anda secara rahasia dan gratis.
            </p>

            <div className="bg-slate-50 border border-slate-200 rounded-2xl p-3 mb-4 space-y-2">
              <div className="flex items-center justify-between text-xs font-bold text-slate-800">
                <span>Dokter Jaga:</span>
                <span className="text-[#3046B4]">dr. Sarah M., Sp.KJ</span>
              </div>
              <div className="flex items-center justify-between text-xs text-slate-600">
                <span>Waktu Tunggu:</span>
                <span className="font-bold text-emerald-600">Langsung Terhubung (&lt; 1 Menit)</span>
              </div>
            </div>

            <div className="flex flex-col gap-2">
              <a
                href="tel:119"
                className="w-full bg-red-600 text-white font-bold py-3 rounded-xl text-center text-xs border border-slate-900 shadow-[3px_3px_0px_#0f172a] block"
              >
                Panggil Sekarang (119 ext 8)
              </a>
              <button
                onClick={() => {
                  alert('Sesi konsultasi live chat darurat telah diinisialisasi.');
                  setShowTelemedicineModal(false);
                }}
                className="w-full bg-slate-200 hover:bg-slate-300 text-slate-800 font-bold py-2.5 rounded-xl text-xs"
              >
                Mulai Chat Darurat On-Device
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
