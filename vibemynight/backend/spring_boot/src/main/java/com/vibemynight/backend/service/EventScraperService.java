package com.vibemynight.backend.service;

import com.vibemynight.backend.dto.importing.EventImportPreviewDto;

public interface EventScraperService {

    /**
     * Safely fetches and parses an event from a supported URL (BookMyShow, District/Insider, Showmates, or Generic),
     * returning a standardized EventImportPreviewDto ready for admin inspection and atomic creation.
     */
    EventImportPreviewDto scrapeEventFromUrl(String url);
}
