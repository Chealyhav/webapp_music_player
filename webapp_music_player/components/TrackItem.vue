<template>
  <div
    @click="$emit('select', track)"
    class="group flex items-center gap-3.5 p-2.5 rounded-2xl cursor-pointer transition-all duration-200"
    :class="isActive ? 'bg-brand-500/15 border border-brand-500/30' : 'hover:bg-white/5 active:bg-white/10'"
  >
    <!-- Thumbnail with play status -->
    <div class="relative w-12 h-12 flex-shrink-0 rounded-xl overflow-hidden bg-dark-800 shadow-md">
      <img
        :src="track.thumb || 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200&auto=format&fit=crop&q=80'"
        :alt="track.title"
        class="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
        loading="lazy"
      />
      <!-- Active Sound Wave Animation or Play Icon Overlay -->
      <div
        v-if="isActive"
        class="absolute inset-0 bg-black/40 backdrop-blur-[2px] flex items-center justify-center gap-0.5"
      >
        <span
          v-if="isPlaying"
          class="w-1 bg-brand-500 rounded-full animate-sound-bar"
          style="height: 16px; animation-delay: 0ms;"
        ></span>
        <span
          v-if="isPlaying"
          class="w-1 bg-brand-500 rounded-full animate-sound-bar"
          style="height: 22px; animation-delay: 200ms;"
        ></span>
        <span
          v-if="isPlaying"
          class="w-1 bg-brand-500 rounded-full animate-sound-bar"
          style="height: 12px; animation-delay: 400ms;"
        ></span>
        <svg
          v-else
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="currentColor"
          class="w-5 h-5 text-brand-500"
        >
          <path d="M8 5v14l11-7z" />
        </svg>
      </div>
      <div
        v-else
        class="absolute inset-0 bg-black/30 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="currentColor"
          class="w-5 h-5 text-white"
        >
          <path d="M8 5v14l11-7z" />
        </svg>
      </div>
    </div>

    <!-- Track Info -->
    <div class="flex-1 min-w-0 pr-1">
      <h4
        class="text-sm font-semibold truncate transition-colors"
        :class="isActive ? 'text-brand-400' : 'text-slate-100 group-hover:text-white'"
      >
        {{ track.title }}
      </h4>
      <p class="text-xs text-slate-400 truncate mt-0.5 flex items-center gap-1.5">
        <span class="truncate">{{ track.channel }}</span>
        <span v-if="track.duration" class="text-[10px] text-slate-500">• {{ track.duration }}</span>
      </p>
    </div>

    <!-- Action Buttons -->
    <div class="flex items-center gap-1">
      <button
        @click.stop="$emit('toggle-favorite', track)"
        class="p-2 rounded-full text-slate-400 hover:text-brand-500 hover:bg-white/10 active:scale-90 transition-all"
        :class="{ '!text-brand-500': isFav }"
        title="Favorite"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          :fill="isFav ? 'currentColor' : 'none'"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="w-4 h-4"
        >
          <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" />
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Track } from '~/composables/usePlayer'

defineProps<{
  track: Track
  isActive?: boolean
  isPlaying?: boolean
  isFav?: boolean
}>()

defineEmits<{
  (e: 'select', track: Track): void
  (e: 'toggle-favorite', track: Track): void
}>()
</script>
