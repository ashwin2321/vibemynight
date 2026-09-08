package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.SettingsPublicDto;
import com.vibemynight.backend.entity.Settings;
import com.vibemynight.backend.service.SettingsService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class SettingsController {

    private final SettingsService settingsService;

    // ---------- Public ----------

    @GetMapping("/api/v1/settings/public")
    public ApiResponse<SettingsPublicDto> getPublicSettings() {
        Settings s = settingsService.getSettings();
        SettingsPublicDto dto = SettingsPublicDto.builder()
                .websiteName(s.getWebsiteName())
                .logoUrl(s.getLogoUrl())
                .whatsappNumber(s.getWhatsappNumber())
                .phone(s.getPhone())
                .email(s.getEmail())
                .instagramUrl(s.getInstagramUrl())
                .facebookUrl(s.getFacebookUrl())
                .currency(s.getCurrency())
                .footerText(s.getFooterText())
                .build();
        return ApiResponse.ok(dto);
    }

    // ---------- Admin ----------

    @GetMapping("/api/v1/admin/settings")
    public ApiResponse<Settings> getSettings() {
        return ApiResponse.ok(settingsService.getSettings());
    }

    @PutMapping("/api/v1/admin/settings")
    public ApiResponse<Settings> updateSettings(@RequestBody Settings settings) {
        return ApiResponse.ok(settingsService.updateSettings(settings), "Settings updated");
    }
}
