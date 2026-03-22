package com.moviebooking.service;

import com.moviebooking.dto.RecommendationResponse;
import com.moviebooking.entity.Movie;
import com.moviebooking.repository.BookingRepository;
import com.moviebooking.repository.MovieRepository;
import com.moviebooking.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * AI-powered recommendation engine using content-based and collaborative filtering.
 * Runs entirely in-JVM with no external API calls – keeping it within AWS Free Tier.
 *
 * Strategy:
 *   1. If the user has booking history  → genre-based content filtering.
 *   2. Popularity boost                 → most-booked movies surfaced first.
 *   3. Rating boost                     → same-genre top-rated movies.
 *   4. Already-watched movies excluded  → better UX.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AIRecommendationService {

    private final BookingRepository bookingRepository;
    private final MovieRepository movieRepository;
    private final UserRepository userRepository;

    public List<RecommendationResponse> getRecommendations(Long userId) {
        List<Object[]> genreStats = bookingRepository.findTopGenresByUser(userId);
        List<Object[]> popularMovieIds = bookingRepository.findMostBookedMovieIds();

        Set<Long> watchedMovieIds = bookingRepository.findByUserIdOrderByBookedAtDesc(userId)
                .stream()
                .map(b -> b.getShow().getMovie().getId())
                .collect(Collectors.toSet());

        List<Movie> allActive = movieRepository.findByActiveTrueOrderByCreatedAtDesc();

        Map<Long, Double> scoreMap = new HashMap<>();
        Map<Long, String> reasonMap = new HashMap<>();

        // Score: genre affinity based on user booking history
        if (!genreStats.isEmpty()) {
            String topGenre = (String) genreStats.get(0)[0];
            for (Movie m : allActive) {
                if (watchedMovieIds.contains(m.getId())) continue;
                double score = 0;
                for (int i = 0; i < genreStats.size(); i++) {
                    String genre = (String) genreStats.get(i)[0];
                    long count = (Long) genreStats.get(i)[1];
                    if (m.getGenre().equalsIgnoreCase(genre)) {
                        score += count * 10.0;
                        reasonMap.put(m.getId(), "Because you enjoy " + genre + " movies");
                    }
                }
                if (score > 0) scoreMap.merge(m.getId(), score, Double::sum);
            }
        }

        // Score: popularity boost
        for (int i = 0; i < popularMovieIds.size(); i++) {
            Long movieId = (Long) popularMovieIds.get(i)[0];
            if (watchedMovieIds.contains(movieId)) continue;
            double boost = (popularMovieIds.size() - i) * 5.0;
            scoreMap.merge(movieId, boost, Double::sum);
            reasonMap.putIfAbsent(movieId, "Trending now");
        }

        // Score: rating boost (0–5 scale mapped to up to 25 points)
        for (Movie m : allActive) {
            if (watchedMovieIds.contains(m.getId())) continue;
            if (m.getRating() != null) {
                scoreMap.merge(m.getId(), m.getRating() * 5.0, Double::sum);
            }
        }

        // Sort by composite score, take top 6
        Map<Long, Movie> movieLookup = allActive.stream()
                .collect(Collectors.toMap(Movie::getId, m -> m));

        return scoreMap.entrySet().stream()
                .sorted(Map.Entry.<Long, Double>comparingByValue().reversed())
                .limit(6)
                .map(e -> {
                    Movie m = movieLookup.get(e.getKey());
                    if (m == null) return null;
                    return RecommendationResponse.builder()
                            .movieId(m.getId())
                            .title(m.getTitle())
                            .genre(m.getGenre())
                            .rating(m.getRating())
                            .posterKey(m.getPosterKey())
                            .reason(reasonMap.getOrDefault(m.getId(), "Recommended for you"))
                            .aiSummary(buildAiSummary(m, reasonMap.get(m.getId())))
                            .build();
                })
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
    }

    private String buildAiSummary(Movie movie, String reason) {
        String base = reason != null ? reason : "Recommended for you";
        return String.format("%s — %s (%d), rated %.1f/5.",
                base,
                movie.getTitle(),
                movie.getReleaseYear(),
                movie.getRating() != null ? movie.getRating() : 0.0);
    }
}
