import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { getRecommendations } from '../api/index.js'
import { SparklesIcon, StarIcon } from '@heroicons/react/24/solid'

export default function AIRecommendations() {
  const [recommendations, setRecommendations] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getRecommendations()
      .then((res) => setRecommendations(res.data))
      .catch(() => setRecommendations([]))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return null
  if (recommendations.length === 0) return null

  return (
    <section className="py-10 px-4 max-w-7xl mx-auto">
      <div className="flex items-center gap-2 mb-6">
        <SparklesIcon className="w-6 h-6 text-yellow-400" />
        <h2 className="text-xl font-bold text-white">AI Picks For You</h2>
        <span className="text-xs bg-yellow-400/10 text-yellow-400 border border-yellow-400/20 px-2 py-0.5 rounded-full">
          Personalised
        </span>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        {recommendations.map((rec) => (
          <Link
            key={rec.movieId}
            to={`/movies/${rec.movieId}`}
            className="card hover:border-yellow-500/50 transition-colors group block"
          >
            <div className="p-3">
              <div className="text-2xl mb-2 text-center">🎬</div>
              <h3 className="text-sm font-semibold text-white truncate">{rec.title}</h3>
              <p className="text-xs text-brand-400 mt-0.5">{rec.genre}</p>
              {rec.rating && (
                <div className="flex items-center gap-1 text-xs text-yellow-400 mt-1">
                  <StarIcon className="w-3 h-3" />
                  {rec.rating.toFixed(1)}
                </div>
              )}
              <p className="text-xs text-gray-500 mt-2 line-clamp-2 italic">{rec.reason}</p>
            </div>
          </Link>
        ))}
      </div>
    </section>
  )
}
