/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        appbg: '#F1F0EA',
        primaryBlue: '#3046B4',
        primaryYellow: '#FFC436',
        secondaryGray: '#5C5C5C',
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      boxShadow: {
        'neo': '6px 6px 0px #0f172a',
        'neo-sm': '4px 4px 0px #0f172a',
        'neo-blue': '6px 6px 0px #3046B4',
        'offset': '12px 12px 0px #3046B4',
      }
    },
  },
  plugins: [],
}
