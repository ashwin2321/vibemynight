package com.vibemynight.backend.mapper;

import com.vibemynight.backend.dto.ArtistDto;
import com.vibemynight.backend.entity.Artist;
import org.springframework.stereotype.Component;

@Component
public class ArtistMapper {

    public ArtistDto toDto(Artist artist) {
        if (artist == null) return null;
        return ArtistDto.builder()
                .id(artist.getId())
                .name(artist.getName())
                .slug(artist.getSlug())
                .photoUrl(artist.getPhotoUrl())
                .type(artist.getType().name())
                .shortBio(artist.getShortBio())
                .fullBio(artist.getFullBio())
                .instagramUrl(artist.getInstagramUrl())
                .facebookUrl(artist.getFacebookUrl())
                .youtubeUrl(artist.getYoutubeUrl())
                .featured(artist.isFeatured())
                .status(artist.getStatus().name())
                .build();
    }
}
