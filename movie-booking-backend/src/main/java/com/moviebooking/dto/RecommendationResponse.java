package com.moviebooking.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecommendationResponse {
    private Long movieId;
    private String title;
    private String genre;
    private Double rating;
    private String posterKey;
    private String reason;
    private List<String> recommendedMovies;
    private String aiSummary;
}
