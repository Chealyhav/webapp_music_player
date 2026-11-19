<template>
  <div
    v-if="store.showApiKeyModal"
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-md"
  >
    <div
      class="w-full max-w-md bg-dark-900 border border-white/10 rounded-3xl p-6 shadow-2xl relative"
    >
      <button
        @click="store.showApiKeyModal = false"
        class="absolute top-4 right-4 p-2 text-slate-400 hover:text-white rounded-full hover:bg-white/5 transition-colors"
      >
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-5 h-5">
          <line x1="18" y1="6" x2="6" y2="18" />
          <line x1="6" y1="6" x2="18" y2="18" />
        </svg>
      </button>

      <div class="flex items-center gap-3 mb-4">
        <div class="w-10 h-10 rounded-2xl bg-gradient-to-tr from-brand-600 to-rose-500 flex items-center justify-center text-white shadow-lg shadow-brand-500/20">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-5 h-5">
            <path d="M21 2l-2 2m-1-1l-3 3m2 2l-3 3m1-1l-2 2m-2-2l-3 3m3 3l-2 2M3 21l3-3m0 0l3-3m-3 3l-3-3m3 3L9 15" />
            <circle cx="7.5" cy="7.5" r="4.5" />
          </svg>
        </div>
        <div>
          <h3 class="text-base font-bold text-white">YouTube Data API Key</h3>
          <p class="text-xs text-slate-400">Unlock live search for all songs and artists</p>
        </div>
      </div>

      <div class="space-y-4">
        <div>
          <label class="block text-xs font-semibold text-slate-300 mb-1.5">
            Paste API Key:
          </label>
          <div class="relative">
            <input
              v-model="inputKey"
              :type="showKey ? 'text' : 'password'"
              placeholder="AIzaSy..."
              class="w-full px-3.5 py-2.5 rounded-xl bg-dark-800 border border-white/10 text-white placeholder-slate-500 text-sm focus:outline-none focus:border-brand-500 transition-colors pr-10"
            />
            <button
              type="button"
              @click="showKey = !showKey"
              class="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-200 p-1"
            >
              <svg v-if="showKey" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-4 h-4">
                <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z" />
                <circle cx="12" cy="12" r="3" />
              </svg>
              <svg v-else xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-4 h-4">
                <path d="M9.88 9.88a3 3 0 1 0 4.24 4.24" />
                <path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68" />
                <path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61" />
                <line x1="2" x2="22" y1="2" y2="22" />
              </svg>
            </button>
          </div>
        </div>

        <!-- How to get API Key helper box -->
        <div class="p-3 bg-white/5 rounded-xl border border-white/5 text-xs text-slate-300 space-y-1.5">
          <p class="font-semibold text-slate-200 flex items-center gap-1.5">
            <span class="w-1.5 h-1.5 rounded-full bg-brand-400"></span>
            Configured default key:
          </p>
          <p class="text-[11px] text-slate-400 font-mono break-all">
            AIzaSyBWoRrWmidw1PfI9dNXLJOWiHRn8E-RYq8
          </p>
        </div>

        <div class="flex gap-2 pt-2">
          <button
            @click="store.showApiKeyModal = false"
            class="flex-1 py-2.5 rounded-xl bg-white/5 text-slate-300 text-sm font-medium hover:bg-white/10 transition-colors"
          >
            Cancel
          </button>
          <button
            @click="handleSave"
            class="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-brand-600 to-rose-500 text-white text-sm font-semibold hover:brightness-110 active:scale-95 transition-all shadow-lg shadow-brand-500/25"
          >
            Save Key
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { usePlayerStore } from '~/stores/player'

const store = usePlayerStore()

const inputKey = ref(store.apiKey)
const showKey = ref(false)

onMounted(() => {
  inputKey.value = store.apiKey
})

watch(() => store.apiKey, (val) => {
  inputKey.value = val
})

const handleSave = () => {
  store.saveApiKey(inputKey.value)
}
</script>
