package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.Facility;
import com.vibemynight.backend.exception.ConflictException;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.repository.FacilityRepository;
import com.vibemynight.backend.service.FacilityService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FacilityServiceImpl implements FacilityService {

    private final FacilityRepository facilityRepository;

    @Override
    @Transactional(readOnly = true)
    public List<Facility> findAll() {
        return facilityRepository.findAll();
    }

    @Override
    @Transactional(readOnly = true)
    public List<Facility> findByStatus(ActiveStatus status) {
        return facilityRepository.findByStatus(status);
    }

    @Override
    @Transactional(readOnly = true)
    public Facility getById(Long id) {
        return facilityRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Facility not found: " + id));
    }

    @Override
    @Transactional
    public Facility create(Facility facility) {
        if (facilityRepository.existsByName(facility.getName())) {
            throw new ConflictException("A facility with this name already exists");
        }
        return facilityRepository.save(facility);
    }

    @Override
    @Transactional
    public Facility update(Long id, Facility updated) {
        Facility existing = getById(id);
        existing.setName(updated.getName());
        existing.setIcon(updated.getIcon());
        existing.setDescription(updated.getDescription());
        return facilityRepository.save(existing);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        facilityRepository.delete(getById(id));
    }

    @Override
    @Transactional
    public Facility changeStatus(Long id, ActiveStatus status) {
        Facility facility = getById(id);
        facility.setStatus(status);
        return facilityRepository.save(facility);
    }
}
