package com.moviebooking.service;

import com.moviebooking.entity.Seat;
import com.moviebooking.entity.Show;
import com.moviebooking.repository.SeatRepository;
import com.moviebooking.repository.ShowRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ShowService {

    private final ShowRepository showRepository;
    private final SeatRepository seatRepository;

    @Transactional(readOnly = true)
    public List<Show> getShowsByMovie(Long movieId) {
        return showRepository.findByMovieIdAndActiveTrueAndShowTimeAfterOrderByShowTime(
                movieId, LocalDateTime.now());
    }

    @Transactional(readOnly = true)
    public Show getShowById(Long id) {
        return showRepository.findById(id)
                .filter(Show::getActive)
                .orElseThrow(() -> new IllegalArgumentException("Show not found: " + id));
    }

    @Transactional(readOnly = true)
    public List<Seat> getSeatLayout(Long showId) {
        return seatRepository.findByShowId(showId);
    }

    @Transactional
    public Show createShow(Show show) {
        show.setAvailableSeats(show.getTotalSeats());
        Show saved = showRepository.save(show);
        generateSeats(saved);
        return saved;
    }

    @Transactional
    public void deleteShow(Long id) {
        Show show = getShowById(id);
        show.setActive(false);
        showRepository.save(show);
    }

    private void generateSeats(Show show) {
        List<Seat> seats = new ArrayList<>();
        int totalSeats = show.getTotalSeats();
        int rows = (int) Math.ceil(totalSeats / 10.0);
        int count = 0;

        for (int r = 0; r < rows && count < totalSeats; r++) {
            char rowLetter = (char) ('A' + r);
            for (int col = 1; col <= 10 && count < totalSeats; col++) {
                seats.add(Seat.builder()
                        .show(show)
                        .seatNumber(rowLetter + String.valueOf(col))
                        .status(Seat.SeatStatus.AVAILABLE)
                        .build());
                count++;
            }
        }
        seatRepository.saveAll(seats);
    }
}
