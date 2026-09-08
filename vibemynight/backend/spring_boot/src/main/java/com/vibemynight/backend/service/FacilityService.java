package com.vibemynight.backend.service;

import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.Facility;

import java.util.List;

public interface FacilityService {
    List<Facility> findAll();
    List<Facility> findByStatus(ActiveStatus status);
    Facility getById(Long id);
    Facility create(Facility facility);
    Facility update(Long id, Facility facility);
    void delete(Long id);
    Facility changeStatus(Long id, ActiveStatus status);
}
