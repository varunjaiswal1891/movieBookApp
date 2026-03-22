package com.moviebooking.controller;

import com.moviebooking.entity.Seat;
import com.moviebooking.entity.Show;
import com.moviebooking.service.ShowService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/shows")
@RequiredArgsConstructor
public class ShowController {

    private final ShowService showService;

    @GetMapping("/{id}")
    public ResponseEntity<Show> getShow(@PathVariable Long id) {
        return ResponseEntity.ok(showService.getShowById(id));
    }

    @GetMapping("/{id}/seats")
    public ResponseEntity<List<Seat>> getSeatLayout(@PathVariable Long id) {
        return ResponseEntity.ok(showService.getSeatLayout(id));
    }
}
