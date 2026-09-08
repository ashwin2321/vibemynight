package com.vibemynight.backend.repository;

import com.vibemynight.backend.entity.Artist;
import com.vibemynight.backend.entity.ActiveStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;
import java.util.Optional;

public interface ArtistRepository extends JpaRepository<Artist, Long>, JpaSpecificationExecutor<Artist> {
    Optional<Artist> findBySlug(String slug);
    boolean existsBySlug(String slug);
    List<Artist> findByStatus(ActiveStatus status);
    List<Artist> findByFeaturedTrueAndStatus(ActiveStatus status);
}
