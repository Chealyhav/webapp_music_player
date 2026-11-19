<template>
  <div
    v-if="store.showFullPlayer"
    class="fixed inset-0 z-50 flex flex-col justify-end transition-all duration-300"
  >
    <!-- Backdrop Blur with dark tint -->
    <div
      @click="store.showFullPlayer = false"
      class="absolute inset-0 bg-black/80 backdrop-blur-2xl transition-opacity"
    ></div>

    <!-- Ambient Dynamic Glow from Album Art -->
    <div
      v-if="store.currentTrack"
      class="absolute inset-0 pointer-events-none opacity-30 blur-[100px] overflow-hidden"
    >
      <img
        :src="store.currentTrack.thumb"
        class="w-full h-full object-cover scale-150 transform -translate-y-10"
      />
    </div>

    <!-- Main Sheet Container -->
    <div
      class="relative z-10 w-full max-w-lg mx-auto h-[95vh] sm:h-[90vh] bg-gradient-to-b from-dark-900/95 via-dark-950/98 to-dark-950 rounded-t-[32px] sm:rounded-[32px] border-t sm:border border-white/10 shadow-2xl flex flex-col overflow-hidden pb-safe"
    >
      <!-- Top Drag Handle / Header -->
      <div class="px-6 pt-3 pb-2 flex-shrink-0 flex items-center justify-between">
        <button
          @click="store.showFullPlayer = false"
          class="p-2 -ml-2 text-slate-400 hover:text-white active:scale-95 transition-all rounded-full hover:bg-white/5"
          title="Minimize player"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="w-6 h-6"
          >
            <path d="m6 9 6 6 6-6" />
          </svg>
        </button>

        <div class="text-center">
          <p class="text-[10px] tracking-widest uppercase font-bold text-slate-400">
            Now Playing
          </p>
          <p class="text-xs text-brand-400 font-medium truncate max-w-[200px]">
            {{ store.currentTrack?.channel || 'YouTube Music' }}
          </p>
        </div>

        <!-- Video Mode Switch Toggle -->
        <button
          @click="store.showVideo = !store.showVideo"
          class="p-2 -mr-2 text-slate-400 hover:text-white rounded-full hover:bg-white/5 transition-all text-xs flex items-center gap-1"
          :class="{ '!text-brand-400 !bg-brand-500/10': store.showVideo }"
          title="Toggle Video view"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="w-5 h-5"
          >
            <rect width="20" height="15" x="2" y="4" rx="2" />
            <polygon points="10 9 15 12 10 15 10 9" />
          </svg>
        </button>
      </div>

      <!-- Scrollable Body for Controls & Queue -->
      <div class="flex-1 overflow-y-auto px-6 py-2 flex flex-col justify-between">
        <!-- Visual Section (Album Art or Video Frame) -->
        <div class="my-auto py-2">
          <!-- Video Display Mode -->
          <div
            v-show="store.showVideo"
            class="w-full aspect-video rounded-2xl overflow-hidden bg-black shadow-2xl border border-white/10 relative"
          >
            <div id="ytplayer-video-host" class="w-full h-full"></div>
          </div>

          <!-- Cover Art Display Mode -->
          <div
            v-show="!store.showVideo"
            class="relative w-64 h-64 sm:w-72 sm:h-72 mx-auto rounded-3xl overflow-hidden shadow-2xl border border-white/10 group"
          >
            <img
              v-if="store.currentTrack"
              :src="store.currentTrack.thumb"
              :alt="store.currentTrack.title"
              class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
            />
            <!-- Ambient Inner Shadow & Glow -->
            <div class="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent pointer-events-none"></div>

            <!-- Pulsing audio indicator badge -->
            <div
              v-if="store.isPlaying"
              class="absolute top-3 right-3 bg-dark-900/80 backdrop-blur-md px-2.5 py-1 rounded-full border border-white/10 flex items-center gap-1.5 shadow-lg"
            >
              <span class="w-2 h-2 rounded-full bg-brand-500 animate-pulse"></span>
              <span class="text-[10px] font-semibold text-white tracking-wider uppercase">Live Stream</span>
            </div>
          </div>
        </div>

        <!-- Song Metadata & Favorite Button -->
        <div class="mt-4 flex items-center justify-between gap-4">
          <div class="min-w-0 flex-1">
            <h2 class="text-lg sm:text-xl font-bold text-white tracking-tight line-clamp-2">
              {{ store.currentTrack?.title || 'No Track Selected' }}
            </h2>
            <p class="text-sm text-slate-400 mt-1 truncate flex items-center gap-2">
              <span>{{ store.currentTrack?.channel || 'Unknown Artist' }}</span>
              <span class="inline-block w-1 h-1 rounded-full bg-slate-600"></span>
              <span class="text-xs text-brand-400 font-medium">YouTube</span>
            </p>
          </div>

          <button
            v-if="store.currentTrack"
            @click="store.toggleFavorite(store.currentTrack)"
            class="p-3 rounded-full hover:bg-white/10 active:scale-90 transition-all text-slate-400"
            :class="{ '!text-brand-500': store.isFavorite(store.currentTrack.id) }"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              :fill="store.isFavorite(store.currentTrack.id) ? 'currentColor' : 'none'"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="w-6 h-6"
            >
              <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" />
            </svg>
          </button>
        </div>

        <!-- Progress Bar & Timers -->
        <div class="mt-5">
          <div
            @click="handleProgressClick"
            class="relative w-full h-3 flex items-center cursor-pointer group"
          >
            <!-- Background track -->
            <div class="w-full h-1.5 bg-white/15 rounded-full overflow-hidden group-hover:h-2 transition-all">
              <!-- Buffered / Active progress -->
              <div
                class="h-full bg-gradient-to-r from-brand-600 to-rose-400 rounded-full"
                :style="{ width: progressPercent + '%' }"
              ></div>
            </div>
            <!-- Slider Thumb handle -->
            <div
              class="absolute w-3.5 h-3.5 bg-white rounded-full shadow-md -ml-1.5 pointer-events-none group-hover:scale-125 transition-transform"
              :style="{ left: progressPercent + '%' }"
            ></div>
          </div>

          <!-- Timestamps -->
          <div class="flex justify-between items-center text-[11px] font-medium text-slate-400 mt-1">
            <span>{{ store.formatTime(store.currentTime) }}</span>
            <span>{{ store.formatTime(store.duration) }}</span>
          </div>
        </div>

        <!-- Primary Controls -->
        <div class="mt-4 flex items-center justify-between px-2">
          <!-- Shuffle Button -->
          <button
            @click="store.toggleShuffle"
            class="p-2.5 rounded-full text-slate-400 hover:text-white active:scale-90 transition-all relative"
            :class="{ '!text-brand-400': store.isShuffle }"
            title="Shuffle"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="w-5 h-5"
            >
              <path d="M2 18h1.4c1.3 0 2.5-.6 3.3-1.7l6.1-8.6c.7-1.1 2-1.7 3.3-1.7H22" />
              <path d="m18 2 4 4-4 4" />
              <path d="M2 6h1.9c1.5 0 2.9.9 3.6 2.2" />
              <path d="M22 18h-5.9c-1.3 0-2.6-.7-3.3-1.8l-.5-.8" />
              <path d="m18 14 4 4-4 4" />
            </svg>
            <span
              v-if="store.isShuffle"
              class="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-brand-400"
            ></span>
          </button>

          <!-- Previous Track -->
          <button
            @click="store.prevTrack"
            class="p-3 text-slate-200 hover:text-white active:scale-90 transition-all"
            title="Previous"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="currentColor"
              class="w-7 h-7"
            >
              <path d="M18.75 5.653c0-.856-.917-1.398-1.667-.986l-11.54 6.347a1.125 1.125 0 0 0 0 1.972l11.54 6.347a1.125 1.125 0 0 0 1.667-.986V5.653Z" />
              <path d="M3.75 5.25h1.5v13.5h-1.5z" />
            </svg>
          </button>

          <!-- Big Play / Pause Button -->
          <button
            @click="store.togglePlay"
            class="w-16 h-16 rounded-full bg-gradient-to-tr from-brand-600 via-rose-500 to-pink-500 text-white flex items-center justify-center shadow-xl shadow-brand-500/35 hover:scale-105 active:scale-95 transition-all"
            :title="store.isPlaying ? 'Pause' : 'Play'"
          >
            <svg
              v-if="store.isPlaying"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="currentColor"
              class="w-8 h-8"
            >
              <path fill-rule="evenodd" d="M6.75 5.25a.75.75 0 0 1 .75.75v12a.75.75 0 0 1-1.5 0v-12a.75.75 0 0 1 .75-.75Zm10.5 0a.75.75 0 0 1 .75.75v12a.75.75 0 0 1-1.5 0v-12a.75.75 0 0 1 .75-.75Z" clip-rule="evenodd" />
            </svg>
            <svg
              v-else
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="currentColor"
              class="w-8 h-8 ml-1"
            >
              <path d="M8 5v14l11-7z" />
            </svg>
          </button>

          <!-- Next Track -->
          <button
            @click="store.nextTrack"
            class="p-3 text-slate-200 hover:text-white active:scale-90 transition-all"
            title="Next"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="currentColor"
              class="w-7 h-7"
            >
              <path d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.347a1.125 1.125 0 0 1 0 1.972l-11.54 6.347a1.125 1.125 0 0 1-1.667-.986V5.653Z" />
              <path d="M18.75 5.25h1.5v13.5h-1.5z" />
            </svg>
          </button>

          <!-- Repeat Mode -->
          <button
            @click="store.toggleRepeat"
            class="p-2.5 rounded-full text-slate-400 hover:text-white active:scale-90 transition-all relative"
            :class="{ '!text-brand-400': store.repeatMode !== 'off' }"
            title="Repeat mode"
          >
            <svg
              v-if="store.repeatMode === 'one'"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="w-5 h-5"
            >
              <path d="m17 2 4 4-4 4" />
              <path d="M3 11v-1a4 4 0 0 1 4-4h14" />
              <path d="m7 22-4-4 4-4" />
              <path d="M21 13v1a4 4 0 0 1-4 4H3" />
              <path d="M11 10h1v4" />
            </svg>
            <svg
              v-else
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="w-5 h-5"
            >
              <path d="m17 2 4 4-4 4" />
              <path d="M3 11v-1a4 4 0 0 1 4-4h14" />
              <path d="m7 22-4-4 4-4" />
              <path d="M21 13v1a4 4 0 0 1-4 4H3" />
            </svg>
            <span
              v-if="store.repeatMode !== 'off'"
              class="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-brand-400"
            ></span>
          </button>
        </div>

        <!-- Volume Bar -->
        <div class="mt-4 flex items-center gap-3 px-3 py-2 bg-white/5 rounded-2xl border border-white/5">
          <button
            @click="store.toggleMute"
            class="text-slate-400 hover:text-white transition-colors"
            :title="store.isMuted ? 'Unmute' : 'Mute'"
          >
            <svg
              v-if="store.isMuted || store.volume === 0"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="w-5 h-5 text-rose-400"
            >
              <line x1="1" x2="23" y1="1" y2="23" />
              <path d="M9 9v3a3 3 0 0 0 5.12 2.12M15 9.34V4a3 3 0 0 0-5.94-.6" />
              <path d="M17 16.95A7 7 0 0 1 5 12v-2m14 0v2a7 7 0 0 1-.11 1.23" />
              <line x1="12" x2="12" y1="19" y2="23" />
              <line x1="8" x2="16" y1="23" y2="23" />
            </svg>
            <svg
              v-else
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="w-5 h-5"
            >
              <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" />
              <path d="M15.54 8.46a5 5 0 0 1 0 7.07" />
              <path d="M19.07 4.93a10 10 0 0 1 0 14.14" />
            </svg>
          </button>

          <input
            type="range"
            min="0"
            max="100"
            :value="store.isMuted ? 0 : store.volume"
            @input="onVolumeInput"
            class="flex-1 accent-brand-500"
          />

          <span class="text-[11px] text-slate-400 font-mono w-7 text-right">
            {{ store.isMuted ? '0%' : `${store.volume}%` }}
          </span>
        </div>

        <!-- Up Next / Queue Drawer Tab -->
        <div class="mt-4 pt-3 border-t border-white/10">
          <button
            @click="showQueue = !showQueue"
            class="w-full flex items-center justify-between text-xs font-semibold text-slate-300 hover:text-white py-1"
          >
            <span class="flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-4 h-4 text-brand-400">
                <line x1="8" x2="21" y1="6" y2="6" />
                <line x1="8" x2="21" y1="12" y2="12" />
                <line x1="8" x2="21" y1="18" y2="18" />
                <line x1="3" x2="3.01" y1="6" y2="6" />
                <line x1="3" x2="3.01" y1="12" y2="12" />
                <line x1="3" x2="3.01" y1="18" y2="18" />
              </svg>
              Queue ({{ store.playlist.length }} tracks)
            </span>
            <span class="text-slate-400 text-[11px]">
              {{ showQueue ? 'Hide Queue' : 'View Queue' }}
            </span>
          </button>

          <!-- Queue List accordion -->
          <div
            v-if="showQueue"
            class="mt-2 max-h-48 overflow-y-auto space-y-1.5 pr-1 rounded-xl"
          >
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
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { usePlayerStore } from '~/stores/player'

const store = usePlayerStore()
const showQueue = ref(false)

const progressPercent = computed(() => {
  if (!store.duration || store.duration === 0) return 0
  return Math.min(100, Math.max(0, (store.currentTime / store.duration) * 100))
})

const handleProgressClick = (e: MouseEvent) => {
  const target = e.currentTarget as HTMLElement
  const rect = target.getBoundingClientRect()
  const clickX = e.clientX - rect.left
  const pct = Math.max(0, Math.min(1, clickX / rect.width))
  if (store.duration > 0) {
    store.seekTo(store.duration * pct)
  }
}

const onVolumeInput = (e: Event) => {
  const val = Number((e.target as HTMLInputElement).value)
  store.setPlayerVolume(val)
}
</script>
