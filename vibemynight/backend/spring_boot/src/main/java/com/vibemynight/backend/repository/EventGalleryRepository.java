package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.EventGallery;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EventGalleryRepository extends JpaRepository<EventGallery, Long> {
    List<EventGallery> findByEventIdOrderBySortOrderAsc(Long eventId);
}
