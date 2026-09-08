package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.Facility;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FacilityRepository extends JpaRepository<Facility, Long> {
    List<Facility> findByStatus(ActiveStatus status);
    boolean existsByName(String name);
}
