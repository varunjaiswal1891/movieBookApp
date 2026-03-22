package com.moviebooking.repository;

import com.moviebooking.entity.Seat;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SeatRepository extends JpaRepository<Seat, Long> {

    List<Seat> findByShowId(Long showId);

    List<Seat> findByShowIdAndStatus(Long showId, Seat.SeatStatus status);

    @Query("SELECT s FROM Seat s WHERE s.show.id = :showId AND s.seatNumber IN :seatNumbers")
    List<Seat> findByShowIdAndSeatNumberIn(
            @Param("showId") Long showId,
            @Param("seatNumbers") List<String> seatNumbers);

    @Modifying
    @Query("UPDATE Seat s SET s.status = :status WHERE s.show.id = :showId AND s.seatNumber IN :seatNumbers")
    int updateSeatStatus(
            @Param("showId") Long showId,
            @Param("seatNumbers") List<String> seatNumbers,
            @Param("status") Seat.SeatStatus status);
}
