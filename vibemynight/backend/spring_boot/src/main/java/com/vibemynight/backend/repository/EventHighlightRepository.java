package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.EventHighlight;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EventHighlightRepository extends JpaRepository<EventHighlight, Long> {
    List<EventHighlight> findByEventIdOrderBySortOrderAsc(Long eventId);
}
