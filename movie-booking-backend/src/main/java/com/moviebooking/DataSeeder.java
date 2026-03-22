package com.moviebooking;

import com.moviebooking.entity.Movie;
import com.moviebooking.entity.Show;
import com.moviebooking.entity.User;
import com.moviebooking.repository.MovieRepository;
import com.moviebooking.repository.UserRepository;
import com.moviebooking.service.ShowService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final MovieRepository movieRepository;
    private final ShowService showService;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        seedUsers();
        seedMovies();
        log.info("Seed data loaded successfully");
    }

    private void seedUsers() {
        if (!userRepository.existsByUsername("admin")) {
            userRepository.save(User.builder()
                    .username("admin")
                    .email("admin@moviebook.com")
                    .password(passwordEncoder.encode("Admin@1234"))
                    .role(User.Role.ADMIN)
                    .build());
        }
        if (!userRepository.existsByUsername("john")) {
            userRepository.save(User.builder()
                    .username("john")
                    .email("john@example.com")
                    .password(passwordEncoder.encode("User@1234"))
                    .role(User.Role.USER)
                    .build());
        }
        if (!userRepository.existsByUsername("jane")) {
            userRepository.save(User.builder()
                    .username("jane")
                    .email("jane@example.com")
                    .password(passwordEncoder.encode("User@1234"))
                    .role(User.Role.USER)
                    .build());
        }
    }

    private void seedMovies() {
        if (movieRepository.count() > 0) return;

        Movie m1 = movieRepository.save(Movie.builder()
                .title("Inception").genre("Sci-Fi").director("Christopher Nolan")
                .description("A thief enters the dreams of others to steal secrets.")
                .durationMinutes(148).releaseYear(2010).rating(4.8).active(true).build());

        Movie m2 = movieRepository.save(Movie.builder()
                .title("The Dark Knight").genre("Action").director("Christopher Nolan")
                .description("Batman faces the Joker in a battle for Gotham City.")
                .durationMinutes(152).releaseYear(2008).rating(4.9).active(true).build());

        Movie m3 = movieRepository.save(Movie.builder()
                .title("Interstellar").genre("Sci-Fi").director("Christopher Nolan")
                .description("Astronauts travel through a wormhole in search of a new home.")
                .durationMinutes(169).releaseYear(2014).rating(4.7).active(true).build());

        Movie m4 = movieRepository.save(Movie.builder()
                .title("Parasite").genre("Thriller").director("Bong Joon-ho")
                .description("A poor family schemes to become employed by a wealthy family.")
                .durationMinutes(132).releaseYear(2019).rating(4.6).active(true).build());

        Movie m5 = movieRepository.save(Movie.builder()
                .title("The Shawshank Redemption").genre("Drama").director("Frank Darabont")
                .description("Two imprisoned men bond over a number of years.")
                .durationMinutes(142).releaseYear(1994).rating(4.9).active(true).build());

        Movie m6 = movieRepository.save(Movie.builder()
                .title("Pulp Fiction").genre("Crime").director("Quentin Tarantino")
                .description("Several stories intertwine in Los Angeles underworld.")
                .durationMinutes(154).releaseYear(1994).rating(4.8).active(true).build());

        Movie m7 = movieRepository.save(Movie.builder()
                .title("The Matrix").genre("Sci-Fi").director("Lana Wachowski")
                .description("A computer hacker learns the truth about reality.")
                .durationMinutes(136).releaseYear(1999).rating(4.7).active(true).build());

        Movie m8 = movieRepository.save(Movie.builder()
                .title("Spirited Away").genre("Animation").director("Hayao Miyazaki")
                .description("A girl wanders into a world of spirits.")
                .durationMinutes(125).releaseYear(2001).rating(4.8).active(true).build());

        Movie m9 = movieRepository.save(Movie.builder()
                .title("Gladiator").genre("Action").director("Ridley Scott")
                .description("A betrayed Roman general seeks vengeance.")
                .durationMinutes(155).releaseYear(2000).rating(4.6).active(true).build());

        Movie m10 = movieRepository.save(Movie.builder()
                .title("Avatar").genre("Sci-Fi").director("James Cameron")
                .description("A paraplegic marine is dispatched to Pandora.")
                .durationMinutes(162).releaseYear(2009).rating(4.5).active(true).build());

        seedShows(m1);
        seedShows(m2);
        seedShows(m3);
        seedShows(m4);
        seedShows(m5);
        seedShows(m6);
        seedShows(m7);
        seedShows(m8);
        seedShows(m9);
        seedShows(m10);
    }

    private void seedShows(Movie movie) {
        LocalDateTime base = LocalDateTime.now().plusDays(1).withHour(10).withMinute(0).withSecond(0).withNano(0);
        for (int i = 0; i < 2; i++) {
            Show show = Show.builder()
                    .movie(movie)
                    .venue("CinePlex " + (i + 1))
                    .screen("Screen " + (i + 1))
                    .showTime(base.plusHours(i * 4L))
                    .totalSeats(50)
                    .ticketPrice(12.99 + i)
                    .active(true)
                    .build();
            showService.createShow(show);
        }
    }
}
