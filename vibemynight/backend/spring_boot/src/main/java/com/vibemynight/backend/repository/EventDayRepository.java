package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.EventDay;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EventDayRepository extends JpaRepository<EventDay, Long> {
    List<EventDay> findByEventIdOrderByDayNumberAsc(Long eventId);
    Optional<EventDay> findByEventIdAndDayNumber(Long eventId, Integer dayNumber);
    long countByEventId(Long eventId);
}
