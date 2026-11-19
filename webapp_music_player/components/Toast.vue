<template>
  <Transition
    enter-active-class="transition duration-300 ease-out"
    enter-from-class="transform -translate-y-4 opacity-0 scale-95"
    enter-to-class="transform translate-y-0 opacity-100 scale-100"
    leave-active-class="transition duration-200 ease-in"
    leave-from-class="transform translate-y-0 opacity-100 scale-100"
    leave-to-class="transform -translate-y-4 opacity-0 scale-95"
  >
    <div
      v-if="store.toastMessage"
      class="fixed top-5 left-1/2 -translate-x-1/2 z-50 px-4 py-2.5 rounded-full bg-dark-900/95 text-white text-xs sm:text-sm font-medium border border-white/15 shadow-2xl backdrop-blur-xl flex items-center gap-2 max-w-[90vw] pointer-events-none"
    >
      <span class="w-2 h-2 rounded-full bg-brand-500 animate-ping"></span>
      <span class="truncate">{{ store.toastMessage }}</span>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { usePlayerStore } from '~/stores/player'

const store = usePlayerStore()
</script>
