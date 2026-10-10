import React, { useState } from 'react';
import Header from '../components/Header';

export default function Stage3Visual({ onNavigate }) {
  const [captureSuccess, setCaptureSuccess] = useState(false);
  const [blinkCount, setBlinkCount] = useState(3);

  const simulateAutoCapture = () => {
    setCaptureSuccess(true);
    setBlinkCount(5);
    setTimeout(() => {
      onNavigate('loading');
    }, 1200);
  };

  return (
    <div className="flex-1 flex flex-col justify-between p-6 select-none bg-[#F1F0EA]">
      <div>
        <Header
          title="Tahap 3"
          subtitle="Visual & Sclera Scan"
          onBack={() => onNavigate('stage2')}
          onNavigate={onNavigate}
        />

        <div className="text-center px-4">
          <h2 className="text-lg font-bold text-[#3046B4]">Pindai Visual & Mata</h2>
          <p className="text-xs text-[#5C5C5C] font-medium">
            Arahkan kamera ke wajah dan tatap titik tengah
          </p>
        </div>

        {/* Middle: Front-facing Camera simulation container */}
        <div className="w-full h-88 bg-gray-900 rounded-3xl relative mt-4 shadow-2xl overflow-hidden flex flex-col items-center justify-center border-4 border-gray-800">
          {/* Subtle camera background gradient overlay */}
          <div className="absolute inset-0 bg-gradient-to-b from-black/50 via-transparent to-black/70 pointer-events-none"></div>

          {/* Camera Top Status Indicator */}
          <div className="absolute top-4 flex items-center gap-2 bg-black/70 backdrop-blur-md px-3.5 py-1.5 rounded-full text-white text-[10px] border border-white/10 z-20">
            <span className={`w-2 h-2 rounded-full ${captureSuccess ? 'bg-green-400' : 'bg-red-500 animate-pulse'}`}></span>
            <span className="font-semibold tracking-wide">
              {captureSuccess ? 'Biomarker Sklera Terkunci' : 'Live Eye-Tracking (Mencari Fokus)'}
            </span>
          </div>

          {/* Dashed Oval Shape in the Center */}
          <div
            className={`w-52 h-64 rounded-[50%] border-4 border-dashed transition-all duration-300 flex flex-col items-center justify-center relative z-10 ${
              captureSuccess
                ? 'border-[#10B981] bg-green-500/15 scale-105'
                : 'border-[#EF4444] bg-transparent'
            }`}
          >
            {/* Center crosshair / guide */}
            <div className={`w-6 h-6 border-t-2 border-b-2 ${captureSuccess ? 'border-green-400' : 'border-red-400'} opacity-75`}></div>
            <div className={`w-6 h-6 border-l-2 border-r-2 ${captureSuccess ? 'border-green-400' : 'border-red-400'} absolute opacity-75`}></div>

            {/* Guide Text */}
            <span className={`text-xs font-bold px-3 py-1 rounded-md mt-4 backdrop-blur-sm transition-all ${
              captureSuccess
                ? 'bg-emerald-600/90 text-white shadow-lg'
                : 'bg-black/60 text-white/90'
            }`}>
              {captureSuccess ? '✓ Wajah & Sklera Pas' : 'Posisikan Wajah di Oval'}
            </span>
          </div>

          {/* Camera grid lines 3x3 */}
          <div className="absolute inset-0 grid grid-cols-3 grid-rows-3 pointer-events-none opacity-20">
            <div className="border-r border-b border-white"></div>
            <div className="border-r border-b border-white"></div>
            <div className="border-b border-white"></div>
            <div className="border-r border-b border-white"></div>
            <div className="border-r border-b border-white"></div>
            <div className="border-b border-white"></div>
          </div>

          {/* Bottom Live Metrics Over Camera */}
          <div className="absolute bottom-3 flex items-center justify-between w-full px-5 text-[10px] text-white/80 z-20">
            <span>Kedipan Sklera: {blinkCount}/menit</span>
            <span className="text-[#FFC436] font-bold">FPS: 60.0</span>
          </div>
        </div>
      </div>

      {/* Bottom Button: Simulate Auto-Capture */}
      <div className="flex flex-col items-center pb-2 mt-4">
        <button
          onClick={simulateAutoCapture}
          className="w-3/4 max-w-xs bg-[#3046B4] hover:bg-[#273a96] active:scale-95 text-white font-bold py-3.5 rounded-full text-sm transition-all flex items-center justify-center gap-2 border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a]"
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <span>Simulate Auto-Capture</span>
        </button>
        <span className="text-[10px] text-[#5C5C5C] mt-2 font-medium">
          Oval berubah hijau lalu otomatis lanjut ke proses AI
        </span>
      </div>
    </div>
  );
}
