package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.EventFacility;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EventFacilityRepository extends JpaRepository<EventFacility, Long> {
    List<EventFacility> findByEventId(Long eventId);
    void deleteByEventIdAndFacilityId(Long eventId, Long facilityId);
}
