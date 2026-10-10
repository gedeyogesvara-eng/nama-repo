import React, { useState } from 'react';

export default function Auth({ onNavigate }) {
  const [email, setEmail] = useState('user.lorem@gmail.com');
  const [password, setPassword] = useState('password123');
  const [isRegister, setIsRegister] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!email.trim() || !password.trim()) {
      setErrorMsg('Mohon isi email dan password terlebih dahulu');
      return;
    }
    setErrorMsg('');
    onNavigate('permission');
  };

  const handleGuestLogin = () => {
    onNavigate('permission');
  };

  return (
    <div className="flex-1 flex flex-col justify-between p-8 select-none bg-[#F1F0EA]">
      {/* Top spacing & brand header */}
      <div className="flex flex-col items-center mt-8 text-center">
        <div className="w-20 h-20 bg-[#3046B4] rounded-[28px] shadow-lg flex items-center justify-center text-white mb-4 relative">
          <div className="absolute inset-0 border-2 border-[#3046B4] rounded-[28px] translate-x-1.5 translate-y-1.5 opacity-40"></div>
          <svg className="w-10 h-10 relative z-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-[#3046B4]">Nama Aplikasi</h1>
        <p className="text-xs text-[#3046B4]/70 mt-1 font-medium">Multimodal AI Depression & Burnout Detection</p>
      </div>

      {/* Form Container */}
      <form onSubmit={handleSubmit} className="w-full flex flex-col gap-5 my-auto max-w-xs mx-auto">
        {errorMsg && (
          <div className="bg-red-50 text-red-600 border border-red-200 text-xs p-3 rounded-xl flex items-center gap-2">
            <svg className="w-4 h-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <span>{errorMsg}</span>
          </div>
        )}

        {isRegister && (
          <div className="flex flex-col">
            <label className="text-[11px] font-bold tracking-wider text-[#3046B4] uppercase">Nama Lengkap</label>
            <input
              type="text"
              placeholder="Nama Pengguna"
              defaultValue="Alex Sander"
              className="bg-transparent border-b-2 border-[#3046B4] py-2 text-sm text-[#3046B4] font-medium placeholder-[#3046B4]/40 focus:outline-none focus:border-[#FFC436] transition-colors"
            />
          </div>
        )}

        <div className="flex flex-col">
          <label className="text-[11px] font-bold tracking-wider text-[#3046B4] uppercase">Email</label>
          <input
            type="email"
            placeholder="user@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="bg-transparent border-b-2 border-[#3046B4] py-2 text-sm text-[#3046B4] font-medium placeholder-[#3046B4]/40 focus:outline-none focus:border-[#FFC436] transition-colors"
          />
        </div>

        <div className="flex flex-col">
          <label className="text-[11px] font-bold tracking-wider text-[#3046B4] uppercase">Password</label>
          <input
            type="password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="bg-transparent border-b-2 border-[#3046B4] py-2 text-sm text-[#3046B4] font-medium placeholder-[#3046B4]/40 focus:outline-none focus:border-[#FFC436] transition-colors"
          />
        </div>

        <div className="flex justify-between items-center text-xs text-[#3046B4]/70 pt-1">
          <label className="flex items-center gap-1.5 cursor-pointer">
            <input
              type="checkbox"
              checked={rememberMe}
              onChange={(e) => setRememberMe(e.target.checked)}
              className="rounded border-[#3046B4] text-[#3046B4] accent-[#3046B4] w-4 h-4 cursor-pointer"
            />
            <span>Ingat saya</span>
          </label>
          <button
            type="button"
            onClick={() => alert('Fitur pemulihan kata sandi dikirimkan ke email terdaftar.')}
            className="font-semibold text-[#3046B4] hover:underline"
          >
            Lupa kata sandi?
          </button>
        </div>

        <div className="flex justify-center mt-2">
          <button
            type="button"
            onClick={() => setIsRegister(!isRegister)}
            className="text-xs text-[#3046B4] font-medium hover:underline"
          >
            {isRegister ? 'Sudah punya akun? Masuk di sini' : 'Belum punya akun? Buat akun baru'}
          </button>
        </div>
      </form>

      {/* Button CTA */}
      <div className="flex flex-col items-center gap-3 mb-6">
        <button
          onClick={handleSubmit}
          className="w-full max-w-xs bg-[#3046B4] hover:bg-[#273a96] active:scale-95 text-white font-bold py-3.5 px-6 rounded-full shadow-lg transition-all flex items-center justify-center gap-2"
        >
          <span>{isRegister ? 'Daftar Sekarang' : 'Masuk / Register'}</span>
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
          </svg>
        </button>

        <button
          type="button"
          onClick={handleGuestLogin}
          className="text-xs text-[#3046B4] font-semibold hover:opacity-80 py-1"
        >
          Masuk Langsung sebagai Tamu (Guest)
        </button>

        <p className="text-[11px] text-[#3046B4]/60">Versi Prototipe Interaktif 1.0</p>
      </div>
    </div>
  );
}
