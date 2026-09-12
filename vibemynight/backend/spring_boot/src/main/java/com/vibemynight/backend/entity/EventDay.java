package com.vibemynight.backend.entity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import jakarta.persistence.Index;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.BatchSize;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

/**
 * A single day within an Event. An Event can have any number of EventDays -
 * never assume a fixed count (e.g. 9 days for Navratri).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = false)
@ToString(exclude = {"event", "eventDayArtists", "ticketCategories"})
@Entity
@Table(
    name = "event_days",
    indexes = {
        @Index(name = "idx_event_days_event", columnList = "event_id"),
        @Index(name = "idx_event_days_date", columnList = "date"),
        @Index(name = "idx_event_days_status", columnList = "status")
    },
    uniqueConstraints = @UniqueConstraint(columnNames = {"event_id", "day_number"})
)
public class EventDay extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    @Column(name = "day_number", nullable = false)
    private Integer dayNumber;

    @Column(nullable = false)
    private LocalDate date;

    @Column(name = "day_name")
    private String dayName;

    @Column(name = "program_name")
    private String programName;

    @Column(name = "start_time")
    private LocalTime startTime;

    @Column(name = "end_time")
    private LocalTime endTime;

    private String venue;

    private String address;

    private String location;

    @Column(name = "google_maps_url")
    private String googleMapsUrl;

    @Column(length = 4000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private ActiveStatus status = ActiveStatus.ACTIVE;

    @Builder.Default
    @BatchSize(size = 20)
    @OneToMany(mappedBy = "eventDay", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("performanceOrder ASC")
    private List<EventDayArtist> eventDayArtists = new ArrayList<>();

    @Builder.Default
    @BatchSize(size = 20)
    @OneToMany(mappedBy = "eventDay", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<TicketCategory> ticketCategories = new ArrayList<>();
}
