import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: 15000,
})

// Attach JWT on every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle 401 – clear session and redirect to login
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

// ── Auth ─────────────────────────────────────────────────────────────────────
export const signup = (data) => api.post('/auth/signup', data)
export const login  = (data) => api.post('/auth/login', data)

// ── Movies ───────────────────────────────────────────────────────────────────
export const getMovies        = (params) => api.get('/movies', { params })
export const getMovie         = (id)     => api.get(`/movies/${id}`)
export const getMovieShows    = (id)     => api.get(`/movies/${id}/shows`)
export const getGenres        = ()       => api.get('/movies/genres')
export const getPosterUrl     = (id)     => api.get(`/movies/${id}/poster-url`)

// ── Shows & Seats ─────────────────────────────────────────────────────────────
export const getShow      = (id) => api.get(`/shows/${id}`)
export const getSeats     = (id) => api.get(`/shows/${id}/seats`)

// ── Bookings ──────────────────────────────────────────────────────────────────
export const getMyBookings   = ()       => api.get('/bookings/my')
export const createBooking   = (data)   => api.post('/bookings', data)
export const cancelBooking   = (id)     => api.delete(`/bookings/${id}/cancel`)

// ── AI ────────────────────────────────────────────────────────────────────────
export const getRecommendations = () => api.get('/ai/recommendations')

// ── Admin ─────────────────────────────────────────────────────────────────────
export const adminCreateMovie  = (formData) => api.post('/admin/movies', formData, { headers: { 'Content-Type': 'multipart/form-data' } })
export const adminUpdateMovie  = (id, fd)   => api.put(`/admin/movies/${id}`, fd, { headers: { 'Content-Type': 'multipart/form-data' } })
export const adminDeleteMovie  = (id)       => api.delete(`/admin/movies/${id}`)
export const adminCreateShow   = (data)     => api.post('/admin/shows', data)
export const adminDeleteShow   = (id)       => api.delete(`/admin/shows/${id}`)
