package com.vibemynight.backend.service;

import com.vibemynight.backend.dto.importing.StagedEventDto;
import com.vibemynight.backend.dto.importing.StagedEventImportRequest;
import com.vibemynight.backend.dto.importing.StagedEventImportResultItemDto;
import com.vibemynight.backend.dto.importing.StagedImportBatchResultDto;

public interface StagedEventImportService {

    /**
     * Imports a batch of approved staged event IDs into the production database.
     * Each event import executes in an independently atomic transaction.
     */
    StagedImportBatchResultDto importStagedEvents(StagedEventImportRequest request, String adminUsername);

    /**
     * Atomically imports a single staged event DTO into production.
     */
    StagedEventImportResultItemDto importSingleStagedEvent(StagedEventDto stagedEvent, String adminUsername);
}
