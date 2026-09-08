package com.vibemynight.backend.service;

import com.vibemynight.backend.entity.Settings;

public interface SettingsService {
    Settings getSettings();
    Settings updateSettings(Settings settings);
}
