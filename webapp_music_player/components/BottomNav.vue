<template>
  <nav
    class="fixed bottom-0 left-0 right-0 z-20 glass-nav pb-safe md:hidden select-none"
  >
    <div class="flex items-center justify-around h-16 max-w-md mx-auto px-4">
      <!-- Home Tab -->
      <button
        @click="store.activeTab = 'home'"
        class="flex flex-col items-center justify-center w-14 py-1 text-slate-400 transition-colors"
        :class="{ '!text-brand-500 font-semibold': store.activeTab === 'home' }"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          :fill="store.activeTab === 'home' ? 'currentColor' : 'none'"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="w-5 h-5 mb-1"
        >
          <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
          <polyline points="9 22 9 12 15 12 15 22" />
        </svg>
        <span class="text-[10px] tracking-tight">Home</span>
      </button>

      <!-- Search Tab -->
      <button
        @click="store.activeTab = 'search'"
        class="flex flex-col items-center justify-center w-14 py-1 text-slate-400 transition-colors"
        :class="{ '!text-brand-500 font-semibold': store.activeTab === 'search' }"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2.5"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="w-5 h-5 mb-1"
        >
          <circle cx="11" cy="11" r="8" />
          <path d="m21 21-4.3-4.3" />
        </svg>
        <span class="text-[10px] tracking-tight">Search</span>
      </button>

      <!-- Library Tab -->
      <button
        @click="store.activeTab = 'library'"
        class="flex flex-col items-center justify-center w-14 py-1 text-slate-400 transition-colors"
        :class="{ '!text-brand-500 font-semibold': store.activeTab === 'library' }"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          :fill="store.activeTab === 'library' ? 'currentColor' : 'none'"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="w-5 h-5 mb-1"
        >
          <path d="m16 6 4 14" />
          <path d="M12 6v14" />
          <path d="M8 8v12" />
          <path d="M4 4v16" />
        </svg>
        <span class="text-[10px] tracking-tight">Library</span>
      </button>

      <!-- Settings / Key Tab -->
      <button
        @click="store.activeTab = 'settings'"
        class="flex flex-col items-center justify-center w-14 py-1 text-slate-400 transition-colors relative"
        :class="{ '!text-brand-500 font-semibold': store.activeTab === 'settings' }"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="w-5 h-5 mb-1"
        >
          <circle cx="12" cy="12" r="3" />
          <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" />
        </svg>
        <span class="text-[10px] tracking-tight">Settings</span>
        <!-- Small dot if API Key is not set -->
        <span
          v-if="!store.apiKey"
          class="absolute top-1.5 right-3 w-1.5 h-1.5 rounded-full bg-amber-400 animate-pulse"
        ></span>
      </button>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { usePlayerStore } from '~/stores/player'

const store = usePlayerStore()
</script>
