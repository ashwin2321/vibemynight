package com.vibemynight.backend.service;

import com.vibemynight.backend.dto.EventDetailDto;
import com.vibemynight.backend.dto.importing.EventImportPreviewDto;
import org.springframework.web.multipart.MultipartFile;

public interface EventImportService {

    /**
     * Parses an uploaded Excel workbook, runs dry-run validations, matches existing artists/facilities,
     * and returns a full preview with warnings/errors without writing to the database.
     */
    EventImportPreviewDto parseAndValidate(MultipartFile file);

    /**
     * Generates a pre-formatted, styled Excel template with sample rows and column instructions.
     */
    byte[] generateExcelTemplate();

    /**
     * Executes the atomic creation of the complete event hierarchy within a single @Transactional boundary.
     * Rolls back completely if any failure occurs.
     */
    EventDetailDto confirmAndCreate(EventImportPreviewDto preview);
}
