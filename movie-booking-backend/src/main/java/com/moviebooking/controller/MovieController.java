package com.moviebooking.controller;

import com.moviebooking.entity.Movie;
import com.moviebooking.entity.Show;
import com.moviebooking.service.MovieService;
import com.moviebooking.service.ShowService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/movies")
@RequiredArgsConstructor
public class MovieController {

    private final MovieService movieService;
    private final ShowService showService;

    @GetMapping
    public ResponseEntity<List<Movie>> getAllMovies(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String genre) {

        if (search != null && !search.isBlank()) {
            return ResponseEntity.ok(movieService.searchMovies(search));
        }
        if (genre != null && !genre.isBlank()) {
            return ResponseEntity.ok(movieService.getMoviesByGenre(genre));
        }
        return ResponseEntity.ok(movieService.getAllActiveMovies());
    }

    @GetMapping("/genres")
    public ResponseEntity<List<String>> getGenres() {
        return ResponseEntity.ok(movieService.getAllGenres());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Movie> getMovie(@PathVariable Long id) {
        return ResponseEntity.ok(movieService.getMovieById(id));
    }

    @GetMapping("/{id}/poster-url")
    public ResponseEntity<?> getPosterUrl(@PathVariable Long id) {
        Movie movie = movieService.getMovieById(id);
        String url = movieService.getPosterPresignedUrl(movie.getPosterKey());
        return ResponseEntity.ok(Map.of("url", url != null ? url : ""));
    }

    @GetMapping("/{id}/shows")
    public ResponseEntity<List<Show>> getShowsForMovie(@PathVariable Long id) {
        return ResponseEntity.ok(showService.getShowsByMovie(id));
    }
}
