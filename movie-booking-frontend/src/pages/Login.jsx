import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { login } from '../api/index.js'
import { useAuth } from '../context/AuthContext.jsx'
import toast from 'react-hot-toast'
import { FilmIcon } from '@heroicons/react/24/outline'

export default function Login() {
  const [form, setForm] = useState({ username: '', password: '' })
  const [loading, setLoading] = useState(false)
  const { loginUser } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      const res = await login(form)
      loginUser(res.data)
      toast.success(`Welcome back, ${res.data.username}!`)
      navigate('/')
    } catch (err) {
      toast.error(err.response?.data?.message || 'Invalid username or password')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-[80vh] flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <FilmIcon className="w-12 h-12 text-brand-500 mx-auto mb-3" />
          <h1 className="text-3xl font-bold text-white">Welcome back</h1>
          <p className="text-gray-400 mt-1">Sign in to your CineBook account</p>
        </div>

        <div className="card p-8">
          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1.5">Username or Email</label>
              <input
                type="text"
                className="input-field"
                placeholder="Enter your username"
                value={form.username}
                onChange={(e) => setForm({ ...form, username: e.target.value })}
                required
                autoComplete="username"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1.5">Password</label>
              <input
                type="password"
                className="input-field"
                placeholder="Enter your password"
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
                required
                autoComplete="current-password"
              />
            </div>

            <button type="submit" className="btn-primary w-full py-3" disabled={loading}>
              {loading ? 'Signing in…' : 'Sign In'}
            </button>
          </form>

          <p className="text-center text-gray-400 text-sm mt-6">
            Don&apos;t have an account?{' '}
            <Link to="/signup" className="text-brand-400 hover:text-brand-300 font-medium">
              Sign up
            </Link>
          </p>
        </div>

        <p className="text-center text-xs text-gray-600 mt-4">
          Demo: <code className="bg-gray-800 px-1 rounded">admin / Admin@1234</code> or{' '}
          <code className="bg-gray-800 px-1 rounded">john / User@1234</code>
        </p>
      </div>
    </div>
  )
}
