import { useEffect, useState } from 'react'
import { getMyBookings, cancelBooking } from '../api/index.js'
import { format } from 'date-fns'
import toast from 'react-hot-toast'
import { TicketIcon, CheckCircleIcon, XCircleIcon } from '@heroicons/react/24/outline'

export default function BookingHistory() {
  const [bookings, setBookings] = useState([])
  const [loading, setLoading] = useState(true)
  const [cancelling, setCancelling] = useState(null)

  const load = () => {
    setLoading(true)
    getMyBookings()
      .then((res) => setBookings(res.data))
      .catch(() => toast.error('Failed to load bookings'))
      .finally(() => setLoading(false))
  }

  useEffect(load, [])

  const handleCancel = async (id) => {
    if (!confirm('Cancel this booking?')) return
    setCancelling(id)
    try {
      await cancelBooking(id)
      toast.success('Booking cancelled')
      load()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Cancellation failed')
    } finally {
      setCancelling(null)
    }
  }

  if (loading) {
    return (
      <div className="max-w-3xl mx-auto px-4 py-12 space-y-4">
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="card animate-pulse h-28" />
        ))}
      </div>
    )
  }

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      <h1 className="text-3xl font-bold text-white mb-8 flex items-center gap-2">
        <TicketIcon className="w-8 h-8 text-brand-500" />
        My Bookings
      </h1>

      {bookings.length === 0 ? (
        <div className="card p-16 text-center text-gray-500">
          <TicketIcon className="w-16 h-16 mx-auto mb-4 opacity-30" />
          <p className="text-lg">No bookings yet</p>
          <a href="/" className="text-brand-400 hover:text-brand-300 text-sm mt-2 block">Browse movies →</a>
        </div>
      ) : (
        <div className="space-y-4">
          {bookings.map((booking) => (
            <div key={booking.id} className={`card p-5 border-l-4 ${
              booking.status === 'CONFIRMED' ? 'border-l-green-500' : 'border-l-red-500/50'
            }`}>
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="font-bold text-white">{booking.show?.movie?.title || 'Movie'}</h3>
                    {booking.status === 'CONFIRMED' ? (
                      <span className="flex items-center gap-1 text-xs text-green-400">
                        <CheckCircleIcon className="w-3.5 h-3.5" /> Confirmed
                      </span>
                    ) : (
                      <span className="flex items-center gap-1 text-xs text-red-400">
                        <XCircleIcon className="w-3.5 h-3.5" /> Cancelled
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-gray-400">
                    {booking.show?.showTime
                      ? format(new Date(booking.show.showTime), 'EEE, MMM d yyyy · h:mm a')
                      : '—'}
                  </p>
                  <p className="text-sm text-gray-400 mt-0.5">
                    {booking.show?.venue} · {booking.show?.screen}
                  </p>
                  <div className="flex flex-wrap gap-2 mt-2">
                    <span className="text-xs bg-gray-800 px-2 py-0.5 rounded text-gray-300">
                      Seats: {booking.seatNumbers?.join(', ')}
                    </span>
                    <span className="text-xs bg-gray-800 px-2 py-0.5 rounded text-brand-400">
                      ${booking.totalAmount?.toFixed(2)}
                    </span>
                    <span className="text-xs bg-gray-800 px-2 py-0.5 rounded text-gray-500 font-mono">
                      {booking.confirmationCode}
                    </span>
                  </div>
                </div>

                {booking.status === 'CONFIRMED' && (
                  <button
                    onClick={() => handleCancel(booking.id)}
                    disabled={cancelling === booking.id}
                    className="text-red-400 hover:text-red-300 text-sm border border-red-500/30 hover:border-red-400/50 px-3 py-1.5 rounded-lg transition-colors disabled:opacity-50"
                  >
                    {cancelling === booking.id ? '…' : 'Cancel'}
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
