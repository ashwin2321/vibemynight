package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.EventDayArtist;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EventDayArtistRepository extends JpaRepository<EventDayArtist, Long> {
    List<EventDayArtist> findByEventDayIdOrderByPerformanceOrderAsc(Long eventDayId);
    Optional<EventDayArtist> findByEventDayIdAndIsPrimaryTrue(Long eventDayId);
    boolean existsByEventDayIdAndArtistId(Long eventDayId, Long artistId);
    void deleteByEventDayIdAndArtistId(Long eventDayId, Long artistId);
}
