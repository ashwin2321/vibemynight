package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;
import java.util.Optional;

public interface EventRepository extends JpaRepository<Event, Long>, JpaSpecificationExecutor<Event> {
    Optional<Event> findBySlug(String slug);
    boolean existsBySlug(String slug);
    List<Event> findByStatus(EventStatus status);
    List<Event> findByFeaturedTrueAndStatus(EventStatus status);
}
