-- H2-compatible schema for CineBook (avoids reserved words: USER, SHOW)
-- Run on DataSource init; use with spring.jpa.hibernate.ddl-auto=none

DROP TABLE IF EXISTS booking_seats;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS seats;
DROP TABLE IF EXISTS movie_shows;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS app_users;

CREATE TABLE app_users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE movies (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description VARCHAR(5000),
    genre VARCHAR(100) NOT NULL,
    director VARCHAR(100),
    cast_members VARCHAR(500),
    duration_minutes INT,
    release_year INT NOT NULL,
    poster_key VARCHAR(500),
    rating DOUBLE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE movie_shows (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    movie_id BIGINT NOT NULL,
    venue VARCHAR(100) NOT NULL,
    screen VARCHAR(50) NOT NULL,
    show_time TIMESTAMP NOT NULL,
    total_seats INT NOT NULL,
    available_seats INT NOT NULL,
    ticket_price DOUBLE NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (movie_id) REFERENCES movies(id)
);

CREATE TABLE seats (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    show_id BIGINT NOT NULL,
    seat_number VARCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    UNIQUE (show_id, seat_number),
    FOREIGN KEY (show_id) REFERENCES movie_shows(id)
);

CREATE TABLE bookings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    show_id BIGINT NOT NULL,
    number_of_seats INT NOT NULL,
    total_amount DOUBLE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',
    confirmation_code VARCHAR(20) UNIQUE,
    booked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES app_users(id),
    FOREIGN KEY (show_id) REFERENCES movie_shows(id)
);

CREATE TABLE booking_seats (
    booking_id BIGINT NOT NULL,
    seat_number VARCHAR(255),
    PRIMARY KEY (booking_id, seat_number),
    FOREIGN KEY (booking_id) REFERENCES bookings(id)
);
