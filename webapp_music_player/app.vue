<template>
  <div class="min-h-screen bg-dark-950 text-slate-100 flex flex-col relative selection:bg-brand-500 selection:text-white">
    <!-- Ambient Background Glow Gradients -->
    <div class="fixed top-0 left-1/4 w-96 h-96 bg-brand-600/10 rounded-full blur-[128px] pointer-events-none"></div>
    <div class="fixed bottom-1/4 right-1/4 w-96 h-96 bg-indigo-600/10 rounded-full blur-[128px] pointer-events-none"></div>

    <!-- Hidden YouTube Player Container -->
    <div class="hidden">
      <div id="ytplayer-frame"></div>
    </div>

    <!-- Toast Notification -->
    <Toast />

    <!-- API Key Settings Modal -->
    <ApiKeyModal />

    <!-- App Header -->
    <header class="sticky top-0 z-20 glass-panel border-b border-white/5 px-4 sm:px-6 py-3.5 flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div class="w-9 h-9 rounded-xl bg-gradient-to-tr from-brand-600 via-rose-500 to-amber-500 flex items-center justify-center shadow-lg shadow-brand-500/25">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 text-white">
            <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z" />
          </svg>
        </div>
        <div>
          <h1 class="text-base sm:text-lg font-extrabold tracking-tight bg-gradient-to-r from-white via-slate-100 to-slate-400 bg-clip-text text-transparent">
            VibeFlow
          </h1>
          <p class="text-[10px] text-slate-400 font-medium -mt-1 hidden sm:block">
            YouTube Music Player
          </p>
        </div>
      </div>

      <!-- Desktop Navigation links -->
      <div class="hidden md:flex items-center gap-1 bg-white/5 p-1 rounded-2xl border border-white/5">
        <button
          @click="store.activeTab = 'home'"
          class="px-4 py-1.5 rounded-xl text-xs font-semibold transition-all"
          :class="store.activeTab === 'home' ? 'bg-brand-500 text-white shadow-md shadow-brand-500/25' : 'text-slate-400 hover:text-white'"
        >
          Home
        </button>
        <button
          @click="store.activeTab = 'search'"
          class="px-4 py-1.5 rounded-xl text-xs font-semibold transition-all"
          :class="store.activeTab === 'search' ? 'bg-brand-500 text-white shadow-md shadow-brand-500/25' : 'text-slate-400 hover:text-white'"
        >
          Search
        </button>
        <button
          @click="store.activeTab = 'library'"
          class="px-4 py-1.5 rounded-xl text-xs font-semibold transition-all"
          :class="store.activeTab === 'library' ? 'bg-brand-500 text-white shadow-md shadow-brand-500/25' : 'text-slate-400 hover:text-white'"
        >
          Library
        </button>
        <button
          @click="store.activeTab = 'settings'"
          class="px-4 py-1.5 rounded-xl text-xs font-semibold transition-all"
          :class="store.activeTab === 'settings' ? 'bg-brand-500 text-white shadow-md shadow-brand-500/25' : 'text-slate-400 hover:text-white'"
        >
          Settings
        </button>
      </div>

      <!-- Right Header Actions -->
      <div class="flex items-center gap-2">
        <button
          @click="store.showApiKeyModal = true"
          class="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium border transition-all"
          :class="store.apiKey ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30' : 'bg-amber-500/10 text-amber-300 border-amber-500/30 hover:bg-amber-500/20'"
        >
          <span class="w-1.5 h-1.5 rounded-full" :class="store.apiKey ? 'bg-emerald-400' : 'bg-amber-400 animate-pulse'"></span>
          <span>{{ store.apiKey ? 'API Connected' : 'Set API Key' }}</span>
        </button>
      </div>
    </header>

    <!-- Main Content Area -->
    <main class="flex-1 w-full max-w-5xl mx-auto px-4 sm:px-6 pt-4 pb-36 md:pb-32">
      <!-- TAB 1: HOME -->
      <section v-if="store.activeTab === 'home'" class="space-y-6">
        <!-- Hero Greeting Banner -->
        <div class="relative overflow-hidden rounded-3xl p-6 sm:p-8 bg-gradient-to-r from-brand-900/60 via-dark-850 to-dark-900 border border-brand-500/20 shadow-2xl">
          <div class="relative z-10 max-w-md">
            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider bg-brand-500/20 text-brand-400 border border-brand-500/30 mb-3">
              ✦ Mobile-First Streaming
            </span>
            <h2 class="text-2xl sm:text-3xl font-extrabold text-white tracking-tight">
              Listen without limits.
            </h2>
            <p class="text-xs sm:text-sm text-slate-300 mt-2 leading-relaxed">
              Play any YouTube track in high quality, scrub audio smoothly, build your library, and enjoy rich mobile controls.
            </p>
            <div class="mt-4 flex flex-wrap gap-2.5">
              <button
                @click="store.loadCategory('trending')"
                class="px-4 py-2 rounded-xl bg-brand-500 text-white text-xs font-bold hover:brightness-110 active:scale-95 transition-all shadow-lg shadow-brand-500/30 flex items-center gap-1.5"
              >
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-4 h-4">
                  <path d="M8 5v14l11-7z" />
                </svg>
                Play Trending
              </button>
              <button
                @click="store.activeTab = 'search'"
                class="px-4 py-2 rounded-xl bg-white/10 hover:bg-white/15 text-slate-200 text-xs font-semibold transition-all border border-white/10"
              >
                Search Live YouTube
              </button>
            </div>
          </div>
          <!-- Decorative Background circle -->
          <div class="absolute -right-10 -bottom-10 w-60 h-60 rounded-full bg-brand-500/10 blur-2xl pointer-events-none"></div>
        </div>

        <!-- Quick Play Pill Grids (Spotify / YT Music mobile home style) -->
        <div>
          <h3 class="text-sm font-bold uppercase tracking-wider text-slate-400 mb-3 flex items-center gap-2">
            <span>🔥 Curated Channels</span>
          </h3>
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div
              @click="store.loadCategory('trending')"
              class="glass-panel p-3.5 rounded-2xl flex items-center gap-3 cursor-pointer hover:border-brand-500/40 hover:bg-white/10 active:scale-[0.98] transition-all group"
            >
              <div class="w-12 h-12 rounded-xl bg-gradient-to-tr from-brand-600 to-rose-500 flex items-center justify-center text-white shadow-md">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
                  <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                </svg>
              </div>
              <div class="min-w-0 flex-1">
                <h4 class="text-sm font-bold text-white group-hover:text-brand-400 transition-colors">Global Trending</h4>
                <p class="text-xs text-slate-400">Ed Sheeran, Queen, Pop</p>
              </div>
            </div>

            <div
              @click="store.loadCategory('chill')"
              class="glass-panel p-3.5 rounded-2xl flex items-center gap-3 cursor-pointer hover:border-brand-500/40 hover:bg-white/10 active:scale-[0.98] transition-all group"
            >
              <div class="w-12 h-12 rounded-xl bg-gradient-to-tr from-indigo-600 to-cyan-500 flex items-center justify-center text-white shadow-md">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
                  <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z" />
                </svg>
              </div>
              <div class="min-w-0 flex-1">
                <h4 class="text-sm font-bold text-white group-hover:text-cyan-400 transition-colors">Lo-Fi & Chillout</h4>
                <p class="text-xs text-slate-400">Synthwave, Acoustic, Relax</p>
              </div>
            </div>

            <div
              @click="store.loadCategory('pop')"
              class="glass-panel p-3.5 rounded-2xl flex items-center gap-3 cursor-pointer hover:border-brand-500/40 hover:bg-white/10 active:scale-[0.98] transition-all group"
            >
              <div class="w-12 h-12 rounded-xl bg-gradient-to-tr from-amber-500 to-pink-500 flex items-center justify-center text-white shadow-md">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
                  <path d="M12 14l9-5-9-5-9 5 9 5z" />
                  <path d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" />
                </svg>
              </div>
              <div class="min-w-0 flex-1">
                <h4 class="text-sm font-bold text-white group-hover:text-amber-400 transition-colors">Pop Essentials</h4>
                <p class="text-xs text-slate-400">Maroon 5, Katy Perry, OneRepublic</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Current Playing Playlist List -->
        <div>
          <div class="flex items-center justify-between mb-3">
            <h3 class="text-sm font-bold uppercase tracking-wider text-slate-400">
              Current Queue ({{ store.playlist.length }} songs)
            </h3>
            <button
              @click="store.showFullPlayer = true"
              class="text-xs text-brand-400 font-semibold hover:underline"
            >
              Open Full Player →
            </button>
          </div>

          <div class="space-y-1 bg-dark-900/60 rounded-3xl p-2 border border-white/5">
            <TrackItem
              v-for="item in store.playlist"
              :key="item.id"
              :track="item"
              :is-active="item.id === store.currentTrack?.id"
              :is-playing="store.isPlaying && item.id === store.currentTrack?.id"
              :is-fav="store.isFavorite(item.id)"
              @select="store.loadTrack(item, true)"
              @toggle-favorite="store.toggleFavorite(item)"
            />
          </div>
        </div>
      </section>

      <!-- TAB 2: SEARCH -->
      <section v-if="store.activeTab === 'search'" class="space-y-5">
        <!-- Live Search Input -->
        <div class="sticky top-16 z-10 pt-1 pb-3 backdrop-blur-xl bg-dark-950/80">
          <form @submit.prevent="handleSearch" class="relative flex items-center">
            <input
              v-model="searchInput"
              type="text"
              placeholder="Search songs, artists, albums on YouTube..."
              class="w-full px-4 py-3.5 pl-11 pr-24 rounded-2xl bg-dark-850 border border-white/10 text-white placeholder-slate-500 text-sm focus:outline-none focus:border-brand-500 shadow-xl transition-all"
            />
            <!-- Search Icon -->
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              class="w-5 h-5 text-slate-400 absolute left-3.5 pointer-events-none"
            >
              <circle cx="11" cy="11" r="8" />
              <path d="m21 21-4.3-4.3" />
            </svg>

            <!-- Search Button -->
            <button
              type="submit"
              :disabled="store.isSearching"
              class="absolute right-2 px-4 py-2 rounded-xl bg-gradient-to-r from-brand-600 to-rose-500 text-white text-xs font-bold shadow-md shadow-brand-500/20 hover:brightness-110 active:scale-95 transition-all disabled:opacity-50"
            >
              <span v-if="store.isSearching" class="flex items-center gap-1">
                <span class="w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
                <span>Searching</span>
              </span>
              <span v-else>Search</span>
            </button>
          </form>

          <!-- Quick Discovery Chips -->
          <div class="flex items-center gap-2 overflow-x-auto py-2.5 no-scrollbar">
            <button
              v-for="chip in genreChips"
              :key="chip"
              @click="quickSearch(chip)"
              class="flex-shrink-0 px-3 py-1.5 rounded-full text-xs font-medium bg-white/5 hover:bg-white/10 active:bg-brand-500 active:text-white border border-white/5 text-slate-300 transition-all"
            >
              {{ chip }}
            </button>
          </div>
        </div>

        <!-- Search Results List -->
        <div>
          <div v-if="store.searchResults.length" class="space-y-1">
            <div class="flex items-center justify-between pb-2 px-1">
              <h3 class="text-xs font-bold uppercase tracking-wider text-slate-400">
                Search Results ({{ store.searchResults.length }})
              </h3>
              <button
                @click="playAllSearchResults"
                class="text-xs text-brand-400 font-semibold hover:underline"
              >
                Play All
              </button>
            </div>
            <div class="space-y-1 bg-dark-900/60 rounded-3xl p-2 border border-white/5">
              <TrackItem
                v-for="item in store.searchResults"
                :key="item.id"
                :track="item"
                :is-active="item.id === store.currentTrack?.id"
                :is-playing="store.isPlaying && item.id === store.currentTrack?.id"
                :is-fav="store.isFavorite(item.id)"
                @select="store.loadTrack(item, true, store.searchResults)"
                @toggle-favorite="store.toggleFavorite(item)"
              />
            </div>
          </div>

          <!-- Empty State / No Search Yet -->
          <div
            v-else-if="!store.isSearching"
            class="text-center py-16 px-4 bg-dark-900/40 rounded-3xl border border-white/5"
          >
            <div class="w-14 h-14 mx-auto rounded-2xl bg-white/5 flex items-center justify-center text-slate-400 mb-3">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-6 h-6">
                <circle cx="11" cy="11" r="8" />
                <path d="m21 21-4.3-4.3" />
              </svg>
            </div>
            <h4 class="text-sm font-bold text-white">Find your favorite music</h4>
            <p class="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
              Type any artist, song, or vibe above to search across millions of YouTube tracks.
            </p>
          </div>
        </div>
      </section>

      <!-- TAB 3: LIBRARY -->
      <section v-if="store.activeTab === 'library'" class="space-y-6">
        <!-- Liked Songs Header Card -->
        <div class="relative overflow-hidden rounded-3xl p-6 bg-gradient-to-br from-brand-600 via-rose-600 to-dark-900 border border-brand-500/30 shadow-2xl">
          <div class="flex items-center gap-4">
            <div class="w-16 h-16 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center text-white shadow-xl">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-8 h-8 text-white">
                <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" />
              </svg>
            </div>
            <div>
              <span class="text-[10px] uppercase font-bold tracking-widest text-brand-200">Playlist</span>
              <h2 class="text-xl sm:text-2xl font-black text-white">Liked Songs</h2>
              <p class="text-xs text-white/80 mt-0.5">
                {{ store.favorites.length }} songs saved on this device
              </p>
            </div>
          </div>
          <div class="mt-4 flex gap-2" v-if="store.favorites.length">
            <button
              @click="playLikedSongs"
              class="px-4 py-2 rounded-xl bg-white text-dark-950 font-bold text-xs hover:bg-white/90 active:scale-95 transition-all flex items-center gap-1.5 shadow-lg"
            >
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-4 h-4 text-brand-600">
                <path d="M8 5v14l11-7z" />
              </svg>
              Play Liked Songs
            </button>
          </div>
        </div>

        <!-- Liked Songs List -->
        <div v-if="store.favorites.length">
          <div class="space-y-1 bg-dark-900/60 rounded-3xl p-2 border border-white/5">
            <TrackItem
              v-for="item in store.favorites"
              :key="item.id"
              :track="item"
              :is-active="item.id === store.currentTrack?.id"
              :is-playing="store.isPlaying && item.id === store.currentTrack?.id"
              :is-fav="true"
              @select="store.loadTrack(item, true, store.favorites)"
              @toggle-favorite="store.toggleFavorite(item)"
            />
          </div>
        </div>
        <div v-else class="text-center py-10 px-4 bg-dark-900/40 rounded-3xl border border-white/5">
          <p class="text-sm font-semibold text-slate-300">No liked songs yet</p>
          <p class="text-xs text-slate-500 mt-1">Tap the heart icon on any song to save it here.</p>
        </div>

        <!-- Recently Played History -->
        <div v-if="store.history.length" class="space-y-3 pt-4">
          <div class="flex items-center justify-between">
            <h3 class="text-xs font-bold uppercase tracking-wider text-slate-400">
              Recently Played ({{ store.history.length }})
            </h3>
            <button
              @click="clearHistory"
              class="text-[11px] text-slate-400 hover:text-rose-400 transition-colors"
            >
              Clear History
            </button>
          </div>
          <div class="space-y-1 bg-dark-900/60 rounded-3xl p-2 border border-white/5">
            <TrackItem
              v-for="item in store.history.slice(0, 15)"
              :key="'hist-' + item.id"
              :track="item"
              :is-active="item.id === store.currentTrack?.id"
              :is-playing="store.isPlaying && item.id === store.currentTrack?.id"
              :is-fav="store.isFavorite(item.id)"
              @select="store.loadTrack(item, true, store.history)"
              @toggle-favorite="store.toggleFavorite(item)"
            />
          </div>
        </div>
      </section>

      <!-- TAB 4: SETTINGS -->
      <section v-if="store.activeTab === 'settings'" class="space-y-5">
        <h2 class="text-lg font-bold text-white">App Settings & Preferences</h2>

        <!-- API Key Status Card -->
        <div class="glass-panel p-5 rounded-3xl space-y-3">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-sm font-bold text-white">YouTube Data API v3</h3>
              <p class="text-xs text-slate-400 mt-0.5">
                {{ store.apiKey ? 'Active: live search enabled' : 'Not configured' }}
              </p>
            </div>
            <button
              @click="store.showApiKeyModal = true"
              class="px-3.5 py-1.5 rounded-xl bg-brand-500 text-white text-xs font-semibold hover:brightness-110 active:scale-95 transition-all shadow-md shadow-brand-500/20"
            >
              {{ store.apiKey ? 'Change Key' : 'Configure' }}
            </button>
          </div>
        </div>

        <!-- Audio & Playback Options -->
        <div class="glass-panel p-5 rounded-3xl space-y-4">
          <h3 class="text-sm font-bold text-white">Audio & Playback</h3>
          <div class="flex items-center justify-between py-2 border-b border-white/5">
            <div>
              <p class="text-xs font-semibold text-slate-200">Default Volume</p>
              <p class="text-[11px] text-slate-400">{{ store.volume }}%</p>
            </div>
            <input
              type="range"
              min="0"
              max="100"
              :value="store.volume"
              @input="e => store.setPlayerVolume(Number((e.target as HTMLInputElement).value))"
              class="w-36 accent-brand-500"
            />
          </div>

          <div class="flex items-center justify-between py-2 border-b border-white/5">
            <div>
              <p class="text-xs font-semibold text-slate-200">Repeat Mode</p>
              <p class="text-[11px] text-slate-400">Currently: {{ store.repeatMode.toUpperCase() }}</p>
            </div>
            <button
              @click="store.toggleRepeat"
              class="px-3 py-1.5 rounded-xl bg-white/10 text-xs font-semibold text-slate-200 hover:bg-white/15"
            >
              Switch ({{ store.repeatMode }})
            </button>
          </div>

          <div class="flex items-center justify-between py-2">
            <div>
              <p class="text-xs font-semibold text-slate-200">Shuffle Playback</p>
              <p class="text-[11px] text-slate-400">{{ store.isShuffle ? 'Enabled' : 'Disabled' }}</p>
            </div>
            <button
              @click="store.toggleShuffle"
              class="px-3 py-1.5 rounded-xl text-xs font-semibold"
              :class="store.isShuffle ? 'bg-brand-500 text-white' : 'bg-white/10 text-slate-200'"
            >
              {{ store.isShuffle ? 'ON' : 'OFF' }}
            </button>
          </div>
        </div>

        <!-- About App -->
        <div class="glass-panel p-5 rounded-3xl space-y-2 text-xs text-slate-400">
          <h3 class="text-sm font-bold text-white">About VibeFlow</h3>
          <p>Built with Nuxt 3, Tailwind CSS, Pinia 2.1.7, Vue 3, and YouTube IFrame API.</p>
          <p>Designed for mobile screens with touch-friendly controls, background playback, and persistent audio synchronization.</p>
        </div>
      </section>
    </main>

    <!-- Persistent Floating Mini Player -->
    <MiniPlayer />

    <!-- Fullscreen Expandable Now-Playing Modal -->
    <FullPlayerModal />

    <!-- Mobile Bottom Navigation Bar -->
    <BottomNav />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { usePlayerStore } from '~/stores/player'

