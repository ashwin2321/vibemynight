package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.Event;
import com.vibemynight.backend.entity.EventStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;
import java.util.Optional;

public interface EventRepository extends JpaRepository<Event, Long>, JpaSpecificationExecutor<Event> {
    @EntityGraph(attributePaths = {"eventDays"})
    Optional<Event> findBySlug(String slug);

    boolean existsBySlug(String slug);

    @EntityGraph(attributePaths = {"eventDays"})
    List<Event> findByStatus(EventStatus status);

    @EntityGraph(attributePaths = {"eventDays"})
    Page<Event> findByStatus(EventStatus status, Pageable pageable);

    @EntityGraph(attributePaths = {"eventDays"})
    List<Event> findByFeaturedTrueAndStatus(EventStatus status);
}
