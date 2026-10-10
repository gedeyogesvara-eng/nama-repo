import React, { useState } from 'react';

// Import all 10 Screen Pages
import Splash from './pages/Splash';
import Auth from './pages/Auth';
import Permission from './pages/Permission';
import Dashboard from './pages/Dashboard';
import Stage1Mental from './pages/Stage1Mental';
import Stage2Physical from './pages/Stage2Physical';
import Stage3Visual from './pages/Stage3Visual';
import Loading from './pages/Loading';
import ResultHealthy from './pages/ResultHealthy';
import ResultModerate from './pages/ResultModerate';
import ResultExtreme from './pages/ResultExtreme';

const SCREENS = [
  { id: 'splash', name: '1. Splash Screen' },
  { id: 'auth', name: '2. Login / Register' },
  { id: 'permission', name: '3. Izin Sensor' },
  { id: 'dashboard', name: '4. Dashboard Utama' },
  { id: 'stage1', name: '5. Stage 1: Draw & Talk' },
  { id: 'stage2', name: '6. Stage 2: Gait Tracker' },
  { id: 'stage3', name: '7. Stage 3: Scan Mata' },
  { id: 'loading', name: '8. Loading AI' },
  { id: 'result_healthy', name: '9. Hasil: Prima (100%)' },
  { id: 'result_moderate', name: '10. Hasil: Kelelahan/Sedang' },
  { id: 'result_extreme', name: '11. Hasil: Mode Zombi Akut' },
];

export default function App() {
  const [currentScreen, setCurrentScreen] = useState('splash');

  const renderScreen = () => {
    switch (currentScreen) {
      case 'splash':
        return <Splash onNavigate={setCurrentScreen} />;
      case 'auth':
        return <Auth onNavigate={setCurrentScreen} />;
      case 'permission':
        return <Permission onNavigate={setCurrentScreen} />;
      case 'dashboard':
        return <Dashboard onNavigate={setCurrentScreen} />;
      case 'stage1':
        return <Stage1Mental onNavigate={setCurrentScreen} />;
      case 'stage2':
        return <Stage2Physical onNavigate={setCurrentScreen} />;
      case 'stage3':
        return <Stage3Visual onNavigate={setCurrentScreen} />;
      case 'loading':
        return <Loading onNavigate={setCurrentScreen} />;
      case 'result_healthy':
        return <ResultHealthy onNavigate={setCurrentScreen} />;
      case 'result_moderate':
        return <ResultModerate onNavigate={setCurrentScreen} />;
      case 'result_extreme':
        return <ResultExtreme onNavigate={setCurrentScreen} />;
      default:
        return <Dashboard onNavigate={setCurrentScreen} />;
    }
  };

  return (
    <div className="w-screen min-h-screen bg-[#e5e4de] flex items-center justify-center p-0 md:p-4 font-sans text-slate-900">
      {/* Floating Screen Selector / Debug Jump Menu from Google Stitch Prototype */}
      <aside className="fixed top-4 left-4 z-50 bg-white/95 backdrop-blur shadow-2xl rounded-2xl p-3 hidden xl:flex flex-col gap-1.5 text-xs border-2 border-slate-900 shadow-[6px_6px_0px_#0f172a] max-h-[92vh] overflow-y-auto">
        <div className="font-extrabold text-[#3046B4] px-2 py-1 text-[11px] uppercase tracking-wider flex items-center justify-between border-b pb-2">
          <span>Navigator Cepat (10 Layar)</span>
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
        </div>
        <div className="flex flex-col gap-1 w-64 pt-1">
          {SCREENS.map((screen) => {
            const isActive = currentScreen === screen.id;
            return (
              <button
                key={screen.id}
                onClick={() => setCurrentScreen(screen.id)}
                className={`p-2 text-[11px] rounded-xl text-left transition font-semibold flex items-center justify-between ${
                  isActive
                    ? 'bg-[#3046B4] text-white shadow-sm'
                    : 'hover:bg-slate-100 text-slate-700'
                }`}
              >
                <span>{screen.name}</span>
                {isActive && <span className="text-xs">👉</span>}
              </button>
            );
          })}
        </div>
        <div className="text-[10px] text-slate-500 pt-2 border-t mt-1 px-1">
          💡 Klik layar manapun untuk berpindah secara instan saat evaluasi.
        </div>
      </aside>

      {/* Mobile Phone Frame Wrapper */}
      <main
        id="appContainer"
        className="w-full max-w-md mx-auto h-[100dvh] bg-[#F1F0EA] relative overflow-hidden shadow-2xl flex flex-col justify-between select-none md:rounded-[40px] md:h-[844px] md:border-[10px] md:border-slate-900 md:shadow-[14px_14px_0px_#0f172a]"
      >
        {/* Screen dynamic container */}
        <div
          id="screenRoot"
          className="flex-1 flex flex-col h-full overflow-y-auto no-scrollbar relative"
        >
          {renderScreen()}
        </div>
      </main>
    </div>
  );
}
