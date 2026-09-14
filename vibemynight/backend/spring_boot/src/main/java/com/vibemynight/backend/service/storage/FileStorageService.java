package com.vibemynight.backend.service.storage;

import org.springframework.web.multipart.MultipartFile;

/**
 * Abstraction over where uploaded images actually live, per the spec's
 * "Version 1 can support local storage or configurable cloud storage" note.
 * Controllers and the rest of the app only ever see a public URL string -
 * swapping LocalFileStorageService for an S3/GCS-backed implementation later
 * requires no change outside this package.
 */
public interface FileStorageService {

    /**
     * Stores the file and returns a publicly reachable URL for it.
     * @param subfolder logical grouping, e.g. "events", "artists" - keeps uploads organized.
     */
    String store(MultipartFile file, String subfolder);

    /**
     * Stores raw bytes (e.g. from downloaded remote artwork) safely with MIME validation,
     * size bounds, and returns a publicly reachable local URL.
     */
    String storeBytes(byte[] data, String originalFilename, String subfolder);
}
