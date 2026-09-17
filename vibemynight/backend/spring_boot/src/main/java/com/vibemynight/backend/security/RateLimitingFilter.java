package com.vibemynight.backend.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vibemynight.backend.dto.ApiResponse;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * In-memory sliding window rate limiter for security-sensitive and spam-prone endpoints:
 * - POST /api/v1/auth/login (10 requests / min / IP)
 * - POST /api/v1/inquiries (30 requests / min / IP)
 */
@Component
public class RateLimitingFilter extends OncePerRequestFilter {

    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final int LOGIN_LIMIT_PER_MINUTE = 10;
    private static final int INQUIRY_LIMIT_PER_MINUTE = 30;
    private static final long WINDOW_MILLIS = 60_000L; // 1 minute

    private final ConcurrentHashMap<String, RequestBucket> clientBuckets = new ConcurrentHashMap<>();

    private static class RequestBucket {
        long windowStart;
        final AtomicInteger count;

        RequestBucket(long now) {
            this.windowStart = now;
            this.count = new AtomicInteger(1);
        }

        synchronized boolean allowRequest(int limit, long now) {
            if (now - windowStart > WINDOW_MILLIS) {
                windowStart = now;
                count.set(1);
                return true;
            }
            return count.incrementAndGet() <= limit;
        }
    }

    private static final int INQUIRY_LOOKUP_LIMIT_PER_MINUTE = 30;

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {

        String path = request.getRequestURI();
        String method = request.getMethod();

        int limit = -1;
        if ("POST".equalsIgnoreCase(method)) {
            if (path.equals("/api/v1/auth/login")) {
                limit = LOGIN_LIMIT_PER_MINUTE;
            } else if (path.equals("/api/v1/inquiries")) {
                limit = INQUIRY_LIMIT_PER_MINUTE;
            }
        } else if ("GET".equalsIgnoreCase(method)) {
            if (path.startsWith("/api/v1/inquiries/")) {
                limit = INQUIRY_LOOKUP_LIMIT_PER_MINUTE;
            }
        }

        if (limit > 0) {
            String clientIp = getClientIp(request);
            String bucketKey = (path.startsWith("/api/v1/inquiries/") ? "/api/v1/inquiries/*" : path) + ":" + clientIp;
            long now = System.currentTimeMillis();

            // Self-cleaning periodically if map grows large
            if (clientBuckets.size() > 5000) {
                clientBuckets.entrySet().removeIf(entry -> now - entry.getValue().windowStart > WINDOW_MILLIS * 2);
            }

            RequestBucket bucket = clientBuckets.compute(bucketKey, (k, existing) -> {
                if (existing == null) {
                    return new RequestBucket(now);
                }
                return existing;
            });

            if (!bucket.allowRequest(limit, now)) {
                response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                response.getWriter().write(
                        objectMapper.writeValueAsString(
                                ApiResponse.error("Too many requests. Please wait a moment and try again.", null)
                        )
                );
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    private static final java.util.regex.Pattern IP_PATTERN =
            java.util.regex.Pattern.compile("^[0-9a-fA-F:.]+$");

    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isBlank()) {
            String candidate = xForwardedFor.split(",")[0].trim();
            if (IP_PATTERN.matcher(candidate).matches() && candidate.length() <= 45) {
                return candidate;
            }
        }
        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isBlank()) {
            String candidate = xRealIp.trim();
            if (IP_PATTERN.matcher(candidate).matches() && candidate.length() <= 45) {
                return candidate;
            }
        }
        return request.getRemoteAddr() != null ? request.getRemoteAddr() : "unknown";
    }
}
