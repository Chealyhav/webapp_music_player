<template>
  <div
    v-if="store.currentTrack"
    class="fixed bottom-[68px] md:bottom-6 left-0 right-0 z-30 px-3 md:px-6 pointer-events-none"
  >
    <div
      @click="store.showFullPlayer = true"
      class="max-w-xl mx-auto w-full glass-panel rounded-2xl p-2.5 flex items-center gap-3.5 shadow-2xl backdrop-blur-xl border border-white/10 hover:border-brand-500/30 transition-all duration-300 pointer-events-auto cursor-pointer relative overflow-hidden group"
    >
      <!-- Top Track Progress line -->
      <div class="absolute top-0 left-0 right-0 h-[2.5px] bg-white/10 overflow-hidden">
        <div
          class="h-full bg-gradient-to-r from-brand-600 via-brand-500 to-rose-400 transition-all duration-200"
          :style="{ width: progressPercent + '%' }"
        ></div>
      </div>

      <!-- Thumbnail -->
      <div class="relative w-11 h-11 rounded-xl overflow-hidden flex-shrink-0 bg-dark-900 shadow-md">
        <img
          :src="store.currentTrack.thumb"
          :alt="store.currentTrack.title"
          class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
        />
        <div
          v-if="store.isPlaying"
          class="absolute inset-0 bg-black/20 flex items-center justify-center"
        >
          <span class="w-2 h-2 rounded-full bg-brand-500 animate-ping"></span>
        </div>
      </div>

      <!-- Track Information -->
      <div class="flex-1 min-w-0 pr-1">
        <h4 class="text-xs sm:text-sm font-semibold text-white truncate group-hover:text-brand-400 transition-colors">
          {{ store.currentTrack.title }}
        </h4>
        <p class="text-[11px] sm:text-xs text-slate-400 truncate mt-0.5">
          {{ store.currentTrack.channel }}
        </p>
      </div>

      <!-- Control Buttons -->
      <div class="flex items-center gap-1 sm:gap-2 flex-shrink-0" @click.stop>
        <!-- Heart / Favorite -->
        <button
          @click="store.toggleFavorite(store.currentTrack)"
          class="p-2 text-slate-400 hover:text-brand-500 active:scale-90 transition-all"
          :class="{ '!text-brand-500': store.isFavorite(store.currentTrack.id) }"
          title="Like song"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            :fill="store.isFavorite(store.currentTrack.id) ? 'currentColor' : 'none'"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="w-4 h-4 sm:w-5 sm:h-5"
          >
            <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" />
          </svg>
        </button>

        <!-- Play / Pause -->
        <button
          @click="store.togglePlay"
          class="w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-gradient-to-r from-brand-600 to-rose-500 text-white flex items-center justify-center shadow-lg shadow-brand-500/25 active:scale-95 hover:brightness-110 transition-all"
          :title="store.isPlaying ? 'Pause' : 'Play'"
        >
          <svg
            v-if="store.isPlaying"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            class="w-5 h-5"
          >
            <path fill-rule="evenodd" d="M6.75 5.25a.75.75 0 0 1 .75.75v12a.75.75 0 0 1-1.5 0v-12a.75.75 0 0 1 .75-.75Zm10.5 0a.75.75 0 0 1 .75.75v12a.75.75 0 0 1-1.5 0v-12a.75.75 0 0 1 .75-.75Z" clip-rule="evenodd" />
          </svg>
          <svg
            v-else
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            class="w-5 h-5 ml-0.5"
          >
            <path d="M8 5v14l11-7z" />
          </svg>
        </button>

        <!-- Next Track -->
        <button
          @click="store.nextTrack"
          class="p-2 text-slate-300 hover:text-white active:scale-90 transition-all hidden xs:block"
          title="Next track"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            class="w-5 h-5"
          >
            <path d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.347a1.125 1.125 0 0 1 0 1.972l-11.54 6.347a1.125 1.125 0 0 1-1.667-.986V5.653Z" />
            <path d="M18.75 5.25h1.5v13.5h-1.5z" />
          </svg>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { usePlayerStore } from '~/stores/player'

const store = usePlayerStore()

const progressPercent = computed(() => {
  if (!store.duration || store.duration === 0) return 0
  return Math.min(100, Math.max(0, (store.currentTime / store.duration) * 100))
})
</script>
