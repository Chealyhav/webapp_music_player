import { defineStore } from 'pinia'
import { ref } from 'vue'

export interface Track {
  id: string
  title: string
  channel: string
  thumb: string
  duration?: string
  addedAt?: number
}

// Curated starter playlists with reliable embeddable YouTube music tracks
export const DEFAULT_TRACKS: Record<string, Track[]> = {
  trending: [
    {
      id: 'jfKfPfyJRdk',
      title: 'Lofi Hip Hop Radio - Beats to Relax/Study to',
      channel: 'Lofi Girl',
      thumb: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&auto=format&fit=crop&q=80',
    },
    {
      id: '5qap5aO4i9A',
      title: 'Lofi Hip Hop Radio - Beats to Sleep/Chill to',
      channel: 'Lofi Girl',
      thumb: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
    },
    {
      id: 'kJQP7kiw5Fk',
      title: 'Luis Fonsi - Despacito ft. Daddy Yankee',
      channel: 'Luis Fonsi',
      thumb: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
    },
    {
      id: 'JGwWNGJdvx8',
      title: 'Ed Sheeran - Shape of You',
      channel: 'Ed Sheeran',
      thumb: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&auto=format&fit=crop&q=80',
    },
    {
      id: '2Vv-BfVoq4g',
      title: 'Ed Sheeran - Perfect',
      channel: 'Ed Sheeran',
      thumb: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
    },
    {
      id: 'fJ9rUzIMcZQ',
      title: 'Queen - Bohemian Rhapsody',
      channel: 'Queen Official',
      thumb: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=600&auto=format&fit=crop&q=80',
    }
  ],
  chill: [
    {
      id: 'TURbeWK2wwg',
      title: 'Synthwave Chill Chillout - Nostalgic Night Drive',
      channel: 'Asthenic',
      thumb: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=600&auto=format&fit=crop&q=80',
    },
    {
      id: 'WPni755-Krg',
      title: 'Coffee Shop Acoustic Guitar Beats',
      channel: 'Cafe Music BGM',
      thumb: 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=600&auto=format&fit=crop&q=80',
    },
    {
      id: 'DWcJFNfaw9c',
      title: 'Night Sky Ambient Piano Relaxation',
      channel: 'Sleep Beats',
      thumb: 'https://images.unsplash.com/photo-1509114397022-ed747cca3f65?w=600&auto=format&fit=crop&q=80',
    }
  ],
  pop: [
    {
      id: 'CevxZvSJLk8',
      title: 'Katy Perry - Roar',
      channel: 'Katy Perry',
      thumb: 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=600&auto=format&fit=crop&q=80',
    },
    {
      id: '09R8_2nJtjg',
      title: 'Maroon 5 - Sugar',
      channel: 'Maroon 5',
      thumb: 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=600&auto=format&fit=crop&q=80',
    },
    {
      id: 'hT_nvWreIhg',
      title: 'OneRepublic - Counting Stars',
      channel: 'OneRepublic',
      thumb: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600&auto=format&fit=crop&q=80',
    }
  ]
}

