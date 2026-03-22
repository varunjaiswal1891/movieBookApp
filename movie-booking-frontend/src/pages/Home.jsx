import { useEffect, useState } from 'react'
import { getMovies, getGenres } from '../api/index.js'
import MovieCard from '../components/MovieCard.jsx'
import AIRecommendations from '../components/AIRecommendations.jsx'
import { useAuth } from '../context/AuthContext.jsx'
import { MagnifyingGlassIcon, FilmIcon } from '@heroicons/react/24/outline'

export default function Home() {
  const [movies, setMovies] = useState([])
  const [genres, setGenres] = useState([])
  const [selectedGenre, setSelectedGenre] = useState('')
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const { user } = useAuth()

  useEffect(() => {
    getGenres().then((res) => setGenres(Array.isArray(res?.data) ? res.data : [])).catch(() => {})
  }, [])

  useEffect(() => {
    setLoading(true)
    const params = {}
    if (search.trim()) params.search = search.trim()
    else if (selectedGenre) params.genre = selectedGenre

    getMovies(params)
      .then((res) => setMovies(Array.isArray(res?.data) ? res.data : []))
      .catch(() => setMovies([]))
      .finally(() => setLoading(false))
  }, [search, selectedGenre])

  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-br from-gray-900 via-gray-900 to-brand-900/20 py-16 px-4">
        <div className="max-w-7xl mx-auto text-center">
          <h1 className="text-4xl sm:text-5xl font-extrabold text-white mb-4">
            Book Your <span className="text-brand-500">Perfect Seat</span>
          </h1>
          <p className="text-gray-400 text-lg mb-8">Browse the latest movies and grab your tickets in seconds</p>

          <div className="max-w-xl mx-auto relative">
            <MagnifyingGlassIcon className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="search"
              className="input-field pl-11 py-3 text-base"
              placeholder="Search movies by title or genre…"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setSelectedGenre('') }}
            />
          </div>
        </div>
      </section>

      {/* AI Recommendations (logged-in users only) */}
      {user && <AIRecommendations />}

      {/* Genre Filter */}
      <section className="py-6 px-4 max-w-7xl mx-auto">
        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => { setSelectedGenre(''); setSearch('') }}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${
              !selectedGenre && !search ? 'bg-brand-600 text-white' : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
            }`}
          >
            All
          </button>
          {(Array.isArray(genres) ? genres : []).map((g) => (
            <button
              key={g}
              onClick={() => { setSelectedGenre(g); setSearch('') }}
              className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${
                selectedGenre === g ? 'bg-brand-600 text-white' : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
              }`}
            >
              {g}
            </button>
          ))}
        </div>
      </section>

      {/* Movie Grid */}
      <section className="pb-16 px-4 max-w-7xl mx-auto">
        {loading ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {Array.from({ length: 10 }).map((_, i) => (
              <div key={i} className="card animate-pulse aspect-[2/3] bg-gray-800" />
            ))}
          </div>
        ) : !Array.isArray(movies) || movies.length === 0 ? (
          <div className="text-center py-24 text-gray-500">
            <FilmIcon className="w-16 h-16 mx-auto mb-4 opacity-30" />
            <p className="text-lg">No movies found</p>
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {(Array.isArray(movies) ? movies : []).map((movie) => (
              <MovieCard key={movie.id} movie={movie} />
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
