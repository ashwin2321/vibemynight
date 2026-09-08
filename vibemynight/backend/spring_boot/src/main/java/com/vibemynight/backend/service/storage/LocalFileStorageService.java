package com.vibemynight.backend.service.storage;

import com.vibemynight.backend.exception.BadRequestException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Version-1 storage: saves to disk under app.image-storage.local-path and
 * serves it back via the /uploads/** static mapping (see
 * WebMvcConfig#addResourceHandlers). Fine for a single-server deployment;
 * swap for an S3/GCS-backed FileStorageService without touching callers if
 * the app ever needs multi-server/CDN-backed storage.
 */
@Service
public class LocalFileStorageService implements FileStorageService {

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of("jpg", "jpeg", "png", "webp", "gif");
    private static final long MAX_FILE_SIZE_BYTES = 8L * 1024 * 1024; // 8MB

    @Value("${app.image-storage.local-path}")
    private String localPath;

    @Value("${app.image-storage.url}")
    private String publicBaseUrl;

    @Override
    public String store(MultipartFile file, String subfolder) {
        if (file.isEmpty()) {
            throw new BadRequestException("Uploaded file is empty");
        }
        if (file.getSize() > MAX_FILE_SIZE_BYTES) {
            throw new BadRequestException("File is too large (max 8MB)");
        }

        String original = file.getOriginalFilename() != null ? file.getOriginalFilename() : "upload";
        String extension = getExtension(original);
        if (!ALLOWED_EXTENSIONS.contains(extension.toLowerCase())) {
            throw new BadRequestException("Only image files are allowed (jpg, jpeg, png, webp, gif)");
        }

        String safeSubfolder = (subfolder == null || subfolder.isBlank()) ? "misc" : subfolder.replaceAll("[^a-zA-Z0-9_-]", "");
        String filename = UUID.randomUUID() + "." + extension;

        try {
            Path dir = Paths.get(localPath, safeSubfolder);
            Files.createDirectories(dir);
            Path target = dir.resolve(filename);
            Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new RuntimeException("Failed to store uploaded file", e);
        }

        String base = publicBaseUrl.endsWith("/") ? publicBaseUrl.substring(0, publicBaseUrl.length() - 1) : publicBaseUrl;
        return base + "/" + safeSubfolder + "/" + filename;
    }

    private String getExtension(String filename) {
        List<String> parts = List.of(filename.split("\\."));
        return parts.size() > 1 ? parts.get(parts.size() - 1) : "";
    }
}
