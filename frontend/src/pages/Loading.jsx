import React, { useState, useEffect } from 'react';

export default function Loading({ onNavigate }) {
  const [activeStep, setActiveStep] = useState(0);

  const steps = [
    { title: 'Analisis Motorik Halus', detail: 'Ekstraksi tekanan & kelenturan goresan mental...' },
    { title: 'Fusi Akselerometer Gait', detail: 'Sinkronisasi ritme & kestabilan langkah kaki...' },
    { title: 'Prosodi Vokal & Frekuensi', detail: 'Evaluasi jeda bicara & tonus emosional audio...' },
    { title: 'Sklera & Kedipan Mata', detail: 'Pengukuran rasio kelelahan pupil dan sklera...' },
  ];

  useEffect(() => {
    const timer = setInterval(() => {
      setActiveStep((prev) => (prev < steps.length - 1 ? prev + 1 : prev));
    }, 900);
    return () => clearInterval(timer);
  }, [steps.length]);

  return (
    <div className="flex-1 flex flex-col justify-between p-6 select-none bg-[#F1F0EA]">
      <div className="h-6"></div>

      {/* Center Loading & Wave / Spinner */}
      <div className="flex flex-col items-center justify-center text-center px-2 my-auto">
        {/* Animated circular wave ring from Stitch */}
        <div className="relative w-28 h-28 flex items-center justify-center mb-5">
          <div className="absolute inset-0 rounded-full border-4 border-[#3046B4]/30 animate-ping"></div>
          <div className="w-20 h-20 rounded-full bg-[#3046B4] flex items-center justify-center text-white shadow-xl animate-pulse-ring border-2 border-slate-900 shadow-[4px_4px_0px_#0f172a]">
            <svg className="w-10 h-10 animate-spin text-[#FFC436]" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
        </div>

        {/* Bouncing Wave Dots */}
        <div className="flex items-center gap-2 mb-3">
          <div className="w-3 h-3 rounded-full bg-[#3046B4] wave-dot-1"></div>
          <div className="w-3 h-3 rounded-full bg-[#FFC436] wave-dot-2"></div>
          <div className="w-3 h-3 rounded-full bg-[#3046B4] wave-dot-3"></div>
        </div>

        <h3 className="text-base font-bold text-[#3046B4]">Agentic AI sedang memproses...</h3>
        <p className="text-xs text-[#5C5C5C] max-w-xs mt-1 leading-relaxed font-medium">
          Mengintegrasikan coretan mental, gait sensor, prosodi suara, dan biomarker sklera mata...
        </p>

        {/* Dynamic Multimodal Step Checklist Card */}
        <div className="w-full max-w-xs bg-white rounded-2xl p-3.5 border-2 border-slate-900 shadow-[4px_4px_0px_#0f172a] mt-5 text-left flex flex-col gap-2">
          {steps.map((step, idx) => (
            <div key={idx} className="flex items-center gap-2.5">
              <div className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold ${
                idx <= activeStep
                  ? 'bg-emerald-500 text-white'
                  : 'bg-slate-200 text-slate-500'
              }`}>
                {idx <= activeStep ? '✓' : idx + 1}
              </div>
              <div className="flex flex-col">
                <span className={`text-[11px] font-bold leading-tight ${
                  idx <= activeStep ? 'text-slate-900' : 'text-slate-400'
                }`}>
                  {step.title}
                </span>
                <span className="text-[9px] text-[#5C5C5C]">{step.detail}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Prototype Simulation Buttons: Choose Result Branch (WAJIB 3 TOMBOL RAHASIA) */}
      <div className="bg-white/90 backdrop-blur rounded-[24px] p-4 border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a] flex flex-col gap-2 mb-2">
        <div className="flex items-center justify-between">
          <span className="text-[10px] font-bold tracking-wider text-[#3046B4] uppercase">
            ⚡ Tombol Testing AI (Pilih Cabang Hasil):
          </span>
          <span className="text-[9px] bg-amber-100 text-amber-800 px-2 py-0.5 rounded-full font-bold">
            Simulasi Cepat
          </span>
        </div>

        <div className="grid grid-cols-3 gap-2 mt-1">
          <button
            onClick={() => onNavigate('result_healthy')}
            className="bg-emerald-500 hover:bg-emerald-600 active:scale-95 text-white text-xs font-bold py-2.5 px-2 rounded-xl shadow transition text-center border border-slate-900 shadow-[2px_2px_0px_#0f172a]"
          >
            Simulate Sehat
          </button>
          <button
            onClick={() => onNavigate('result_moderate')}
            className="bg-amber-500 hover:bg-amber-600 active:scale-95 text-white text-xs font-bold py-2.5 px-2 rounded-xl shadow transition text-center border border-slate-900 shadow-[2px_2px_0px_#0f172a]"
          >
            Simulate Sedang
          </button>
          <button
            onClick={() => onNavigate('result_extreme')}
            className="bg-red-500 hover:bg-red-600 active:scale-95 text-white text-xs font-bold py-2.5 px-2 rounded-xl shadow transition text-center border border-slate-900 shadow-[2px_2px_0px_#0f172a]"
          >
            Simulate Ekstrem
          </button>
        </div>
      </div>
    </div>
  );
}