const store = usePlayerStore()

const searchInput = ref('')
const genreChips = [
  'Lofi Hip Hop',
  'Ed Sheeran',
  'Taylor Swift',
  'Despacito',
  'Acoustic Guitar',
  'Pop Hits 2024',
  'Synthwave Chill',
  'Khmer Music',
  'Rock Classics',
  'Deep Sleep Beats'
]

onMounted(() => {
  store.initFromStorage()
  store.initYouTube()
})

const handleSearch = () => {
  if (searchInput.value.trim()) {
    store.searchYouTube(searchInput.value)
  }
}

const quickSearch = (tag: string) => {
  searchInput.value = tag
  store.searchYouTube(tag)
}

const playAllSearchResults = () => {
  if (store.searchResults.length) {
    store.loadTrack(store.searchResults[0], true, store.searchResults)
    store.showToast(`Playing ${store.searchResults.length} search results`)
  }
}

const playLikedSongs = () => {
  if (store.favorites.length) {
    store.loadTrack(store.favorites[0], true, store.favorites)
    store.showToast(`Playing liked songs`)
  }
}

const clearHistory = () => {
  store.history = []
  if (typeof window !== 'undefined') {
    localStorage.removeItem('vibe_history')
  }
  store.showToast('Playback history cleared')
}
</script>
