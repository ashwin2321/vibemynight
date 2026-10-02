package com.vibemynight.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.importing.StagedEventImportRequest;
import com.vibemynight.backend.dto.importing.StagedEventImportResultItemDto;
import com.vibemynight.backend.dto.importing.StagedImportBatchResultDto;
import com.vibemynight.backend.service.StagedEventImportService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class StagedEventImportControllerTest {

    @Mock
    private StagedEventImportService stagedEventImportService;

    private StagedEventImportController controller;

    @BeforeEach
    void setUp() {
        controller = new StagedEventImportController(stagedEventImportService);
    }

    @Test
    void importStagedEvents_AdminUser_ReturnsBatchResults() {
        StagedEventImportRequest request = StagedEventImportRequest.builder()
                .stagedEventIds(List.of(101, 102))
                .build();

        StagedImportBatchResultDto mockResult = StagedImportBatchResultDto.builder()
                .success(true)
                .totalRequested(2)
                .imported(2)
                .results(List.of(
                        StagedEventImportResultItemDto.builder().stagedEventId(101).status("IMPORTED").productionEventId(5001L).build(),
                        StagedEventImportResultItemDto.builder().stagedEventId(102).status("IMPORTED").productionEventId(5002L).build()
                ))
                .build();

        when(stagedEventImportService.importStagedEvents(eq(request), eq("admin_master"))).thenReturn(mockResult);

        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                "admin_master",
                null,
                List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))
        );

        ApiResponse<StagedImportBatchResultDto> response = controller.importStagedEvents(request, auth);

        assertNotNull(response);
        assertTrue(response.isSuccess());
        assertEquals(2, response.getData().getImported());
        verify(stagedEventImportService, times(1)).importStagedEvents(eq(request), eq("admin_master"));
    }
}
