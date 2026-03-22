import { useEffect, useState } from 'react'
import { useParams, useLocation, useNavigate } from 'react-router-dom'
import { getSeats, getShow, createBooking } from '../api/index.js'
import SeatGrid from '../components/SeatGrid.jsx'
import { format } from 'date-fns'
import toast from 'react-hot-toast'
import { MapPinIcon, CalendarIcon, TicketIcon } from '@heroicons/react/24/outline'

export default function SeatSelection() {
  const { showId } = useParams()
  const location = useLocation()
  const navigate = useNavigate()

  const [show, setShow] = useState(location.state?.show || null)
  const [movie, setMovie] = useState(location.state?.movie || null)
  const [seats, setSeats] = useState([])
  const [selectedSeats, setSelectedSeats] = useState([])
  const [loading, setLoading] = useState(true)
  const [booking, setBooking] = useState(false)

  useEffect(() => {
    const loadData = async () => {
      try {
        const [seatsRes, showRes] = await Promise.all([
          getSeats(showId),
          show ? Promise.resolve({ data: show }) : getShow(showId),
        ])
        setSeats(seatsRes.data)
        setShow(showRes.data)
      } catch {
        toast.error('Failed to load seat layout')
        navigate(-1)
      } finally {
        setLoading(false)
      }
    }
    loadData()
  }, [showId, navigate, show])

  const toggleSeat = (seatNumber) => {
    setSelectedSeats((prev) =>
      prev.includes(seatNumber)
        ? prev.filter((s) => s !== seatNumber)
        : prev.length < 5
        ? [...prev, seatNumber]
        : (toast.error('Maximum 5 seats per booking'), prev)
    )
  }

  const handleConfirmBooking = async () => {
    if (selectedSeats.length === 0) {
      toast.error('Please select at least one seat')
      return
    }
    setBooking(true)
    try {
      const res = await createBooking({ showId: Number(showId), seatNumbers: selectedSeats })
      toast.success(`Booking confirmed! Code: ${res.data.confirmationCode}`)
      navigate('/bookings')
    } catch (err) {
      toast.error(err.response?.data?.message || 'Booking failed')
    } finally {
      setBooking(false)
    }
  }

  if (loading) {
    return (
      <div className="max-w-3xl mx-auto px-4 py-12">
        <div className="animate-pulse h-64 bg-gray-800 rounded-xl" />
      </div>
    )
  }

  const total = selectedSeats.length * (show?.ticketPrice || 0)

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      <h1 className="text-3xl font-bold text-white mb-2">{movie?.title || 'Select Seats'}</h1>

      {show && (
        <div className="flex flex-wrap gap-4 text-sm text-gray-400 mb-8">
          <span className="flex items-center gap-1">
            <CalendarIcon className="w-4 h-4" />
            {format(new Date(show.showTime), 'EEE, MMM d · h:mm a')}
          </span>
          <span className="flex items-center gap-1">
            <MapPinIcon className="w-4 h-4" />
            {show.venue} · {show.screen}
          </span>
          <span className="text-brand-400 font-medium">${show.ticketPrice}/seat</span>
        </div>
      )}

      <div className="card p-6 mb-6">
        <SeatGrid
          seats={seats}
          selectedSeats={selectedSeats}
          onToggle={toggleSeat}
          maxSeats={5}
        />
      </div>

      {/* Booking Summary */}
      <div className="card p-5 flex items-center justify-between">
        <div>
          <p className="text-gray-400 text-sm">
            {selectedSeats.length === 0
              ? 'Select up to 5 seats'
              : `Seats: ${selectedSeats.join(', ')}`}
          </p>
          {selectedSeats.length > 0 && (
            <p className="text-white font-bold text-xl mt-0.5">
              Total: ${total.toFixed(2)}
            </p>
          )}
        </div>
        <button
          onClick={handleConfirmBooking}
          disabled={selectedSeats.length === 0 || booking}
          className="btn-primary flex items-center gap-2 py-3 px-6"
        >
          <TicketIcon className="w-5 h-5" />
          {booking ? 'Booking…' : `Confirm ${selectedSeats.length > 0 ? `(${selectedSeats.length})` : ''}`}
        </button>
      </div>
    </div>
  )
}
