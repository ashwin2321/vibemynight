package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.Settings;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettingsRepository extends JpaRepository<Settings, Long> {
}
