package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.Artist;
import com.vibemynight.backend.exception.ConflictException;
import com.vibemynight.backend.exception.ResourceNotFoundException;
import com.vibemynight.backend.repository.ArtistRepository;
import com.vibemynight.backend.service.ArtistService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ArtistServiceImpl implements ArtistService {

    private final ArtistRepository artistRepository;

    @Override
    @Transactional(readOnly = true)
    public List<Artist> findAll() {
        return artistRepository.findAll();
    }

    @Override
    @Transactional(readOnly = true)
    public List<Artist> findByStatus(ActiveStatus status) {
        return artistRepository.findByStatus(status);
    }

    @Override
    @Transactional(readOnly = true)
    public Artist getById(Long id) {
        return artistRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Artist not found: " + id));
    }

    @Override
    @Transactional(readOnly = true)
    public Artist getBySlug(String slug) {
        return artistRepository.findBySlug(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Artist not found: " + slug));
    }

    @Override
    @Transactional
    public Artist create(Artist artist) {
        if (artistRepository.existsBySlug(artist.getSlug())) {
            throw new ConflictException("An artist with this slug already exists");
        }
        return artistRepository.save(artist);
    }

    @Override
    @Transactional
    public Artist update(Long id, Artist updated) {
        Artist existing = getById(id);
        existing.setName(updated.getName());
        existing.setSlug(updated.getSlug());
        existing.setPhotoUrl(updated.getPhotoUrl());
        existing.setType(updated.getType());
        existing.setShortBio(updated.getShortBio());
        existing.setFullBio(updated.getFullBio());
        existing.setInstagramUrl(updated.getInstagramUrl());
        existing.setFacebookUrl(updated.getFacebookUrl());
        existing.setYoutubeUrl(updated.getYoutubeUrl());
        existing.setFeatured(updated.isFeatured());
        return artistRepository.save(existing);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        artistRepository.delete(getById(id));
    }

    @Override
    @Transactional
    public Artist changeStatus(Long id, ActiveStatus status) {
        Artist artist = getById(id);
        artist.setStatus(status);
        return artistRepository.save(artist);
    }
}
