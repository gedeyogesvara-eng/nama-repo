import React, { useState, useEffect } from 'react';
import Header from '../components/Header';

export default function Stage2Physical({ onNavigate }) {
  const [walkingSeconds, setWalkingSeconds] = useState(0);
  const [isRunning, setIsRunning] = useState(false);
  const [stepsCount, setStepsCount] = useState(0);

  useEffect(() => {
    let interval = null;
    if (isRunning) {
      interval = setInterval(() => {
        setWalkingSeconds((prev) => {
          if (prev >= 10) {
            setIsRunning(false);
            return 10;
          }
          const next = prev + 1;
          setStepsCount(Math.floor(next * 1.2));
          return next;
        });
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isRunning]);

  const startWalkingSimulation = () => {
    setWalkingSeconds(0);
    setStepsCount(0);
    setIsRunning(true);
  };

  const isComplete = walkingSeconds >= 10;
  const progressPercent = Math.min(100, (walkingSeconds / 10) * 100);
  const strokeDashoffset = 440 - (440 * progressPercent) / 100;

  return (
    <div className="flex-1 flex flex-col justify-between p-6 select-none bg-[#F1F0EA]">
      <div>
        <Header
          title="Tahap 2"
          subtitle="Gait Tracker"
          onBack={() => onNavigate('stage1')}
          onNavigate={onNavigate}
        />

        <div className="text-center px-4 mt-1">
          <h2 className="text-lg font-bold text-[#3046B4]">Tahap 2: Gait Tracker</h2>
          <p className="text-xs text-[#5C5C5C] mt-1 font-medium">
            Taruh HP di saku dan berjalanlah selama 10 langkah (10 detik)
          </p>
        </div>

        {/* Middle: Large circular progress ring with Neo-brutalist accent */}
        <div className="relative w-56 h-56 mx-auto my-7 flex items-center justify-center">
          <svg className="w-full h-full transform -rotate-90 drop-shadow-sm" viewBox="0 0 160 160">
            {/* Background track */}
            <circle cx="80" cy="80" r="70" stroke="#e0ded6" strokeWidth="12" fill="none" />
            {/* Dynamic progress circle */}
            <circle
              cx="80"
              cy="80"
              r="70"
              stroke={isComplete ? '#10B981' : '#3046B4'}
              strokeWidth="12"
              strokeDasharray="440"
              strokeDashoffset={strokeDashoffset}
              strokeLinecap="round"
              fill="none"
              className="transition-all duration-500 ease-out"
            />
          </svg>

          {/* Center Inside Circle Content */}
          <div className="absolute inset-0 flex flex-col items-center justify-center text-center p-4">
            {isComplete ? (
              <div className="flex flex-col items-center animate-fade-in">
                <div className="w-14 h-14 bg-[#10B981]/15 text-[#10B981] rounded-full flex items-center justify-center mb-1 border-2 border-[#10B981]">
                  <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <span className="text-xs font-bold text-[#10B981]">10s Lengkap!</span>
                <span className="text-[10px] text-[#5C5C5C] font-semibold">{stepsCount || 12} Langkah Tercatat</span>
              </div>
            ) : (
              <>
                <span className="text-3xl font-extrabold text-[#3046B4] tracking-tight">
                  {walkingSeconds}s
                </span>
                <span className="text-xs font-semibold text-[#5C5C5C]">dari 10 detik</span>
                {isRunning ? (
                  <div className="flex items-center gap-1.5 mt-2 bg-[#3046B4]/10 px-2 py-0.5 rounded-full">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#3046B4] animate-ping"></span>
                    <span className="text-[10px] text-[#3046B4] font-bold">
                      {stepsCount} langkah terdeteksi...
                    </span>
                  </div>
                ) : (
                  <span className="text-[10px] text-slate-400 mt-1">Siap berjalan</span>
                )}
              </>
            )}
          </div>
        </div>

        {/* Sensor instructions note */}
        <div className="bg-white/80 rounded-2xl p-3.5 border-2 border-slate-900 shadow-[4px_4px_0px_#0f172a] max-w-xs mx-auto text-center">
          <div className="flex items-center justify-center gap-2 text-xs font-bold text-[#3046B4] mb-0.5">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
            <span>Sensor IMU 6-Axis Aktif</span>
          </div>
          <p className="text-[11px] text-[#5C5C5C] font-medium leading-relaxed">
            Membaca variasi ritme langkah, deviasi postural, dan kelelahan neuromuskular secara real-time.
          </p>
        </div>
      </div>

      {/* Bottom Action Buttons */}
      <div className="flex flex-col items-center pb-4 gap-3">
        {isComplete ? (
          <>
            <button
              onClick={() => onNavigate('stage3')}
              className="w-3/4 max-w-xs bg-[#10B981] hover:bg-[#059669] active:scale-95 text-white font-bold py-3.5 rounded-full text-sm transition-all flex items-center justify-center gap-2 border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a]"
            >
              <span>Lanjut Scan Mata</span>
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7" />
              </svg>
            </button>
            <button
              onClick={startWalkingSimulation}
              className="text-xs text-slate-600 hover:text-slate-900 underline font-medium"
            >
              Ulangi Tes Berjalan
            </button>
          </>
        ) : (
          <button
            onClick={startWalkingSimulation}
            disabled={isRunning}
            className={`w-3/4 max-w-xs ${
              isRunning ? 'bg-gray-400 cursor-not-allowed opacity-80' : 'bg-[#3046B4] hover:bg-[#273a96]'
            } active:scale-95 text-white font-bold py-3.5 rounded-full text-sm transition-all flex items-center justify-center gap-2 border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a]`}
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
            </svg>
            <span>{isRunning ? 'Sedang Berjalan (10s)...' : 'Mulai Berjalan (10 Detik)'}</span>
          </button>
        )}
      </div>
    </div>
  );
}
