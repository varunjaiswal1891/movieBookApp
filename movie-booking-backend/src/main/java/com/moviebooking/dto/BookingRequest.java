package com.moviebooking.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.List;

@Data
public class BookingRequest {

    @NotNull
    private Long showId;

    @NotNull
    @Size(min = 1, max = 5, message = "You can book between 1 and 5 seats")
    private List<String> seatNumbers;
}
