package com.vibemynight.backend.util;

import com.vibemynight.backend.exception.BadRequestException;
import com.vibemynight.backend.security.UrlSecurityValidator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Optional;

@Slf4j
@Component
@RequiredArgsConstructor
public class SafeWebFetcher {

    private final UrlSecurityValidator urlSecurityValidator;

    private static final int MAX_REDIRECTS = 5;
    private static final int MAX_BODY_BYTES = 2 * 1024 * 1024; // 2 MB
    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(5);
    private static final Duration READ_TIMEOUT = Duration.ofSeconds(8);

    private static final String USER_AGENT =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36";

    /**
     * Safely fetches the HTML content of a public URL with SSRF protection,
     * validated redirects, timeout bounds, and maximum response size limits.
     */
    public String fetchHtml(String rawUrl) {
        URI currentUri = urlSecurityValidator.validateAndSanitizeUrl(rawUrl);

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(CONNECT_TIMEOUT)
                .followRedirects(HttpClient.Redirect.NEVER) // Manual redirect validation for SSRF safety
                .build();

        int redirectCount = 0;

        while (redirectCount <= MAX_REDIRECTS) {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(currentUri)
                    .timeout(READ_TIMEOUT)
                    .header("User-Agent", USER_AGENT)
                    .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7")
                    .header("Accept-Language", "en-US,en;q=0.9,hi;q=0.8,gu;q=0.7")
                    .header("Sec-Ch-Ua", "\"Chromium\";v=\"128\", \"Not;A=Brand\";v=\"24\", \"Google Chrome\";v=\"128\"")
                    .header("Sec-Ch-Ua-Mobile", "?0")
                    .header("Sec-Ch-Ua-Platform", "\"Windows\"")
                    .header("Sec-Fetch-Dest", "document")
                    .header("Sec-Fetch-Mode", "navigate")
                    .header("Sec-Fetch-Site", "none")
                    .header("Sec-Fetch-User", "?1")
                    .header("Upgrade-Insecure-Requests", "1")
                    .GET()
                    .build();

            try {
                HttpResponse<InputStream> response = client.send(request, HttpResponse.BodyHandlers.ofInputStream());
                int statusCode = response.statusCode();

                // Handle Redirects (301, 302, 303, 307, 308)
                if (statusCode >= 300 && statusCode < 400) {
                    Optional<String> locationOpt = response.headers().firstValue("Location");
                    if (locationOpt.isEmpty() || locationOpt.get().isBlank()) {
                        throw new BadRequestException("Redirect response missing Location header.");
                    }

                    String redirectLocation = locationOpt.get();
                    URI targetUri = currentUri.resolve(redirectLocation);

                    // Re-validate redirect target for SSRF!
                    currentUri = urlSecurityValidator.validateAndSanitizeUrl(targetUri.toString());
                    redirectCount++;
                    continue;
                }

                if (statusCode == 404) {
                    throw new BadRequestException("Event page not found (HTTP 404). Please verify the link.");
                }

                if (statusCode == 403 || statusCode == 401) {
                    log.warn("Website returned status {} for URL: {}. Proceeding with URL metadata fallback.", statusCode, currentUri);
                    // Return minimal fallback HTML so the user gets an initialized draft rather than hard failure
                    return "<html><head><title>" + currentUri.getPath() + "</title></head><body><!-- bot-protected --></body></html>";
                }

                if (statusCode >= 400) {
                    throw new BadRequestException("Remote website returned an error (HTTP " + statusCode + ").");
                }

                // Read limited response body
                try (InputStream in = response.body(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
                    byte[] buffer = new byte[8192];
                    int bytesRead;
                    int totalRead = 0;

                    while ((bytesRead = in.read(buffer)) != -1) {
                        totalRead += bytesRead;
                        if (totalRead > MAX_BODY_BYTES) {
                            log.warn("Response exceeded maximum allowed size of 2MB for URL: {}", currentUri);
                            break;
                        }
                        out.write(buffer, 0, bytesRead);
                    }

                    return out.toString(StandardCharsets.UTF_8);
                }

            } catch (BadRequestException e) {
                throw e;
            } catch (java.net.http.HttpTimeoutException e) {
                throw new BadRequestException("Connection to source website timed out. Please try again.");
            } catch (java.io.IOException e) {
                log.warn("Network error fetching URL {}: {}", currentUri, e.getMessage());
                throw new BadRequestException("Network error connecting to source website: " + e.getMessage());
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new BadRequestException("Request was interrupted.");
            } catch (Exception e) {
                log.error("Unexpected error fetching URL {}: {}", currentUri, e.getMessage());
                throw new BadRequestException("Unable to fetch event page: " + e.getMessage());
            }
        }

        throw new BadRequestException("Too many redirects encountered while fetching event page.");
    }

    public static class ImageFetchResult {
        public final byte[] data;
        public final String contentType;

        public ImageFetchResult(byte[] data, String contentType) {
            this.data = data;
            this.contentType = contentType;
        }
    }

    /**
     * Safely fetches remote image binary data with SSRF protection,
     * browser header emulation, redirect validation, and 10MB limit.
     */
    public ImageFetchResult fetchImageBytes(String rawUrl) {
        URI currentUri = urlSecurityValidator.validateAndSanitizeUrl(rawUrl);

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(CONNECT_TIMEOUT)
                .followRedirects(HttpClient.Redirect.NEVER)
                .build();

        int redirectCount = 0;

        while (redirectCount <= MAX_REDIRECTS) {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(currentUri)
                    .timeout(READ_TIMEOUT)
                    .header("User-Agent", USER_AGENT)
                    .header("Accept", "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8")
                    .header("Sec-Fetch-Dest", "image")
                    .header("Sec-Fetch-Mode", "no-cors")
                    .header("Sec-Fetch-Site", "cross-site")
                    .GET()
                    .build();

            try {
                HttpResponse<InputStream> response = client.send(request, HttpResponse.BodyHandlers.ofInputStream());
                int statusCode = response.statusCode();

                if (statusCode >= 300 && statusCode < 400) {
                    Optional<String> locationOpt = response.headers().firstValue("Location");
                    if (locationOpt.isEmpty() || locationOpt.get().isBlank()) {
                        throw new BadRequestException("Redirect response missing Location header.");
                    }
                    String redirectLocation = locationOpt.get();
                    URI targetUri = currentUri.resolve(redirectLocation);
                    currentUri = urlSecurityValidator.validateAndSanitizeUrl(targetUri.toString());
                    redirectCount++;
                    continue;
                }

                if (statusCode >= 400) {
                    throw new BadRequestException("Remote image server returned status " + statusCode);
                }

                String contentType = response.headers().firstValue("Content-Type").orElse("image/jpeg");

                try (InputStream in = response.body(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
                    byte[] buffer = new byte[8192];
                    int bytesRead;
                    int totalRead = 0;

                    while ((bytesRead = in.read(buffer)) != -1) {
                        totalRead += bytesRead;
                        if (totalRead > 10 * 1024 * 1024) { // 10MB limit for image
                            break;
                        }
                        out.write(buffer, 0, bytesRead);
                    }

                    return new ImageFetchResult(out.toByteArray(), contentType);
                }
            } catch (BadRequestException e) {
                throw e;
            } catch (Exception e) {
                log.warn("Error fetching remote image {}: {}", currentUri, e.getMessage());
                throw new BadRequestException("Unable to load remote image: " + e.getMessage());
            }
        }

        throw new BadRequestException("Too many redirects fetching remote image.");
    }
}
