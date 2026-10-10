import React, { useRef, useState, useEffect } from 'react';
import Header from '../components/Header';

export default function Stage1Mental({ onNavigate }) {
  const canvasRef = useRef(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const [tool, setTool] = useState('pen'); // 'pen' | 'eraser'
  const [strokeCount, setStrokeCount] = useState(0);
  const [isRecording, setIsRecording] = useState(false);
  const [recordSeconds, setRecordSeconds] = useState(0);

  // Setup canvas
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.lineWidth = 3;
    ctx.strokeStyle = '#FFFFFF';
  }, []);

  // Voice recording timer simulation
  useEffect(() => {
    let interval = null;
    if (isRecording) {
      interval = setInterval(() => {
        setRecordSeconds((prev) => {
          if (prev >= 30) {
            setIsRecording(false);
            return 30;
          }
          return prev + 1;
        });
      }, 1000);
    } else {
      clearInterval(interval);
    }
    return () => clearInterval(interval);
  }, [isRecording]);

  const startDrawing = (e) => {
    setIsDrawing(true);
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX || e.touches?.[0]?.clientX) - rect.left;
    const y = (e.clientY || e.touches?.[0]?.clientY) - rect.top;

    ctx.beginPath();
    ctx.moveTo(x, y);

    if (tool === 'eraser') {
      ctx.strokeStyle = '#3046B4';
      ctx.lineWidth = 14;
    } else {
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 3.5;
    }
    setStrokeCount((c) => c + 1);
  };

  const draw = (e) => {
    if (!isDrawing) return;
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX || e.touches?.[0]?.clientX) - rect.left;
    const y = (e.clientY || e.touches?.[0]?.clientY) - rect.top;

    ctx.lineTo(x, y);
    ctx.stroke();
  };

  const stopDrawing = () => {
    setIsDrawing(false);
  };

  const clearCanvas = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    setStrokeCount(0);
  };

  const toggleRecording = () => {
    if (isRecording) {
      setIsRecording(false);
    } else {
      setIsRecording(true);
      setRecordSeconds(0);
    }
  };

  return (
    <div className="flex-1 flex flex-col justify-between p-4 select-none bg-[#F1F0EA] relative">
      <div>
        <Header
          title="1st stage"
          subtitle="Draw & Talk"
          onBack={() => onNavigate('dashboard')}
          onNavigate={onNavigate}
        />

        <div className="px-6 flex justify-between items-center text-xs text-[#3046B4] font-bold mb-1">
          <span>Draw (Kanvas Ekspresi)</span>
          <span className="text-[10px] text-slate-500 font-medium">
            {strokeCount > 0 ? `${strokeCount} goresan terdeteksi` : 'Coretkan suasana hatimu'}
          </span>
        </div>

        {/* Middle: The EXACT Google Stitch Offset Canvas Structure (Blue bg) */}
        <div className="relative w-64 h-64 mx-auto mt-1 mb-5">
          {/* Border outline (shadow) */}
          <div className="absolute inset-0 border-[3px] border-[#3046B4] rounded-[32px] translate-x-3 translate-y-3"></div>

          {/* Main colored canvas with actual interactive drawing area */}
          <div className="absolute inset-0 bg-[#3046B4] rounded-[32px] p-3.5 flex flex-col justify-between z-10 overflow-hidden shadow-sm text-white border-2 border-slate-900">
            {/* Top-left Pen, Eraser, and Clear icons */}
            <div className="flex items-center justify-between text-white z-20">
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => setTool('pen')}
                  className={`p-1.5 rounded-lg transition active:scale-90 ${
                    tool === 'pen' ? 'bg-white text-[#3046B4] shadow-sm font-bold' : 'bg-white/20 hover:bg-white/30 text-white'
                  }`}
                  title="Pen Tool"
                >
                  <svg className="w-4 h-4 stroke-[2]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                  </svg>
                </button>

                <button
                  type="button"
                  onClick={() => setTool('eraser')}
                  className={`p-1.5 rounded-lg transition active:scale-90 ${
                    tool === 'eraser' ? 'bg-white text-[#3046B4] shadow-sm font-bold' : 'bg-white/20 hover:bg-white/30 text-white'
                  }`}
                  title="Eraser Tool"
                >
                  <svg className="w-4 h-4 stroke-[2]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>

                <button
                  type="button"
                  onClick={clearCanvas}
                  className="p-1.5 bg-white/20 hover:bg-white/30 rounded-lg text-white text-[10px] font-semibold transition active:scale-90"
                  title="Hapus Bersih"
                >
                  Reset
                </button>
              </div>

              <span className="text-[10px] bg-white/20 px-2 py-0.5 rounded-full font-medium">
                {tool === 'pen' ? 'Mode Pena' : 'Mode Penghapus'}
              </span>
            </div>

            {/* Interactive HTML5 Canvas Playground */}
            <div className="relative flex-1 my-1 w-full flex items-center justify-center">
              <canvas
                ref={canvasRef}
                width={230}
                height={160}
                onMouseDown={startDrawing}
                onMouseMove={draw}
                onMouseUp={stopDrawing}
                onMouseLeave={stopDrawing}
                onTouchStart={startDrawing}
                onTouchMove={draw}
                onTouchEnd={stopDrawing}
                className="w-full h-full bg-transparent rounded-2xl cursor-crosshair touch-none"
              />

              {strokeCount === 0 && (
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none opacity-40">
                  <svg className="w-16 h-16 stroke-white fill-none stroke-[1.5]" viewBox="0 0 100 100">
                    <path d="M20 70 Q 40 20 60 50 T 90 30" strokeLinecap="round" />
                    <circle cx="50" cy="50" r="15" strokeDasharray="4 2" />
                  </svg>
                  <span className="text-[10px] text-white/90 font-medium">Coret bebas di sini</span>
                </div>
              )}
            </div>

            <div className="flex justify-between items-center text-[10px] text-white/70">
              <span>Kecepatan & Tekanan Otomatis Direkam</span>
              <span className="font-semibold text-[#FFC436]">Biomarker Aktif</span>
            </div>
          </div>
        </div>

        {/* Bottom "Talk" Section */}
        <div className="flex flex-col items-center justify-center my-2">
          <span className="text-xs text-[#3046B4] font-bold mb-1">Talk (Suara Curhat)</span>

          {/* Interactive Mic Button */}
          <button
            type="button"
            onClick={toggleRecording}
            className={`w-16 h-16 rounded-full border-2 transition-all flex items-center justify-center relative cursor-pointer active:scale-95 ${
              isRecording
                ? 'border-red-500 bg-red-50 text-red-600 shadow-[0_0_15px_rgba(239,68,68,0.5)]'
                : 'border-[#3046B4] text-[#3046B4] bg-transparent hover:bg-[#3046B4]/5 shadow-sm'
            }`}
            title="Klik untuk merekam suara"
          >
            {isRecording && (
              <span className="absolute inset-0 rounded-full border-2 border-red-400 animate-ping opacity-75"></span>
            )}
            <svg className="w-8 h-8 stroke-[1.5]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
            </svg>
          </button>

          {isRecording ? (
            <div className="flex items-center gap-2 mt-2">
              <span className="w-2 h-2 rounded-full bg-red-500 animate-ping"></span>
              <span className="text-xs font-bold text-red-600">
                Merekam Suara: {recordSeconds}s / 30s
              </span>
            </div>
          ) : (
            <span className="text-[11px] text-[#3046B4]/70 mt-1.5 font-medium">
              Tekan & ceritakan harimu (30s)
            </span>
          )}
        </div>
      </div>

      {/* Button: Selesai Corat-coret -> onNavigate('stage2') */}
      <div className="flex flex-col items-center pb-4">
        <button
          onClick={() => onNavigate('stage2')}
          className="w-3/4 max-w-xs bg-[#3046B4] hover:bg-[#273a96] active:scale-95 text-white font-bold py-3.5 rounded-full text-sm transition-all flex items-center justify-center gap-2 border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a]"
        >
          <span>Selesai Corat-coret</span>
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </div>
    </div>
  );
}
