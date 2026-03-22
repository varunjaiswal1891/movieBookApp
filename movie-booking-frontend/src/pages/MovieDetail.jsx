import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { getMovie, getMovieShows } from '../api/index.js'
import { format } from 'date-fns'
import { StarIcon, ClockIcon, CalendarIcon, MapPinIcon, TicketIcon } from '@heroicons/react/24/outline'
import { useAuth } from '../context/AuthContext.jsx'
import toast from 'react-hot-toast'

export default function MovieDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const [movie, setMovie] = useState(null)
  const [shows, setShows] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([getMovie(id), getMovieShows(id)])
      .then(([movieRes, showsRes]) => {
        setMovie(movieRes.data)
        setShows(showsRes.data)
      })
      .catch(() => navigate('/'))
      .finally(() => setLoading(false))
  }, [id, navigate])

  const handleBookShow = (show) => {
    if (!user) {
      toast.error('Please log in to book tickets')
      navigate('/login')
      return
    }
    navigate(`/shows/${show.id}/seats`, { state: { show, movie } })
  }

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-12">
        <div className="animate-pulse space-y-4">
          <div className="h-64 bg-gray-800 rounded-xl" />
          <div className="h-8 bg-gray-800 rounded w-1/3" />
        </div>
      </div>
    )
  }

  if (!movie) return null

  return (
    <div className="max-w-7xl mx-auto px-4 py-10">
      {/* Movie Header */}
      <div className="flex flex-col md:flex-row gap-8 mb-12">
        <div className="w-full md:w-64 flex-shrink-0">
          <div className="card aspect-[2/3] flex items-center justify-center text-6xl bg-gray-800">
            {movie.posterKey ? (
              <img src={`/api/movies/${movie.id}/poster-url`} alt={movie.title} className="w-full h-full object-cover rounded-xl" />
            ) : '🎬'}
          </div>
        </div>

        <div className="flex-1">
          <h1 className="text-4xl font-extrabold text-white mb-2">{movie.title}</h1>
          <div className="flex flex-wrap gap-3 mb-4">
            <span className="bg-brand-600/20 text-brand-400 border border-brand-600/30 px-3 py-1 rounded-full text-sm">
              {movie.genre}
            </span>
            {movie.rating && (
              <span className="flex items-center gap-1 bg-yellow-500/10 text-yellow-400 border border-yellow-500/20 px-3 py-1 rounded-full text-sm">
                <StarIcon className="w-4 h-4" />
                {movie.rating.toFixed(1)} / 5
              </span>
            )}
            {movie.durationMinutes && (
              <span className="flex items-center gap-1 text-gray-400 text-sm">
                <ClockIcon className="w-4 h-4" />
                {movie.durationMinutes} min
              </span>
            )}
          </div>
          {movie.description && <p className="text-gray-300 mb-4 leading-relaxed">{movie.description}</p>}
          <div className="grid grid-cols-2 gap-2 text-sm text-gray-400">
            {movie.director && <div><span className="text-gray-500">Director: </span>{movie.director}</div>}
            {movie.releaseYear && <div><span className="text-gray-500">Year: </span>{movie.releaseYear}</div>}
            {movie.castMembers && <div className="col-span-2"><span className="text-gray-500">Cast: </span>{movie.castMembers}</div>}
          </div>
        </div>
      </div>

      {/* Shows */}
      <section>
        <h2 className="text-2xl font-bold text-white mb-6 flex items-center gap-2">
          <TicketIcon className="w-6 h-6 text-brand-500" />
          Available Shows
        </h2>

        {shows.length === 0 ? (
          <div className="card p-12 text-center text-gray-500">
            <TicketIcon className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p>No upcoming shows available</p>
          </div>
        ) : (
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {shows.map((show) => (
              <div key={show.id} className="card p-5 hover:border-brand-600/50 transition-colors">
                <div className="flex items-center gap-2 text-gray-400 text-sm mb-1">
                  <CalendarIcon className="w-4 h-4" />
                  {format(new Date(show.showTime), 'EEE, MMM d · h:mm a')}
                </div>
                <div className="flex items-center gap-2 text-gray-400 text-sm mb-3">
                  <MapPinIcon className="w-4 h-4" />
                  {show.venue} · {show.screen}
                </div>
                <div className="flex items-center justify-between">
                  <div>
                    <span className="text-white font-bold text-lg">${show.ticketPrice}</span>
                    <span className="text-gray-500 text-xs ml-2">
                      {show.availableSeats} seats left
                    </span>
                  </div>
                  <button
                    onClick={() => handleBookShow(show)}
                    disabled={show.availableSeats === 0}
                    className="btn-primary py-1.5 px-4 text-sm"
                  >
                    {show.availableSeats === 0 ? 'Sold Out' : 'Book Now'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
