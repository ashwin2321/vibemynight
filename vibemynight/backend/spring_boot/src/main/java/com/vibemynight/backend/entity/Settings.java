package com.vibemynight.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Single-row global site configuration (seeded by a migration). The WhatsApp number lives
 * here so it is never hardcoded in the frontend - the frontend fetches it via
 * GET /api/v1/settings/public.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = false)
@Entity
@Table(name = "settings")
public class Settings extends BaseEntity {

    @Column(name = "website_name", nullable = false)
    @Builder.Default
    private String websiteName = "VibeMyNight";

    @Column(name = "logo_url")
    private String logoUrl;

    /** International format, no plus sign, e.g. 917041615131 */
    @Column(name = "whatsapp_number", nullable = false)
    private String whatsappNumber;

    private String phone;

    private String email;

    @Column(name = "instagram_url")
    private String instagramUrl;

    @Column(name = "facebook_url")
    private String facebookUrl;

    @Column(nullable = false)
    @Builder.Default
    private String currency = "INR";

    @Column(name = "footer_text", length = 1000)
    private String footerText;
}
