package com.moviebooking.repository;

import com.moviebooking.entity.Movie;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface MovieRepository extends JpaRepository<Movie, Long> {

    List<Movie> findByActiveTrueOrderByCreatedAtDesc();

    List<Movie> findByGenreAndActiveTrue(String genre);

    @Query("SELECT m FROM Movie m WHERE m.active = true AND " +
           "(LOWER(m.title) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           " LOWER(m.genre) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<Movie> searchMovies(@Param("query") String query);

    @Query("SELECT DISTINCT m.genre FROM Movie m WHERE m.active = true")
    List<String> findAllActiveGenres();

    @Query("SELECT m FROM Movie m WHERE m.active = true ORDER BY m.rating DESC LIMIT 10")
    List<Movie> findTopRatedMovies();
}
