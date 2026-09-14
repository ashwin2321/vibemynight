package com.vibemynight.backend.dto.importing;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UrlImportRequest {

    @NotBlank(message = "URL is required")
    private String url;
}
