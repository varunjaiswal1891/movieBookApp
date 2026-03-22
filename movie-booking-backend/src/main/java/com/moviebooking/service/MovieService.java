package com.moviebooking.service;

import com.moviebooking.entity.Movie;
import com.moviebooking.repository.MovieRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

import java.io.IOException;
import java.time.Duration;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MovieService {

    private final MovieRepository movieRepository;

    @Autowired(required = false)
    private S3Client s3Client;

    @Autowired(required = false)
    private S3Presigner s3Presigner;

    @Value("${app.aws.s3-bucket:movie-booking-posters}")
    private String bucket;

    public List<Movie> getAllActiveMovies() {
        return movieRepository.findByActiveTrueOrderByCreatedAtDesc();
    }

    public Movie getMovieById(Long id) {
        return movieRepository.findById(id)
                .filter(Movie::getActive)
                .orElseThrow(() -> new IllegalArgumentException("Movie not found: " + id));
    }

    public List<Movie> searchMovies(String query) {
        return movieRepository.searchMovies(query);
    }

    public List<Movie> getMoviesByGenre(String genre) {
        return movieRepository.findByGenreAndActiveTrue(genre);
    }

    public List<String> getAllGenres() {
        return movieRepository.findAllActiveGenres();
    }

    @Transactional
    public Movie createMovie(Movie movie, MultipartFile poster) throws IOException {
        if (poster != null && !poster.isEmpty() && s3Client != null) {
            String key = uploadPoster(poster);
            movie.setPosterKey(key);
        }
        return movieRepository.save(movie);
    }

    @Transactional
    public Movie updateMovie(Long id, Movie updated, MultipartFile poster) throws IOException {
        Movie existing = getMovieById(id);
        existing.setTitle(updated.getTitle());
        existing.setDescription(updated.getDescription());
        existing.setGenre(updated.getGenre());
        existing.setDirector(updated.getDirector());
        existing.setCastMembers(updated.getCastMembers());
        existing.setDurationMinutes(updated.getDurationMinutes());
        existing.setReleaseYear(updated.getReleaseYear());
        existing.setRating(updated.getRating());

        if (poster != null && !poster.isEmpty() && s3Client != null) {
            if (existing.getPosterKey() != null) {
                deletePoster(existing.getPosterKey());
            }
            existing.setPosterKey(uploadPoster(poster));
        }
        return movieRepository.save(existing);
    }

    @Transactional
    public void deleteMovie(Long id) {
        Movie movie = getMovieById(id);
        movie.setActive(false);
        movieRepository.save(movie);
    }

    public String getPosterPresignedUrl(String posterKey) {
        if (posterKey == null || s3Presigner == null) return null;
        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofHours(1))
                .getObjectRequest(GetObjectRequest.builder()
                        .bucket(bucket)
                        .key(posterKey)
                        .build())
                .build();
        return s3Presigner.presignGetObject(presignRequest).url().toString();
    }

    private String uploadPoster(MultipartFile file) throws IOException {
        String key = "posters/" + UUID.randomUUID() + "-" + file.getOriginalFilename();
        s3Client.putObject(
                PutObjectRequest.builder()
                        .bucket(bucket)
                        .key(key)
                        .contentType(file.getContentType())
                        .build(),
                RequestBody.fromBytes(file.getBytes())
        );
        return key;
    }

    private void deletePoster(String key) {
        s3Client.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(key).build());
    }
}
