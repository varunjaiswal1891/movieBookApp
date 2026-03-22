package com.moviebooking.repository;

import com.moviebooking.entity.Show;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface ShowRepository extends JpaRepository<Show, Long> {

    @Query("SELECT s FROM Show s JOIN FETCH s.movie WHERE s.id = :id")
    java.util.Optional<Show> findByIdWithMovie(@Param("id") Long id);

    @Query("SELECT s FROM Show s JOIN FETCH s.movie WHERE s.movie.id = :movieId AND s.active = true AND s.showTime > :after ORDER BY s.showTime")
    List<Show> findByMovieIdAndActiveTrueAndShowTimeAfterOrderByShowTime(
            @Param("movieId") Long movieId, @Param("after") LocalDateTime after);

    @Query("SELECT s FROM Show s WHERE s.movie.id = :movieId AND s.active = true " +
           "AND s.showTime BETWEEN :start AND :end ORDER BY s.showTime")
    List<Show> findByMovieAndDateRange(
            @Param("movieId") Long movieId,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

    List<Show> findByActiveTrueAndShowTimeAfterOrderByShowTime(LocalDateTime after);
}
