package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ArtistDto {
    private Long id;
    private String name;
    private String slug;
    private String photoUrl;
    private String type;
    private String shortBio;
    private String fullBio;
    private String instagramUrl;
    private String facebookUrl;
    private String youtubeUrl;
    private boolean featured;
    private String status;
}
