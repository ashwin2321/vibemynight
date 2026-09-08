package com.vibemynight.backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

/**
 * Without this, Flutter Web (served from its own dev-server origin, e.g.
 * http://localhost:PORT) cannot call this API running on a different origin
 * (http://localhost:8080) - the browser blocks it at the CORS preflight
 * before the request ever reaches a controller. Flutter mobile/desktop
 * builds aren't affected (no browser same-origin policy), but Flutter Web
 * is the platform explicitly required by the spec, so this is required for
 * "connect Flutter to backend" to actually work end-to-end.
 */
@Configuration
public class CorsConfig {

    /**
     * Comma-separated list of allowed origins, e.g.
     * "http://localhost:5000,https://admin.vibemynight.com". Defaults to a
     * permissive localhost pattern for local development only - set this
     * explicitly via env var in any deployed environment.
     */
    @Value("${app.cors.allowed-origins:http://localhost:*}")
    private String allowedOrigins;

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        List<String> origins = Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
        configuration.setAllowedOriginPatterns(origins);
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
