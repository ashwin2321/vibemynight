package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.EventDetailDto;
import com.vibemynight.backend.dto.importing.EventImportPreviewDto;
import com.vibemynight.backend.service.EventImportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/admin/events/import")
@RequiredArgsConstructor
public class EventImportController {

    private final EventImportService eventImportService;

    /**
     * Upload an Excel workbook (.xlsx) to parse, validate, and preview the event hierarchy
     * without writing any data to the database.
     */
    @PostMapping(value = "/parse", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<EventImportPreviewDto> parseAndValidate(@RequestParam("file") MultipartFile file) {
        EventImportPreviewDto preview = eventImportService.parseAndValidate(file);
        return ApiResponse.ok(preview, "Event file parsed and validated successfully");
    }

    /**
     * Download the official Excel event import template pre-populated with sample 3-day data and column formatting.
     */
    @GetMapping("/template")
    public ResponseEntity<byte[]> downloadTemplate() {
        byte[] excelBytes = eventImportService.generateExcelTemplate();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"vibemynight_event_import_template.xlsx\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelBytes);
    }

    /**
     * Atomically creates the entire event, all days, passes, artists, and facilities
     * in a single @Transactional operation.
     */
    @PostMapping("/confirm")
    public ApiResponse<EventDetailDto> confirmAndCreate(@RequestBody EventImportPreviewDto preview) {
        EventDetailDto createdEvent = eventImportService.confirmAndCreate(preview);
        return ApiResponse.ok(createdEvent, "Event imported and created successfully!");
    }
}
