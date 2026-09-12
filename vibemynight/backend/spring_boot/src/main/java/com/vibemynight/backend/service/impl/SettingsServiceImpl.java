package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.entity.Settings;
import com.vibemynight.backend.repository.SettingsRepository;
import com.vibemynight.backend.service.SettingsService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class SettingsServiceImpl implements SettingsService {

    private final SettingsRepository settingsRepository;

    @Value("${app.whatsapp.number}")
    private String defaultWhatsappNumber;

    @Override
    @Transactional
    @Cacheable(value = "settings", key = "'public'")
    public Settings getSettings() {
        return settingsRepository.findAll().stream()
                .findFirst()
                .orElseGet(() -> settingsRepository.save(
                        Settings.builder()
                                .websiteName("VibeMyNight")
                                .whatsappNumber(defaultWhatsappNumber)
                                .currency("INR")
                                .build()));
    }

    @Override
    @Transactional
    @CacheEvict(value = "settings", allEntries = true)
    public Settings updateSettings(Settings updated) {
        Settings existing = getSettings();
        existing.setWebsiteName(updated.getWebsiteName());
        existing.setLogoUrl(updated.getLogoUrl());
        existing.setWhatsappNumber(updated.getWhatsappNumber());
        existing.setPhone(updated.getPhone());
        existing.setEmail(updated.getEmail());
        existing.setInstagramUrl(updated.getInstagramUrl());
        existing.setFacebookUrl(updated.getFacebookUrl());
        existing.setCurrency(updated.getCurrency());
        existing.setFooterText(updated.getFooterText());
        return settingsRepository.save(existing);
    }
}
