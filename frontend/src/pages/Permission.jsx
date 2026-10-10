import React, { useState } from 'react';
import Header from '../components/Header';

export default function Permission({ onNavigate }) {
  const [permissions, setPermissions] = useState({
    camera: false,
    microphone: false,
    motion: false,
  });

  const [showAlert, setShowAlert] = useState(false);

  const togglePermission = (key) => {
    setPermissions((prev) => ({
      ...prev,
      [key]: !prev[key],
    }));
    setShowAlert(false);
  };

  const allGranted = permissions.camera && permissions.microphone && permissions.motion;

  const handleAllowAll = () => {
    setPermissions({
      camera: true,
      microphone: true,
      motion: true,
    });
    setShowAlert(false);
    setTimeout(() => {
      onNavigate('dashboard');
    }, 300);
  };

  const handleProceed = () => {
    if (!allGranted) {
      setShowAlert(true);
      return;
    }
    onNavigate('dashboard');
  };

  return (
    <div className="flex-1 flex flex-col justify-between p-6 select-none bg-[#F1F0EA]">
      <div>
        <Header
          title="Izin Sensor Dibutuhkan"
          subtitle="Multimodal Behavioral Skrining"
          onBack={() => onNavigate('auth')}
          onNavigate={onNavigate}
        />

        <div className="px-2 mt-2">
          <p className="text-xs text-[#3046B4]/80 leading-relaxed font-medium">
            Untuk mendeteksi biomarker depresi dan fatigue secara akurat, sistem AI membutuhkan akses sensor temporal perangkat Anda:
          </p>

          {showAlert && (
            <div className="mt-4 p-3 bg-red-100 border-2 border-red-500 rounded-2xl shadow-[4px_4px_0px_#ef4444] text-red-800 text-xs flex items-start gap-2.5 animate-bounce">
              <svg className="w-5 h-5 text-red-600 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
              <div>
                <span className="font-bold block">Izin Belum Lengkap!</span>
                <span>Wajib mengaktifkan ketiga sensor (Kamera, Mikrofon, dan Akselerometer) untuk melakukan analisis multimodal komprehensif.</span>
              </div>
            </div>
          )}

          {/* Sensor List Cards with Interactive Toggles */}
          <div className="flex flex-col gap-3.5 mt-5">
            {/* Camera */}
            <div
              onClick={() => togglePermission('camera')}
              className={`rounded-[24px] p-4 border transition-all cursor-pointer flex items-center gap-4 ${
                permissions.camera
                  ? 'bg-white border-[#3046B4] shadow-[4px_4px_0px_#3046B4]'
                  : 'bg-white/80 border-slate-300 shadow-sm opacity-90'
              }`}
            >
              <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 transition-colors ${
                permissions.camera ? 'bg-[#3046B4] text-white' : 'bg-[#3046B4]/10 text-[#3046B4]'
              }`}>
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </div>
              <div className="flex-1">
                <div className="flex items-center justify-between">
                  <h3 className="text-sm font-bold text-[#3046B4]">Kamera Depan</h3>
                  <div className={`w-11 h-6 flex items-center rounded-full p-1 cursor-pointer transition-colors ${
                    permissions.camera ? 'bg-[#3046B4] justify-end' : 'bg-slate-300 justify-start'
                  }`}>
                    <div className="bg-white w-4 h-4 rounded-full shadow-md transform transition-transform"></div>
                  </div>
                </div>
                <p className="text-[11px] text-[#5C5C5C] leading-snug mt-1">
                  Analisis kedipan sklera mata, mikropupil & mikroekspresi wajah.
                </p>
              </div>
            </div>

            {/* Microphone */}
            <div
              onClick={() => togglePermission('microphone')}
              className={`rounded-[24px] p-4 border transition-all cursor-pointer flex items-center gap-4 ${
                permissions.microphone
                  ? 'bg-white border-[#3046B4] shadow-[4px_4px_0px_#3046B4]'
                  : 'bg-white/80 border-slate-300 shadow-sm opacity-90'
              }`}
            >
              <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 transition-colors ${
                permissions.microphone ? 'bg-[#3046B4] text-white' : 'bg-[#3046B4]/10 text-[#3046B4]'
              }`}>
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                </svg>
              </div>
              <div className="flex-1">
                <div className="flex items-center justify-between">
                  <h3 className="text-sm font-bold text-[#3046B4]">Mikrofon Audio</h3>
                  <div className={`w-11 h-6 flex items-center rounded-full p-1 cursor-pointer transition-colors ${
                    permissions.microphone ? 'bg-[#3046B4] justify-end' : 'bg-slate-300 justify-start'
                  }`}>
                    <div className="bg-white w-4 h-4 rounded-full shadow-md transform transition-transform"></div>
                  </div>
                </div>
                <p className="text-[11px] text-[#5C5C5C] leading-snug mt-1">
                  Pola intonasi bicara, jeda prosodi, dan resonansi vokal.
                </p>
              </div>
            </div>

            {/* Accelerometer / Gait */}
            <div
              onClick={() => togglePermission('motion')}
              className={`rounded-[24px] p-4 border transition-all cursor-pointer flex items-center gap-4 ${
                permissions.motion
                  ? 'bg-white border-[#3046B4] shadow-[4px_4px_0px_#3046B4]'
                  : 'bg-white/80 border-slate-300 shadow-sm opacity-90'
              }`}
            >
              <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 transition-colors ${
                permissions.motion ? 'bg-[#3046B4] text-white' : 'bg-[#3046B4]/10 text-[#3046B4]'
              }`}>
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <div className="flex-1">
                <div className="flex items-center justify-between">
                  <h3 className="text-sm font-bold text-[#3046B4]">Akselerometer & Gait Sensor</h3>
                  <div className={`w-11 h-6 flex items-center rounded-full p-1 cursor-pointer transition-colors ${
                    permissions.motion ? 'bg-[#3046B4] justify-end' : 'bg-slate-300 justify-start'
                  }`}>
                    <div className="bg-white w-4 h-4 rounded-full shadow-md transform transition-transform"></div>
                  </div>
                </div>
                <p className="text-[11px] text-[#5C5C5C] leading-snug mt-1">
                  Metrik gaya berjalan, kelambanan langkah & tremor motorik halus.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Action Buttons */}
      <div className="p-4 flex flex-col items-center gap-3">
        {allGranted ? (
          <button
            onClick={handleProceed}
            className="w-full max-w-xs bg-[#10B981] hover:bg-[#059669] active:scale-95 text-white font-bold py-3.5 px-8 rounded-full shadow-lg transition-all text-sm flex items-center justify-center gap-2 border-2 border-slate-900 shadow-[4px_4px_0px_#0f172a]"
          >
            <span>Lanjut ke Dashboard</span>
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
            </svg>
          </button>
        ) : (
          <button
            onClick={handleAllowAll}
            className="w-full max-w-xs bg-[#3046B4] hover:bg-[#273a96] active:scale-95 text-white font-bold py-3.5 px-8 rounded-full shadow-lg transition-all text-sm flex items-center justify-center gap-2 border-2 border-slate-900 shadow-[4px_4px_0px_#0f172a]"
          >
            <span>Izinkan Semua Sensor</span>
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7" />
            </svg>
          </button>
        )}

        <button
          onClick={handleProceed}
          className="text-xs font-semibold text-[#3046B4] underline hover:opacity-80 py-1"
        >
          Verifikasi & Lanjutkan
        </button>

        <span className="text-[10px] text-[#3046B4]/60 text-center">
          Data sensor diproses secara on-device terenkripsi
        </span>
      </div>
    </div>
  );
}
