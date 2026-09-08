package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.UploadResponse;
import com.vibemynight.backend.service.storage.FileStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Admin-only image upload - covers "Admin can upload artist photo" /
 * event image / gallery upload requirements. Returns a URL the admin app
 * then puts straight into the relevant photoUrl/mainImage/imageUrl field
 * on the normal Create/Update Event|Artist|Gallery request - this endpoint
 * only ever deals with the file, never with which entity it belongs to.
 */
@RestController
@RequiredArgsConstructor
public class UploadController {

    private final FileStorageService fileStorageService;

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
}
