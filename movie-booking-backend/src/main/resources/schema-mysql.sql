-- MySQL-compatible schema for first-time init (idempotent with IF NOT EXISTS)
-- Used when spring.sql.init.platform=mysql and spring.sql.init.mode=always

CREATE TABLE IF NOT EXISTS app_users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_username (username),
    UNIQUE KEY uk_email (email)
);

CREATE TABLE IF NOT EXISTS movies (
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

CREATE TABLE IF NOT EXISTS movie_shows (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    movie_id BIGINT NOT NULL,
    venue VARCHAR(100) NOT NULL,
    screen VARCHAR(50) NOT NULL,
    show_time DATETIME(6) NOT NULL,
    total_seats INT NOT NULL,
    available_seats INT NOT NULL,
    ticket_price DOUBLE NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (movie_id) REFERENCES movies(id)
);

CREATE TABLE IF NOT EXISTS seats (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    show_id BIGINT NOT NULL,
    seat_number VARCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    UNIQUE KEY uk_show_seat (show_id, seat_number),
    FOREIGN KEY (show_id) REFERENCES movie_shows(id)
);

CREATE TABLE IF NOT EXISTS bookings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    show_id BIGINT NOT NULL,
    number_of_seats INT NOT NULL,
    total_amount DOUBLE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',
    confirmation_code VARCHAR(20),
    booked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_confirmation (confirmation_code),
    FOREIGN KEY (user_id) REFERENCES app_users(id),
    FOREIGN KEY (show_id) REFERENCES movie_shows(id)
);

CREATE TABLE IF NOT EXISTS booking_seats (
    booking_id BIGINT NOT NULL,
    seat_number VARCHAR(255) NOT NULL,
    PRIMARY KEY (booking_id, seat_number),
    FOREIGN KEY (booking_id) REFERENCES bookings(id)
);
