package com.vibemynight.backend.config;

import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.AdminRole;
import com.vibemynight.backend.entity.User;
import com.vibemynight.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Creates the first admin user from ADMIN_SEED_EMAIL / ADMIN_SEED_PASSWORD env vars
 * if the users table is empty. No real password is committed - see .env.example.
 * Safe to leave enabled: it only ever acts when there are zero users.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${ADMIN_SEED_EMAIL:}")
    private String seedEmail;

    @Value("${ADMIN_SEED_PASSWORD:}")
    private String seedPassword;

    @Override
    public void run(String... args) {
        if (userRepository.count() > 0) {
            return;
        }
        if (seedEmail == null || seedEmail.isBlank() || seedPassword == null || seedPassword.isBlank()) {
            log.warn("No admin users exist and ADMIN_SEED_EMAIL/ADMIN_SEED_PASSWORD are not set - "
                    + "set them in your environment and restart to bootstrap the first admin account.");
            return;
        }

        User admin = User.builder()
                .name("VibeMyNight Admin")
                .email(seedEmail)
                .passwordHash(passwordEncoder.encode(seedPassword))
                .role(AdminRole.ADMIN)
                .status(ActiveStatus.ACTIVE)
                .build();
        userRepository.save(admin);
        log.info("Seeded initial admin user: {}", seedEmail);
    }
}
