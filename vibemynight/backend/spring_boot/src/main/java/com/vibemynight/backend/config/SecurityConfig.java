package com.vibemynight.backend.config;

import com.vibemynight.backend.security.JwtAuthenticationEntryPoint;
import com.vibemynight.backend.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfigurationSource;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;
    private final CorsConfigurationSource corsConfigurationSource;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource))
                .csrf(csrf -> csrf.disable())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(eh -> eh.authenticationEntryPoint(jwtAuthenticationEntryPoint))
                .authorizeHttpRequests(auth -> auth
                        // Cloud and container health check endpoints
                        .requestMatchers("/", "/health", "/api/v1/health", "/error", "/favicon.ico", "/actuator/health", "/actuator/info").permitAll()
                        .requestMatchers("/actuator/**").hasRole("ADMIN")

                        // Auth
                        .requestMatchers("/api/v1/auth/**").permitAll()

                        // Public read-only customer-facing endpoints
                        .requestMatchers(HttpMethod.GET,
                                "/api/v1/events/**",
                                "/api/v1/artists/**",
                                "/api/v1/facilities/**",
                                "/api/v1/event-days/**",
                                "/api/v1/settings/public"
                        ).permitAll()

                        // Inquiry submission and status lookup are public; admin inquiry management is not
                        .requestMatchers(HttpMethod.POST, "/api/v1/inquiries").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/v1/inquiries/**").permitAll()

                        // Static uploads (local image storage, Phase 5+)
                        .requestMatchers("/uploads/**").permitAll()

                        // Everything else under /api/v1/admin/** requires an authenticated ADMIN
                        .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")

                        // Any other endpoint defaults to requiring authentication
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
