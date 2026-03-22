import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext.jsx'
import { FilmIcon, TicketIcon, UserIcon, Cog6ToothIcon } from '@heroicons/react/24/outline'

export default function Navbar() {
  const { user, logoutUser, isAdmin } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logoutUser()
    navigate('/')
  }

  return (
    <nav className="bg-gray-900 border-b border-gray-800 sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <Link to="/" className="flex items-center gap-2 text-xl font-bold text-brand-500 hover:text-brand-400">
            <FilmIcon className="w-7 h-7" />
            CineBook
          </Link>

          <div className="flex items-center gap-4">
            <Link to="/" className="text-gray-300 hover:text-white text-sm transition-colors">
              Movies
            </Link>

            {user ? (
              <>
                <Link to="/bookings" className="flex items-center gap-1 text-gray-300 hover:text-white text-sm transition-colors">
                  <TicketIcon className="w-4 h-4" />
                  My Bookings
                </Link>
                {isAdmin && (
                  <Link to="/admin" className="flex items-center gap-1 text-yellow-400 hover:text-yellow-300 text-sm transition-colors">
                    <Cog6ToothIcon className="w-4 h-4" />
                    Admin
                  </Link>
                )}
                <div className="flex items-center gap-2 text-gray-400 text-sm">
                  <UserIcon className="w-4 h-4" />
                  {user.username}
                </div>
                <button onClick={handleLogout} className="btn-secondary text-sm py-1.5 px-4">
                  Logout
                </button>
              </>
            ) : (
              <>
                <Link to="/login" className="text-gray-300 hover:text-white text-sm transition-colors">
                  Login
                </Link>
                <Link to="/signup" className="btn-primary text-sm py-1.5 px-4">
                  Sign Up
                </Link>
              </>
            )}
          </div>
        </div>
      </div>
    </nav>
  )
}
