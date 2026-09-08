package com.vibemynight.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = false)
@Entity
@Table(name = "artists")
public class Artist extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String slug;

    @Column(name = "photo_url")
    private String photoUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ArtistType type;

    @Column(name = "short_bio", length = 500)
    private String shortBio;

    @Column(name = "full_bio", length = 4000)
    private String fullBio;

    @Column(name = "instagram_url")
    private String instagramUrl;

    @Column(name = "facebook_url")
    private String facebookUrl;

    @Column(name = "youtube_url")
    private String youtubeUrl;

    @Builder.Default
    private boolean featured = false;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private ActiveStatus status = ActiveStatus.ACTIVE;
}
