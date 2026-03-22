package com.moviebooking.service;

import com.moviebooking.dto.BookingRequest;
import com.moviebooking.entity.*;
import com.moviebooking.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BookingService {

    private final BookingRepository bookingRepository;
    private final ShowRepository showRepository;
    private final SeatRepository seatRepository;
    private final UserRepository userRepository;

    public List<Booking> getUserBookings(Long userId) {
        return bookingRepository.findByUserIdOrderByBookedAtDescWithShowAndMovie(userId);
    }

    public Booking getBookingById(Long bookingId, Long userId) {
        Booking booking = bookingRepository.findByIdWithShowAndMovie(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found"));
        if (!booking.getUser().getId().equals(userId)) {
            throw new IllegalArgumentException("Access denied");
        }
        return booking;
    }

    @Transactional
    public Booking createBooking(BookingRequest request, String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Show show = showRepository.findByIdWithMovie(request.getShowId())
                .filter(Show::getActive)
                .orElseThrow(() -> new IllegalArgumentException("Show not found or unavailable"));

        List<String> requestedSeats = request.getSeatNumbers();

        if (requestedSeats.size() < 1 || requestedSeats.size() > 5) {
            throw new IllegalArgumentException("You can book between 1 and 5 seats");
        }

        List<Seat> seats = seatRepository.findByShowIdAndSeatNumberIn(show.getId(), requestedSeats);

        if (seats.size() != requestedSeats.size()) {
            throw new IllegalArgumentException("One or more seat numbers are invalid");
        }

        boolean anyUnavailable = seats.stream()
                .anyMatch(s -> s.getStatus() != Seat.SeatStatus.AVAILABLE);
        if (anyUnavailable) {
            throw new IllegalArgumentException("One or more seats are already booked");
        }

        seatRepository.updateSeatStatus(show.getId(), requestedSeats, Seat.SeatStatus.BOOKED);

        show.setAvailableSeats(show.getAvailableSeats() - requestedSeats.size());
        showRepository.save(show);

        double totalAmount = show.getTicketPrice() * requestedSeats.size();

        Booking booking = Booking.builder()
                .user(user)
                .show(show)
                .seatNumbers(requestedSeats)
                .numberOfSeats(requestedSeats.size())
                .totalAmount(totalAmount)
                .status(Booking.BookingStatus.CONFIRMED)
                .confirmationCode("MB-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .build();

        return bookingRepository.save(booking);
    }

    @Transactional
    public void cancelBooking(Long bookingId, String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found"));

        if (!booking.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("Access denied");
        }

        if (booking.getStatus() == Booking.BookingStatus.CANCELLED) {
            throw new IllegalArgumentException("Booking is already cancelled");
        }

        booking.setStatus(Booking.BookingStatus.CANCELLED);
        bookingRepository.save(booking);

        seatRepository.updateSeatStatus(
                booking.getShow().getId(),
                booking.getSeatNumbers(),
                Seat.SeatStatus.AVAILABLE);

        Show show = booking.getShow();
        show.setAvailableSeats(show.getAvailableSeats() + booking.getNumberOfSeats());
        showRepository.save(show);
    }
}
