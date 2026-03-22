package com.moviebooking.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.List;

@Data
@Component
@ConfigurationProperties(prefix = "app.cors")
public class CorsProperties {

    private List<String> allowedOriginPatterns = List.of(
            "http://localhost:3000",
            "http://localhost:5173",
            "https://*.cloudfront.net",
            "https://*.amazonaws.com"
    );
}
