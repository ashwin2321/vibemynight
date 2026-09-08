package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SettingsPublicDto {
    private String websiteName;
    private String logoUrl;
    private String whatsappNumber;
    private String phone;
    private String email;
    private String instagramUrl;
    private String facebookUrl;
    private String currency;
    private String footerText;
}
