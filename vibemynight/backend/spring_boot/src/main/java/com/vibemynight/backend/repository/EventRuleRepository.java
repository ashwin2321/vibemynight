package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.EventRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EventRuleRepository extends JpaRepository<EventRule, Long> {
    List<EventRule> findByEventIdOrderBySortOrderAsc(Long eventId);
}
