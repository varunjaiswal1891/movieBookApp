package com.moviebooking.controller;

import com.moviebooking.entity.Movie;
import com.moviebooking.entity.Show;
import com.moviebooking.service.MovieService;
import com.moviebooking.service.ShowService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminController {

    private final MovieService movieService;
    private final ShowService showService;

    // ── Movie management ──────────────────────────────────────────────────────

    @PostMapping("/movies")
    public ResponseEntity<Movie> createMovie(
            @RequestPart("movie") @Valid Movie movie,
            @RequestPart(value = "poster", required = false) MultipartFile poster) throws IOException {
        return ResponseEntity.ok(movieService.createMovie(movie, poster));
    }

    @PutMapping("/movies/{id}")
    public ResponseEntity<Movie> updateMovie(
            @PathVariable Long id,
            @RequestPart("movie") @Valid Movie movie,
            @RequestPart(value = "poster", required = false) MultipartFile poster) throws IOException {
        return ResponseEntity.ok(movieService.updateMovie(id, movie, poster));
    }

    @DeleteMapping("/movies/{id}")
    public ResponseEntity<?> deleteMovie(@PathVariable Long id) {
        movieService.deleteMovie(id);
        return ResponseEntity.ok(Map.of("message", "Movie deleted"));
    }

    // ── Show management ───────────────────────────────────────────────────────

    @PostMapping("/shows")
    public ResponseEntity<Show> createShow(@Valid @RequestBody Show show) {
        return ResponseEntity.ok(showService.createShow(show));
    }

    @DeleteMapping("/shows/{id}")
    public ResponseEntity<?> deleteShow(@PathVariable Long id) {
        showService.deleteShow(id);
        return ResponseEntity.ok(Map.of("message", "Show deleted"));
    }
}
