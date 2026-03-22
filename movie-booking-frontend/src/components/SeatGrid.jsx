export default function SeatGrid({ seats, selectedSeats, onToggle, maxSeats = 5 }) {
  const grouped = seats.reduce((acc, seat) => {
    const row = seat.seatNumber[0]
    if (!acc[row]) acc[row] = []
    acc[row].push(seat)
    return acc
  }, {})

  const getStyle = (seat) => {
    if (seat.status === 'BOOKED') return 'bg-red-900/60 border-red-700 cursor-not-allowed text-red-400'
    if (selectedSeats.includes(seat.seatNumber)) return 'bg-brand-600 border-brand-500 text-white cursor-pointer'
    return 'bg-gray-800 border-gray-600 text-gray-300 hover:border-brand-500 hover:bg-gray-700 cursor-pointer'
  }

  const handleClick = (seat) => {
    if (seat.status === 'BOOKED') return
    onToggle(seat.seatNumber)
  }

  return (
    <div className="space-y-2">
      <div className="flex justify-center mb-6">
        <div className="bg-gray-700 text-gray-400 text-xs px-16 py-2 rounded-t-full text-center">SCREEN</div>
      </div>

      {Object.entries(grouped).map(([row, rowSeats]) => (
        <div key={row} className="flex items-center gap-2">
          <span className="w-6 text-xs text-gray-500 text-right">{row}</span>
          <div className="flex gap-1.5 flex-wrap">
            {rowSeats.map((seat) => (
              <button
                key={seat.id}
                onClick={() => handleClick(seat)}
                disabled={seat.status === 'BOOKED'}
                className={`w-8 h-8 rounded text-xs font-medium border transition-colors ${getStyle(seat)}`}
                title={`Seat ${seat.seatNumber} – ${seat.status}`}
              >
                {seat.seatNumber.slice(1)}
              </button>
            ))}
          </div>
        </div>
      ))}

      <div className="flex gap-6 justify-center mt-6 text-xs text-gray-400">
        <div className="flex items-center gap-1.5"><div className="w-4 h-4 rounded bg-gray-800 border border-gray-600" />Available</div>
        <div className="flex items-center gap-1.5"><div className="w-4 h-4 rounded bg-brand-600 border border-brand-500" />Selected</div>
        <div className="flex items-center gap-1.5"><div className="w-4 h-4 rounded bg-red-900/60 border border-red-700" />Booked</div>
      </div>
    </div>
  )
}
