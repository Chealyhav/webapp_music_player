# 🎵 VibeFlow — Modern YouTube Music Player (Nuxt 3)

A responsive, mobile-first YouTube Music web application built with **Nuxt 3**, **Pinia 2.1.7**, **Tailwind CSS**, and the **YouTube IFrame API**.

---

## ✨ Features

- **Mobile App Native UI/UX**:
  - **Floating Mini Player**: Stays pinned above the navigation bar with real-time audio progress indicator, live track details, play/pause, and favorite toggles.
  - **Full-Screen Now Playing Sheet**: Ambient dynamic album glow, vinyl card view, interactive scrubbable progress bar, shuffle/repeat modes, and volume control.
  - **Video / Audio Toggle**: Switch seamlessly between full album artwork mode and direct YouTube video playback mode.
  - **Bottom Navigation Bar**: Native mobile navigation between **Home**, **Search**, **Library**, and **Settings**.
  - **Queue / Up Next**: Expandable drawer inside the full player to view and re-order upcoming tracks.
- **State Management with Pinia 2.1.7**:
  - Global reactive store located at `stores/player.ts`.
  - Supports continuous music playback across all views without interruption.
  - Native **MediaSession API** integration for lock screen and Bluetooth headphone controls (play, pause, next, previous, seek).
- **YouTube Integration**:
  - Configured with `.env` using `YOUTUBE_API_KEY`.
  - Live search across YouTube's music catalog.
  - Curated out-of-the-box playlists for instant playback (Global Trending, Lo-Fi Chillout, Pop Essentials).
  - Favorites and Recently Played history persisted locally via `localStorage`.
- **Responsive Layout**:
  - Optimized for mobile smartphones (safe-area padding, touch targets).
  - Adapts to tablet and desktop layouts with a unified glassmorphic theme.

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
npm install
```

### 2. Environment Configuration
Create a `.env` file in the project root and add your YouTube Data API key:
```env
YOUTUBE_API_KEY=your_youtube_data_api_key
```

Keep your real API key private; `.env` files are excluded from Git.

### 3. Run Development Server
```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) in your mobile or desktop browser.

### 4. Build for Production
```bash
npm run build
```
Preview production build:
```bash
npm run preview
```
