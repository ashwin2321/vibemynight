package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.UploadFromUrlRequest;
import com.vibemynight.backend.dto.UploadResponse;
import com.vibemynight.backend.exception.BadRequestException;
import com.vibemynight.backend.security.UrlSecurityValidator;
import com.vibemynight.backend.service.storage.FileStorageService;
import com.vibemynight.backend.util.SafeWebFetcher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.time.Duration;

/**
 * Image upload and secure proxy controller - covers local file upload,
 * URL auto-import with SSRF validation, and CORS-enabled image proxy.
 */
@Slf4j
@RestController
@RequiredArgsConstructor
public class UploadController {

    private final FileStorageService fileStorageService;
    private final SafeWebFetcher safeWebFetcher;
    private final UrlSecurityValidator urlSecurityValidator;

    /**
     * multipart/form-data with a "file" part. Optional "folder" query param
     * groups uploads (e.g. "events", "artists", "gallery") - purely cosmetic
     * for local disk organization.
     */
    @PostMapping("/api/v1/admin/uploads")
    public ApiResponse<UploadResponse> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "folder", required = false, defaultValue = "misc") String folder
    ) {
        String url = fileStorageService.store(file, folder);
        return ApiResponse.ok(UploadResponse.builder().url(url).build(), "File uploaded");
    }

    /**
     * Downloads an image from an external public URL, validates SSRF and magic bytes,
     * stores it permanently in local storage, and returns the VibeMyNight local URL.
     */
    @PostMapping("/api/v1/admin/uploads/from-url")
    public ApiResponse<UploadResponse> uploadFromUrl(
            @RequestParam(value = "url", required = false) String queryUrl,
            @RequestParam(value = "folder", required = false) String queryFolder,
            @RequestBody(required = false) UploadFromUrlRequest requestBody
    ) {
        String targetUrl = queryUrl != null && !queryUrl.isBlank()
                ? queryUrl
                : (requestBody != null ? requestBody.getUrl() : null);

        String targetFolder = queryFolder != null && !queryFolder.isBlank()
                ? queryFolder
                : (requestBody != null && requestBody.getFolder() != null ? requestBody.getFolder() : "events");

        if (targetUrl == null || targetUrl.isBlank()) {
            throw new BadRequestException("Image URL must not be blank.");
        }

        String cleanUrl = urlSecurityValidator.extractAndCleanSingleUrl(targetUrl);
        SafeWebFetcher.ImageFetchResult result = safeWebFetcher.fetchImageBytes(cleanUrl);

        if (result == null || result.data == null || result.data.length == 0) {
            throw new BadRequestException("No valid image data could be downloaded from source URL.");
        }

        String filename = "artwork.jpg";
        try {
            java.net.URI uri = java.net.URI.create(cleanUrl);
            String path = uri.getPath();
            if (path != null && path.contains("/")) {
                String lastSegment = path.substring(path.lastIndexOf('/') + 1);
                if (lastSegment.contains(".")) {
                    filename = lastSegment;
                }
            }
        } catch (Exception ignored) {}

        String localUrl = fileStorageService.storeBytes(result.data, filename, targetFolder);
        return ApiResponse.ok(UploadResponse.builder().url(localUrl).build(), "Image imported and saved to server");
    }

    /**
     * CORS Image Proxy: Streams remote images with 'Access-Control-Allow-Origin: *'
     * and 24h caching headers to allow Flutter Web to preview 3rd-party images directly without browser CORS errors.
     */
    @GetMapping(value = "/api/v1/images/proxy")
    public ResponseEntity<byte[]> proxyImage(@RequestParam("url") String url) {
        if (url == null || url.isBlank()) {
            return ResponseEntity.badRequest().build();
        }

        try {
            String cleanUrl = urlSecurityValidator.extractAndCleanSingleUrl(url);
            SafeWebFetcher.ImageFetchResult result = safeWebFetcher.fetchImageBytes(cleanUrl);

            MediaType mediaType = MediaType.IMAGE_JPEG;
            if (result.contentType != null && !result.contentType.isBlank()) {
                try {
                    mediaType = MediaType.parseMediaType(result.contentType);
                } catch (Exception ignored) {}
            }

            return ResponseEntity.ok()
                    .header(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "*")
                    .header(HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS, "GET, OPTIONS")
                    .cacheControl(CacheControl.maxAge(Duration.ofDays(1)).cachePublic())
                    .contentType(mediaType)
                    .body(result.data);
        } catch (Exception e) {
            log.warn("Proxy failed for URL {}: {}", url, e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }
}
