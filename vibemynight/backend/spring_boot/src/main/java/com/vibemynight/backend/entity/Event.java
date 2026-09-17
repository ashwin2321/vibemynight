package com.vibemynight.backend.entity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import jakarta.persistence.Index;
import org.hibernate.annotations.BatchSize;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = false)
@ToString(exclude = {"eventDays", "galleryImages", "highlights", "rules"})
@Entity
@Table(
    name = "events",
    indexes = {
        @Index(name = "idx_events_slug", columnList = "slug"),
        @Index(name = "idx_events_status", columnList = "status"),
        @Index(name = "idx_events_featured", columnList = "featured"),
        @Index(name = "idx_events_start_date", columnList = "start_date"),
        @Index(name = "idx_events_status_start", columnList = "status, start_date")
    }
)
public class Event extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String slug;

    @Column(name = "main_image")
    private String mainImage;

    private String banner;

    private String thumbnail;

    @Column(length = 4000)
    private String description;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    private String venue;

    private String address;

    private String city;

    private String location;

    @Column(name = "google_maps_url")
    private String googleMapsUrl;

    private String organizer;

    @Column(name = "contact_number")
    private String contactNumber;

    private String email;

    @Builder.Default
    @Column(name = "featured")
    private Boolean featured = Boolean.FALSE;

    @Builder.Default
    @Column(name = "show_in_hero")
    private Boolean showInHero = Boolean.FALSE;

    public boolean isFeatured() {
        return featured != null && featured;
    }

    public void setFeatured(Boolean featured) {
        this.featured = featured != null ? featured : Boolean.FALSE;
    }

    public boolean isShowInHero() {
        return showInHero != null && showInHero;
    }

    public void setShowInHero(Boolean showInHero) {
        this.showInHero = showInHero != null ? showInHero : Boolean.FALSE;
    }

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private EventStatus status = EventStatus.DRAFT;

    @Builder.Default
    @BatchSize(size = 20)
    @OneToMany(mappedBy = "event", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("dayNumber ASC")
    private List<EventDay> eventDays = new ArrayList<>();

    @Builder.Default
    @BatchSize(size = 20)
    @OneToMany(mappedBy = "event", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("sortOrder ASC")
    private List<EventGallery> galleryImages = new ArrayList<>();

    @Builder.Default
    @BatchSize(size = 20)
    @OneToMany(mappedBy = "event", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<EventHighlight> highlights = new ArrayList<>();

    @Builder.Default
    @BatchSize(size = 20)
    @OneToMany(mappedBy = "event", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<EventRule> rules = new ArrayList<>();
}
