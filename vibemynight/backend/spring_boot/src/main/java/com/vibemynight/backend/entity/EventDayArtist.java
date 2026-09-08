package com.vibemynight.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalTime;

/**
 * Join entity: an EventDay can feature multiple Artists (one primary + additional).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = false)
@Entity
@Table(name = "event_day_artists", uniqueConstraints = @UniqueConstraint(columnNames = {"event_day_id", "artist_id"}))
public class EventDayArtist extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_day_id", nullable = false)
    private EventDay eventDay;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "artist_id", nullable = false)
    private Artist artist;

    @Column(name = "is_primary", nullable = false)
    @Builder.Default
    private boolean isPrimary = false;

    @Column(name = "performance_order")
    private Integer performanceOrder;

    @Column(name = "performance_start_time")
    private LocalTime performanceStartTime;

    @Column(name = "performance_end_time")
    private LocalTime performanceEndTime;
}
