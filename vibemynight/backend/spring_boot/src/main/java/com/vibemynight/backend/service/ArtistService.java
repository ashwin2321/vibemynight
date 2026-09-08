package com.vibemynight.backend.service;

import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.Artist;

import java.util.List;

public interface ArtistService {
    List<Artist> findAll();
    List<Artist> findByStatus(ActiveStatus status);
    Artist getById(Long id);
    Artist getBySlug(String slug);
    Artist create(Artist artist);
    Artist update(Long id, Artist artist);
    void delete(Long id);
    Artist changeStatus(Long id, ActiveStatus status);
}
