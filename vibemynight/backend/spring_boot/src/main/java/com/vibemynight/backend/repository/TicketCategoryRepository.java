package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.TicketCategory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TicketCategoryRepository extends JpaRepository<TicketCategory, Long> {
    List<TicketCategory> findByEventDayIdAndStatus(Long eventDayId, ActiveStatus status);
    List<TicketCategory> findByEventDayId(Long eventDayId);
}
