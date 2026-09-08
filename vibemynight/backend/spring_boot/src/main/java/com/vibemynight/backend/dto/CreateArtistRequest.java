package com.vibemynight.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateArtistRequest {

    @NotBlank(message = "Artist name is required")
    private String name;

    @NotBlank(message = "Slug is required")
    private String slug;

    private String photoUrl;

    @NotNull(message = "Artist type is required")
    private String type;

    private String shortBio;
    private String fullBio;
    private String instagramUrl;
    private String facebookUrl;
    private String youtubeUrl;
    private boolean featured;
}
