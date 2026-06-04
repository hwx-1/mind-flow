/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        cream: { DEFAULT: '#faf6f0', deep: '#f3ece1' },
        paper: '#fffdfa',
        terracotta: { DEFAULT: '#d98e73', deep: '#c2755a' },
        sage: { DEFAULT: '#9caf88', deep: '#7d9268' },
        clay: '#8a7158',
        ink: { DEFAULT: '#4a3f35', soft: '#8a7d6e' },
        line: '#ece2d4',
        gold: '#e0b87f',
        blush: '#f0d4c4',
        danger: '#c0573f',
      },
      fontFamily: {
        sans: ['"Noto Sans SC"', '-apple-system', 'sans-serif'],
        serif: ['"Noto Serif SC"', 'serif'],
      },
      boxShadow: {
        soft: '0 4px 24px rgba(138,113,88,.08)',
        'soft-lg': '0 12px 48px rgba(138,113,88,.12)',
      },
    },
  },
  plugins: [],
};
