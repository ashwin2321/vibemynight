package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.EventDayFacility;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EventDayFacilityRepository extends JpaRepository<EventDayFacility, Long> {
    List<EventDayFacility> findByEventDayId(Long eventDayId);
    void deleteByEventDayIdAndFacilityId(Long eventDayId, Long facilityId);
}
