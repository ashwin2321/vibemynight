package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.importing.StagedEventImportRequest;
import com.vibemynight.backend.dto.importing.StagedImportBatchResultDto;
import com.vibemynight.backend.service.StagedEventImportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/v1/admin/events")
@RequiredArgsConstructor
public class StagedEventImportController {

    private final StagedEventImportService stagedEventImportService;

    /**
     * Phase 2: Secure Production Import Bridge Endpoint.
     * Allows an authenticated Administrator to explicitly import approved staged events into the production database.
     */
    @PostMapping("/import-staged")
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponse<StagedImportBatchResultDto> importStagedEvents(
            @Valid @RequestBody StagedEventImportRequest request,
            Authentication authentication
    ) {
        String adminUser = (authentication != null && authentication.getName() != null)
                ? authentication.getName()
                : "admin";

        log.info("REST POST /api/v1/admin/events/import-staged triggered by admin '{}'", adminUser);
        StagedImportBatchResultDto result = stagedEventImportService.importStagedEvents(request, adminUser);
        return ApiResponse.ok(result, "Staged events import batch completed");
    }
}
