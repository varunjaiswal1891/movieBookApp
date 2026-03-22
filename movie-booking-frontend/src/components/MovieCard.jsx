import { Link } from 'react-router-dom'
import { StarIcon, ClockIcon } from '@heroicons/react/24/solid'

export default function MovieCard({ movie }) {
  return (
    <Link to={`/movies/${movie.id}`} className="card group hover:border-brand-600 transition-colors duration-200 block">
      <div className="aspect-[2/3] bg-gray-800 relative overflow-hidden">
        {movie.posterUrl ? (
          <img
            src={movie.posterUrl}
            alt={movie.title}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-gray-600 text-4xl">🎬</div>
        )}
        <div className="absolute top-2 right-2 bg-black/70 rounded-full px-2 py-0.5 flex items-center gap-1 text-xs text-yellow-400">
          <StarIcon className="w-3 h-3" />
          {movie.rating ? movie.rating.toFixed(1) : 'N/A'}
        </div>
      </div>
      <div className="p-4">
        <h3 className="font-bold text-white truncate">{movie.title}</h3>
        <div className="flex items-center justify-between mt-1">
          <span className="text-xs text-brand-400 bg-brand-900/30 px-2 py-0.5 rounded-full">{movie.genre}</span>
          {movie.durationMinutes && (
            <span className="flex items-center gap-1 text-xs text-gray-500">
              <ClockIcon className="w-3 h-3" />
              {movie.durationMinutes}m
            </span>
          )}
        </div>
        {movie.description && (
          <p className="text-xs text-gray-500 mt-2 line-clamp-2">{movie.description}</p>
        )}
      </div>
    </Link>
  )
}
