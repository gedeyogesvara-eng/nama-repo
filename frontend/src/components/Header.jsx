import React from 'react';

export default function Header({ title, subtitle, onBack, onNavigate, showNotification = true }) {
  if (title) {
    return (
      <header className="flex justify-between items-center p-6 w-full shrink-0 select-none">
        <div className="flex items-center gap-3">
          {onBack ? (
            <button
              onClick={onBack}
              className="p-1 -ml-1 text-[#3046B4] hover:bg-[#3046B4]/10 rounded-full transition active:scale-95"
              title="Kembali"
            >
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" strokeWidth="2.5" d="M15 19l-7-7 7-7" />
              </svg>
            </button>
          ) : (
            <div className="w-4 h-4 rounded-full bg-[#3046B4] shadow-sm"></div>
          )}
          <div className="flex flex-col">
            <span className="text-base font-bold text-[#3046B4] leading-tight">{title}</span>
            {subtitle && (
              <span className="text-[11px] text-[#3046B4]/80 font-medium">{subtitle}</span>
            )}
          </div>
        </div>
        {onNavigate && (
          <button
            onClick={() => onNavigate('dashboard')}
            className="p-2 text-[#3046B4] hover:bg-[#3046B4]/10 rounded-full transition active:scale-95"
            title="Ke Dashboard"
          >
            <svg className="w-6 h-6 stroke-[1.75]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
          </button>
        )}
      </header>
    );
  }

  return (
    <header className="flex justify-between items-center p-6 w-full shrink-0 select-none">
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 bg-[#3046B4] rounded-full flex items-center justify-center text-white text-sm font-semibold shadow-inner">
          <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" />
          </svg>
        </div>
        <div className="flex flex-col">
          <span className="text-sm font-bold text-[#3046B4] leading-tight">Alex Sander</span>
          <span className="text-[10px] text-[#3046B4]/70 font-medium tracking-wide">ID: BIO-8892</span>
        </div>
      </div>
      {showNotification && (
        <button
          onClick={() => alert('Tidak ada notifikasi baru saat ini.')}
          className="p-2 text-[#3046B4] hover:bg-[#3046B4]/10 rounded-full transition active:scale-95 relative"
          title="Notifikasi"
        >
          <svg className="w-6 h-6 stroke-[1.75]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
          </svg>
          <span className="absolute top-2 right-2 w-2 h-2 rounded-full bg-[#FFC436]"></span>
        </button>
      )}
    </header>
  );
}
