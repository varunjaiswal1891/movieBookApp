package com.moviebooking.repository;

import com.moviebooking.entity.Booking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface BookingRepository extends JpaRepository<Booking, Long> {

    List<Booking> findByUserIdOrderByBookedAtDesc(Long userId);

    @Query("SELECT b FROM Booking b JOIN FETCH b.show s JOIN FETCH s.movie WHERE b.user.id = :userId ORDER BY b.bookedAt DESC")
    List<Booking> findByUserIdOrderByBookedAtDescWithShowAndMovie(@Param("userId") Long userId);

    @Query("SELECT b FROM Booking b JOIN FETCH b.show s JOIN FETCH s.movie WHERE b.id = :id")
    Optional<Booking> findByIdWithShowAndMovie(@Param("id") Long id);

    Optional<Booking> findByConfirmationCode(String confirmationCode);

    @Query("SELECT b FROM Booking b WHERE b.user.id = :userId AND b.show.movie.id = :movieId")
    List<Booking> findByUserIdAndMovieId(@Param("userId") Long userId, @Param("movieId") Long movieId);

    @Query("SELECT b.show.movie.genre, COUNT(b) FROM Booking b WHERE b.user.id = :userId " +
           "AND b.status = 'CONFIRMED' GROUP BY b.show.movie.genre ORDER BY COUNT(b) DESC")
    List<Object[]> findTopGenresByUser(@Param("userId") Long userId);

    @Query("SELECT b.show.movie.id, COUNT(b) FROM Booking b " +
           "WHERE b.status = 'CONFIRMED' GROUP BY b.show.movie.id ORDER BY COUNT(b) DESC LIMIT 10")
    List<Object[]> findMostBookedMovieIds();
}