export const usePlayerStore = defineStore('player', () => {
  const config = useRuntimeConfig()
  const defaultKey = config.public.youtubeApiKey || 'AIzaSyBWoRrWmidw1PfI9dNXLJOWiHRn8E-RYq8'

  // Global player state
  const playlist = ref<Track[]>([...DEFAULT_TRACKS.trending])
  const currentTrack = ref<Track | null>(DEFAULT_TRACKS.trending[0])
  const currentIndex = ref<number>(0)
  const isPlaying = ref<boolean>(false)
  const isReady = ref<boolean>(false)
  const isBuffering = ref<boolean>(false)
  const currentTime = ref<number>(0)
  const duration = ref<number>(0)
  const volume = ref<number>(75)
  const isMuted = ref<boolean>(false)
  const repeatMode = ref<'off' | 'all' | 'one'>('all')
  const isShuffle = ref<boolean>(false)

  // UI state
  const showFullPlayer = ref<boolean>(false)
  const showVideo = ref<boolean>(false)
  const showApiKeyModal = ref<boolean>(false)
  const activeTab = ref<'home' | 'search' | 'library' | 'settings'>('home')
  const toastMessage = ref<string | null>(null)
  const searchQuery = ref<string>('')
  const isSearching = ref<boolean>(false)
  const searchResults = ref<Track[]>([])

  // Stored state
  const apiKey = ref<string>(defaultKey)
  const favorites = ref<Track[]>([])
  const history = ref<Track[]>([])

  // YouTube player internal references
  let ytPlayer: any = null
  let progressTimer: any = null

  // Helpers
  const showToast = (msg: string, dur = 3000) => {
    toastMessage.value = msg
    setTimeout(() => {
      if (toastMessage.value === msg) toastMessage.value = null
    }, dur)
  }

  const formatTime = (secs: number) => {
    if (!secs || isNaN(secs) || secs < 0) return '0:00'
    const s = Math.floor(secs)
    const m = Math.floor(s / 60)
    const remainder = s % 60
    return `${m}:${remainder < 10 ? '0' : ''}${remainder}`
  }

  // Local storage sync
  const initFromStorage = () => {
    if (typeof window === 'undefined') return
    try {
      const storedKey = localStorage.getItem('vibe_yt_api_key')
      if (storedKey) {
        apiKey.value = storedKey
      } else if (defaultKey) {
        apiKey.value = defaultKey
      }

      const storedFavs = localStorage.getItem('vibe_favorites')
      if (storedFavs) favorites.value = JSON.parse(storedFavs)

      const storedHist = localStorage.getItem('vibe_history')
      if (storedHist) history.value = JSON.parse(storedHist)

      const storedVol = localStorage.getItem('vibe_volume')
      if (storedVol) volume.value = Number(storedVol)
    } catch (e) {
      console.warn('Failed to read from localStorage:', e)
    }
  }

  const saveApiKey = (key: string) => {
    apiKey.value = key.trim()
    if (typeof window !== 'undefined') {
      localStorage.setItem('vibe_yt_api_key', apiKey.value)
    }
    showToast('YouTube API key saved successfully!')
    showApiKeyModal.value = false
  }

  const toggleFavorite = (track: Track) => {
    const exists = favorites.value.some(t => t.id === track.id)
    if (exists) {
      favorites.value = favorites.value.filter(t => t.id !== track.id)
      showToast('Removed from Liked Songs')
    } else {
      favorites.value = [track, ...favorites.value]
      showToast('Added to Liked Songs ❤️')
    }
    if (typeof window !== 'undefined') {
      localStorage.setItem('vibe_favorites', JSON.stringify(favorites.value))
    }
  }

  const isFavorite = (trackId: string) => {
    return favorites.value.some(t => t.id === trackId)
  }

  // YouTube API Initialization
  const initYouTube = () => {
    if (typeof window === 'undefined') return

    ;(window as any).onYouTubeIframeAPIReady = () => {
      createYTPlayer()
    }

    if ((window as any).YT && (window as any).YT.Player) {
      createYTPlayer()
    } else {
      const existing = document.getElementById('youtube-iframe-api')
      if (!existing) {
        const tag = document.createElement('script')
        tag.id = 'youtube-iframe-api'
        tag.src = 'https://www.youtube.com/iframe_api'
        document.head.appendChild(tag)
      }
    }
  }

  const createYTPlayer = () => {
    const container = document.getElementById('ytplayer-frame')
    if (!container || ytPlayer) return

    try {
      ytPlayer = new (window as any).YT.Player('ytplayer-frame', {
        height: '100%',
        width: '100%',
        videoId: currentTrack.value?.id || 'jfKfPfyJRdk',
        playerVars: {
          autoplay: 0,
          controls: 0,
          disablekb: 1,
          fs: 0,
          modestbranding: 1,
          playsinline: 1,
          rel: 0,
          origin: window.location.origin
        },
        events: {
          onReady: () => {
            isReady.value = true
            ytPlayer.setVolume(volume.value)
            if (isMuted.value) ytPlayer.mute()
          },
          onStateChange: (event: any) => {
            const YT = (window as any).YT
            if (event.data === YT.PlayerState.PLAYING) {
              isPlaying.value = true
              isBuffering.value = false
              startProgressLoop()
              updateMediaSession()
            } else if (event.data === YT.PlayerState.PAUSED) {
              isPlaying.value = false
              isBuffering.value = false
              stopProgressLoop()
            } else if (event.data === YT.PlayerState.BUFFERING) {
              isBuffering.value = true
            } else if (event.data === YT.PlayerState.ENDED) {
              isPlaying.value = false
              stopProgressLoop()
              handleTrackEnded()
            }
          },
          onError: (e: any) => {
            console.warn('YouTube Player Error:', e.data)
            isBuffering.value = false
            showToast(`Playback error (${e.data}). Skipping to next track...`)
            setTimeout(() => nextTrack(), 1500)
          }
        }
      })
    } catch (err) {
      console.error('Failed to create YouTube Player:', err)
    }
  }

  const startProgressLoop = () => {
    stopProgressLoop()
    progressTimer = setInterval(() => {
      if (ytPlayer && typeof ytPlayer.getCurrentTime === 'function') {
        const cur = ytPlayer.getCurrentTime() || 0
        const dur = ytPlayer.getDuration() || 0
        currentTime.value = cur
        if (dur > 0) duration.value = dur
      }
    }, 500)
  }

  const stopProgressLoop = () => {
    if (progressTimer) {
      clearInterval(progressTimer)
      progressTimer = null
    }
  }

  const updateMediaSession = () => {
    if (typeof navigator !== 'undefined' && 'mediaSession' in navigator && currentTrack.value) {
      navigator.mediaSession.metadata = new MediaMetadata({
        title: currentTrack.value.title,
        artist: currentTrack.value.channel,
        album: 'YouTube Music',
        artwork: [
          { src: currentTrack.value.thumb, sizes: '512x512', type: 'image/jpeg' }
        ]
      })

      navigator.mediaSession.setActionHandler('play', () => togglePlay())
      navigator.mediaSession.setActionHandler('pause', () => togglePlay())
      navigator.mediaSession.setActionHandler('previoustrack', () => prevTrack())
      navigator.mediaSession.setActionHandler('nexttrack', () => nextTrack())
      navigator.mediaSession.setActionHandler('seekto', (details) => {
        if (details.seekTime !== undefined) seekTo(details.seekTime)
      })
    }
  }

  const handleTrackEnded = () => {
    if (repeatMode.value === 'one') {
      seekTo(0)
      playCurrent()
      return
    }

    if (playlist.value.length <= 1 && repeatMode.value === 'off') {
      return
    }

    nextTrack()
  }

  // Playback Controls
  const loadTrack = (track: Track, autoPlay = true, playlistContext?: Track[]) => {
    if (playlistContext) {
      playlist.value = [...playlistContext]
    }
    const idx = playlist.value.findIndex(t => t.id === track.id)
    currentIndex.value = idx !== -1 ? idx : 0
    currentTrack.value = track
    currentTime.value = 0
    duration.value = 0

    // Add to history
    history.value = [track, ...history.value.filter(t => t.id !== track.id)].slice(0, 50)
    if (typeof window !== 'undefined') {
      localStorage.setItem('vibe_history', JSON.stringify(history.value))
    }

    if (ytPlayer && typeof ytPlayer.loadVideoById === 'function') {
      if (autoPlay) {
        ytPlayer.loadVideoById(track.id, 0)
        isPlaying.value = true
      } else {
        ytPlayer.cueVideoById(track.id, 0)
      }
    }
  }

  const playCurrent = () => {
    if (ytPlayer && typeof ytPlayer.playVideo === 'function') {
      ytPlayer.playVideo()
      isPlaying.value = true
    }
  }

  const pauseCurrent = () => {
    if (ytPlayer && typeof ytPlayer.pauseVideo === 'function') {
      ytPlayer.pauseVideo()
      isPlaying.value = false
    }
  }

  const togglePlay = () => {
    if (!currentTrack.value && playlist.value.length) {
      loadTrack(playlist.value[0], true)
      return
    }
    if (isPlaying.value) {
      pauseCurrent()
    } else {
      playCurrent()
    }
  }

  const nextTrack = () => {
    if (!playlist.value.length) return

    let nextIdx: number
    if (isShuffle.value) {
      nextIdx = Math.floor(Math.random() * playlist.value.length)
      if (nextIdx === currentIndex.value && playlist.value.length > 1) {
        nextIdx = (nextIdx + 1) % playlist.value.length
      }
    } else {
      if (currentIndex.value >= playlist.value.length - 1 && repeatMode.value === 'off') {
        return
      }
      nextIdx = (currentIndex.value + 1) % playlist.value.length
    }

    loadTrack(playlist.value[nextIdx], true)
  }

  const prevTrack = () => {
    if (!playlist.value.length) return
    if (currentTime.value > 3) {
      seekTo(0)
      return
    }
    const prevIdx = (currentIndex.value - 1 + playlist.value.length) % playlist.value.length
    loadTrack(playlist.value[prevIdx], true)
  }

  const seekTo = (seconds: number) => {
    if (ytPlayer && typeof ytPlayer.seekTo === 'function') {
      ytPlayer.seekTo(seconds, true)
      currentTime.value = seconds
    }
  }

  const setPlayerVolume = (val: number) => {
    volume.value = Math.max(0, Math.min(100, val))
    if (ytPlayer && typeof ytPlayer.setVolume === 'function') {
      ytPlayer.setVolume(volume.value)
    }
    if (isMuted.value && volume.value > 0) {
      isMuted.value = false
      if (ytPlayer) ytPlayer.unMute()
    }
    if (typeof window !== 'undefined') {
      localStorage.setItem('vibe_volume', String(volume.value))
    }
  }

  const toggleMute = () => {
    isMuted.value = !isMuted.value
    if (ytPlayer) {
      if (isMuted.value) ytPlayer.mute()
      else ytPlayer.unMute()
    }
  }

  const toggleShuffle = () => {
    isShuffle.value = !isShuffle.value
    showToast(isShuffle.value ? 'Shuffle turned on' : 'Shuffle turned off')
  }

  const toggleRepeat = () => {
    if (repeatMode.value === 'all') {
      repeatMode.value = 'one'
      showToast('Repeat one track')
    } else if (repeatMode.value === 'one') {
      repeatMode.value = 'off'
      showToast('Repeat off')
    } else {
      repeatMode.value = 'all'
      showToast('Repeat playlist')
    }
  }

  // YouTube API Search
  const searchYouTube = async (query: string) => {
    const q = query.trim()
    if (!q) return

    const key = apiKey.value || defaultKey
    if (!key) {
      showToast('Please add your YouTube API Key to search live YouTube songs!')
      showApiKeyModal.value = true
      return
    }

    isSearching.value = true
    try {
      const url = new URL('https://www.googleapis.com/youtube/v3/search')
      url.searchParams.set('part', 'snippet')
      url.searchParams.set('q', `${q} audio`)
      url.searchParams.set('type', 'video')
      url.searchParams.set('videoCategoryId', '10') // Music category
      url.searchParams.set('maxResults', '25')
      url.searchParams.set('key', key)

      const res = await fetch(url.toString())
      const data = await res.json()

      if (data.error) {
        throw new Error(data.error.message || 'YouTube API error')
      }

      if (!data.items || !data.items.length) {
        searchResults.value = []
        showToast('No tracks found. Try a different query.')
        return
      }

      const results: Track[] = data.items.map((item: any) => ({
        id: item.id.videoId,
        title: item.snippet.title.replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'"),
        channel: item.snippet.channelTitle,
        thumb: item.snippet.thumbnails?.high?.url || item.snippet.thumbnails?.medium?.url || item.snippet.thumbnails?.default?.url
      }))

      searchResults.value = results
      showToast(`Found ${results.length} tracks for "${q}"`)
    } catch (err: any) {
      console.error('Search error:', err)
      showToast(`Search failed: ${err.message || 'Check API key or network'}`)
    } finally {
      isSearching.value = false
    }
  }

  const loadCategory = (catKey: string) => {
    if (DEFAULT_TRACKS[catKey]) {
      playlist.value = [...DEFAULT_TRACKS[catKey]]
      loadTrack(playlist.value[0], true)
      showToast(`Loaded ${catKey.toUpperCase()} playlist`)
    }
  }

  return {
    playlist,
    currentTrack,
    currentIndex,
    isPlaying,
    isReady,
    isBuffering,
    currentTime,
    duration,
    volume,
    isMuted,
    repeatMode,
    isShuffle,
    showFullPlayer,
    showVideo,
    showApiKeyModal,
    activeTab,
    toastMessage,
    searchQuery,
    isSearching,
    searchResults,
    apiKey,
    favorites,
    history,
    formatTime,
    showToast,
    initFromStorage,
    saveApiKey,
    toggleFavorite,
    isFavorite,
    initYouTube,
    loadTrack,
    playCurrent,
    pauseCurrent,
    togglePlay,
    nextTrack,
    prevTrack,
    seekTo,
    setPlayerVolume,
    toggleMute,
    toggleShuffle,
    toggleRepeat,
    searchYouTube,
    loadCategory
  }
})
