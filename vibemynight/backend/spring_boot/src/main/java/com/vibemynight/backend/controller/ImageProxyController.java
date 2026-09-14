package com.vibemynight.backend.controller;

import com.vibemynight.backend.util.SafeWebFetcher;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api/v1/public/images")
@RequiredArgsConstructor
public class ImageProxyController {

    private final SafeWebFetcher safeWebFetcher;

    /**
     * Public image proxy to safely stream third-party event posters and banners
     * to frontend clients with proper CORS headers, avoiding CanvasKit / hotlink CORS errors.
     */
    @GetMapping("/proxy")
    public ResponseEntity<byte[]> proxyImage(@RequestParam("url") String url) {
        SafeWebFetcher.ImageFetchResult result = safeWebFetcher.fetchImageBytes(url);

        MediaType mediaType;
        try {
            mediaType = MediaType.parseMediaType(result.contentType);
        } catch (Exception e) {
            mediaType = MediaType.IMAGE_JPEG;
        }

        return ResponseEntity.ok()
                .contentType(mediaType)
                .header(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "*")
                .header(HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS, "GET, OPTIONS")
                .cacheControl(CacheControl.maxAge(7, TimeUnit.DAYS).cachePublic())
                .body(result.data);
    }
}
