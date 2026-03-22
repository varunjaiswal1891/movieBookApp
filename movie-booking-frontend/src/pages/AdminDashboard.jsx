import { useState } from 'react'
import { adminCreateMovie, adminDeleteMovie, adminCreateShow, adminDeleteShow } from '../api/index.js'
import toast from 'react-hot-toast'
import { Cog6ToothIcon, PlusIcon, TrashIcon, FilmIcon, TicketIcon } from '@heroicons/react/24/outline'

const INITIAL_MOVIE = {
  title: '', genre: '', director: '', castMembers: '', description: '',
  durationMinutes: '', releaseYear: new Date().getFullYear(), rating: '',
}

const INITIAL_SHOW = {
  movieId: '', venue: '', screen: '', showTime: '', totalSeats: 50, ticketPrice: 12.99,
}

export default function AdminDashboard() {
  const [tab, setTab] = useState('movie')
  const [movieForm, setMovieForm] = useState(INITIAL_MOVIE)
  const [showForm, setShowForm] = useState(INITIAL_SHOW)
  const [poster, setPoster] = useState(null)
  const [loading, setLoading] = useState(false)

  const handleCreateMovie = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      const fd = new FormData()
      fd.append('movie', new Blob([JSON.stringify({
        ...movieForm,
        durationMinutes: Number(movieForm.durationMinutes) || null,
        releaseYear: Number(movieForm.releaseYear),
        rating: movieForm.rating ? Number(movieForm.rating) : null,
        active: true,
      })], { type: 'application/json' }))
      if (poster) fd.append('poster', poster)
      await adminCreateMovie(fd)
      toast.success('Movie created!')
      setMovieForm(INITIAL_MOVIE)
      setPoster(null)
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to create movie')
    } finally {
      setLoading(false)
    }
  }

  const handleCreateShow = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      await adminCreateShow({
        movie: { id: Number(showForm.movieId) },
        venue: showForm.venue,
        screen: showForm.screen,
        showTime: showForm.showTime,
        totalSeats: Number(showForm.totalSeats),
        ticketPrice: Number(showForm.ticketPrice),
        active: true,
      })
      toast.success('Show created!')
      setShowForm(INITIAL_SHOW)
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to create show')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      <h1 className="text-3xl font-bold text-white mb-8 flex items-center gap-2">
        <Cog6ToothIcon className="w-8 h-8 text-yellow-400" />
        Admin Dashboard
      </h1>

      {/* Tabs */}
      <div className="flex gap-2 mb-8">
        {[{ id: 'movie', label: 'Add Movie', icon: FilmIcon },
          { id: 'show', label: 'Add Show', icon: TicketIcon }].map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            onClick={() => setTab(id)}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-lg font-medium text-sm transition-colors ${
              tab === id ? 'bg-brand-600 text-white' : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
            }`}
          >
            <Icon className="w-4 h-4" />
            {label}
          </button>
        ))}
      </div>

      {/* Add Movie Form */}
      {tab === 'movie' && (
        <div className="card p-6">
          <h2 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
            <PlusIcon className="w-5 h-5 text-brand-500" />
            Add New Movie
          </h2>
          <form onSubmit={handleCreateMovie} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2">
                <label className="block text-sm text-gray-400 mb-1">Title *</label>
                <input className="input-field" required value={movieForm.title}
                  onChange={(e) => setMovieForm({ ...movieForm, title: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Genre *</label>
                <input className="input-field" required value={movieForm.genre}
                  onChange={(e) => setMovieForm({ ...movieForm, genre: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Director</label>
                <input className="input-field" value={movieForm.director}
                  onChange={(e) => setMovieForm({ ...movieForm, director: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Duration (min)</label>
                <input type="number" className="input-field" value={movieForm.durationMinutes}
                  onChange={(e) => setMovieForm({ ...movieForm, durationMinutes: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Release Year *</label>
                <input type="number" className="input-field" required value={movieForm.releaseYear}
                  onChange={(e) => setMovieForm({ ...movieForm, releaseYear: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Rating (0–5)</label>
                <input type="number" step="0.1" min="0" max="5" className="input-field" value={movieForm.rating}
                  onChange={(e) => setMovieForm({ ...movieForm, rating: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Poster Image</label>
                <input type="file" accept="image/*" className="input-field text-sm"
                  onChange={(e) => setPoster(e.target.files[0])} />
              </div>
              <div className="col-span-2">
                <label className="block text-sm text-gray-400 mb-1">Cast</label>
                <input className="input-field" value={movieForm.castMembers}
                  onChange={(e) => setMovieForm({ ...movieForm, castMembers: e.target.value })} />
              </div>
              <div className="col-span-2">
                <label className="block text-sm text-gray-400 mb-1">Description</label>
                <textarea rows={3} className="input-field" value={movieForm.description}
                  onChange={(e) => setMovieForm({ ...movieForm, description: e.target.value })} />
              </div>
            </div>
            <button type="submit" className="btn-primary w-full py-3" disabled={loading}>
              {loading ? 'Creating…' : 'Create Movie'}
            </button>
          </form>
        </div>
      )}

      {/* Add Show Form */}
      {tab === 'show' && (
        <div className="card p-6">
          <h2 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
            <PlusIcon className="w-5 h-5 text-brand-500" />
            Add New Show
          </h2>
          <form onSubmit={handleCreateShow} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-gray-400 mb-1">Movie ID *</label>
                <input type="number" className="input-field" required value={showForm.movieId}
                  onChange={(e) => setShowForm({ ...showForm, movieId: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Venue *</label>
                <input className="input-field" required value={showForm.venue}
                  onChange={(e) => setShowForm({ ...showForm, venue: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Screen *</label>
                <input className="input-field" required value={showForm.screen}
                  onChange={(e) => setShowForm({ ...showForm, screen: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Show Time *</label>
                <input type="datetime-local" className="input-field" required value={showForm.showTime}
                  onChange={(e) => setShowForm({ ...showForm, showTime: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Total Seats</label>
                <input type="number" className="input-field" value={showForm.totalSeats}
                  onChange={(e) => setShowForm({ ...showForm, totalSeats: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">Ticket Price ($)</label>
                <input type="number" step="0.01" className="input-field" value={showForm.ticketPrice}
                  onChange={(e) => setShowForm({ ...showForm, ticketPrice: e.target.value })} />
              </div>
            </div>
            <button type="submit" className="btn-primary w-full py-3" disabled={loading}>
              {loading ? 'Creating…' : 'Create Show'}
            </button>
          </form>
        </div>
      )}
    </div>
  )
}
