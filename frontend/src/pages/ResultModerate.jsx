import React, { useState } from 'react';
import Header from '../components/Header';

export default function ResultModerate({ onNavigate }) {
  const [interventions, setInterventions] = useState({
    stretch: false,
    coffee: false,
    rest: false,
    breathing: false,
  });

  const toggleIntervention = (key) => {
    setInterventions((prev) => ({
      ...prev,
      [key]: !prev[key],
    }));
  };

  const completedCount = Object.values(interventions).filter(Boolean).length;
  const totalCount = Object.keys(interventions).length;

  return (
    <div className="flex-1 flex flex-col justify-between p-6 select-none bg-gradient-to-b from-[#F1F0EA] via-[#fffbeb] to-[#F1F0EA]">
      <div>
        <Header
          title="Hasil Skrining"
          subtitle="Kelelahan Terdeteksi"
          onNavigate={onNavigate}
        />

        <div className="flex flex-col items-center text-center mt-1 px-2">
          {/* Amber warning icon */}
          <div className="w-20 h-20 rounded-full bg-amber-100 border-4 border-amber-400 shadow-md flex items-center justify-center text-amber-600 mb-2.5">
            <svg className="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>

          <h2 className="text-lg font-black text-amber-800 tracking-tight">
            Gejala Kelelahan (Burnout Sedang) Terdeteksi
          </h2>
          <p className="text-xs text-amber-700 mt-1 font-medium leading-relaxed">
            Variabilitas gait lambat dan frekuensi prosodi suara menurun, mengindikasikan kelelahan saraf kognitif.
          </p>

          {/* Recipe Card: Exact Google Stitch Signature Neo-brutalism */}
          <div className="bg-white p-5 rounded-[24px] w-full mt-3 text-left border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a]">
            <div className="flex justify-between items-center mb-2">
              <h3 className="text-sm font-bold text-[#3046B4] flex items-center gap-1.5">
                <span>📋 Resep Anti-Zombi</span>
              </h3>
              <span className="text-[10px] bg-amber-100 text-amber-800 font-bold px-2 py-0.5 rounded-full border border-amber-300">
                {completedCount}/{totalCount} Selesai
              </span>
            </div>

            <p className="text-xs text-[#5C5C5C] mb-3 font-medium">
              Selesaikan mikro-intervensi pemulihan cepat ini untuk me-reset sistem saraf:
            </p>

            {/* Checklists */}
            <div className="flex flex-col gap-2.5">
              <label
                onClick={() => toggleIntervention('stretch')}
                className={`flex items-center gap-3 p-2.5 rounded-xl border transition cursor-pointer select-none ${
                  interventions.stretch ? 'bg-amber-50/70 border-amber-300' : 'bg-gray-50 border-gray-200 hover:bg-gray-100'
                }`}
              >
                <input
                  type="checkbox"
                  checked={interventions.stretch}
                  onChange={() => {}}
                  className="w-4 h-4 rounded text-[#3046B4] accent-[#3046B4] cursor-pointer"
                />
                <span className={`text-xs font-semibold ${
                  interventions.stretch ? 'line-through text-gray-400' : 'text-gray-800'
                }`}>
                  Peregangan Otot Leher & Bahu (3 Menit)
                </span>
              </label>

              <label
                onClick={() => toggleIntervention('coffee')}
                className={`flex items-center gap-3 p-2.5 rounded-xl border transition cursor-pointer select-none ${
                  interventions.coffee ? 'bg-amber-50/70 border-amber-300' : 'bg-gray-50 border-gray-200 hover:bg-gray-100'
                }`}
              >
                <input
                  type="checkbox"
                  checked={interventions.coffee}
                  onChange={() => {}}
                  className="w-4 h-4 rounded text-[#3046B4] accent-[#3046B4] cursor-pointer"
                />
                <span className={`text-xs font-semibold ${
                  interventions.coffee ? 'line-through text-gray-400' : 'text-gray-800'
                }`}>
                  Seduh Kopi/Teh Hangat atau Air Lemon
                </span>
              </label>

              <label
                onClick={() => toggleIntervention('rest')}
                className={`flex items-center gap-3 p-2.5 rounded-xl border transition cursor-pointer select-none ${
                  interventions.rest ? 'bg-amber-50/70 border-amber-300' : 'bg-gray-50 border-gray-200 hover:bg-gray-100'
                }`}
              >
                <input
                  type="checkbox"
                  checked={interventions.rest}
                  onChange={() => {}}
                  className="w-4 h-4 rounded text-[#3046B4] accent-[#3046B4] cursor-pointer"
                />
                <span className={`text-xs font-semibold ${
                  interventions.rest ? 'line-through text-gray-400' : 'text-gray-800'
                }`}>
                  Istirahat Taktil (Jauhkan Layar HP/Laptop 10 Menit)
                </span>
              </label>

              <label
                onClick={() => toggleIntervention('breathing')}
                className={`flex items-center gap-3 p-2.5 rounded-xl border transition cursor-pointer select-none ${
                  interventions.breathing ? 'bg-amber-50/70 border-amber-300' : 'bg-gray-50 border-gray-200 hover:bg-gray-100'
                }`}
              >
                <input
                  type="checkbox"
                  checked={interventions.breathing}
                  onChange={() => {}}
                  className="w-4 h-4 rounded text-[#3046B4] accent-[#3046B4] cursor-pointer"
                />
                <span className={`text-xs font-semibold ${
                  interventions.breathing ? 'line-through text-gray-400' : 'text-gray-800'
                }`}>
                  Teknik Napas 4-7-8 untuk Meredakan Kortisol
                </span>
              </label>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Button: Selesaikan Resep -> onNavigate('dashboard') */}
      <div className="flex flex-col items-center pb-4 mt-3">
        <button
          onClick={() => onNavigate('dashboard')}
          className="w-3/4 max-w-xs bg-[#FFC436] hover:bg-[#f0b52b] active:scale-95 text-[#3046B4] font-black py-3.5 rounded-full text-sm transition-all flex items-center justify-center gap-2 border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a]"
        >
          <span>Selesaikan Resep</span>
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7" />
          </svg>
        </button>
      </div>
    </div>
  );
}
