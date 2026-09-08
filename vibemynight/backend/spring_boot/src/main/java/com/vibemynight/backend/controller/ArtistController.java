package com.vibemynight.backend.controller;

import com.vibemynight.backend.dto.ApiResponse;
import com.vibemynight.backend.dto.ArtistDto;
import com.vibemynight.backend.dto.CreateArtistRequest;
import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.Artist;
import com.vibemynight.backend.entity.ArtistType;
import com.vibemynight.backend.mapper.ArtistMapper;
import com.vibemynight.backend.service.ArtistService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class ArtistController {

    private final ArtistService artistService;
    private final ArtistMapper artistMapper;

    // ---------- Public ----------

    @GetMapping("/api/v1/artists")
    public ApiResponse<List<ArtistDto>> list() {
        List<ArtistDto> artists = artistService.findByStatus(ActiveStatus.ACTIVE).stream()
                .map(artistMapper::toDto)
                .toList();
        return ApiResponse.ok(artists);
    }

    @GetMapping("/api/v1/artists/{id}")
    public ApiResponse<ArtistDto> getById(@PathVariable Long id) {
        return ApiResponse.ok(artistMapper.toDto(artistService.getById(id)));
    }

    // ---------- Admin ----------

    @GetMapping("/api/v1/admin/artists")
    public ApiResponse<List<ArtistDto>> listAllForAdmin() {
        List<ArtistDto> artists = artistService.findAll().stream()
                .map(artistMapper::toDto)
                .toList();
        return ApiResponse.ok(artists);
    }

    @PostMapping("/api/v1/admin/artists")
    public ApiResponse<ArtistDto> create(@Valid @RequestBody CreateArtistRequest request) {
        Artist artist = Artist.builder()
                .name(request.getName())
                .slug(request.getSlug())
                .photoUrl(request.getPhotoUrl())
                .type(ArtistType.valueOf(request.getType().toUpperCase()))
                .shortBio(request.getShortBio())
                .fullBio(request.getFullBio())
                .instagramUrl(request.getInstagramUrl())
                .facebookUrl(request.getFacebookUrl())
                .youtubeUrl(request.getYoutubeUrl())
                .featured(request.isFeatured())
                .status(ActiveStatus.ACTIVE)
                .build();
        return ApiResponse.ok(artistMapper.toDto(artistService.create(artist)), "Artist created");
    }

    @PutMapping("/api/v1/admin/artists/{id}")
    public ApiResponse<ArtistDto> update(@PathVariable Long id, @Valid @RequestBody CreateArtistRequest request) {
        Artist artist = Artist.builder()
                .name(request.getName())
                .slug(request.getSlug())
                .photoUrl(request.getPhotoUrl())
                .type(ArtistType.valueOf(request.getType().toUpperCase()))
                .shortBio(request.getShortBio())
                .fullBio(request.getFullBio())
                .instagramUrl(request.getInstagramUrl())
                .facebookUrl(request.getFacebookUrl())
                .youtubeUrl(request.getYoutubeUrl())
                .featured(request.isFeatured())
                .build();
        return ApiResponse.ok(artistMapper.toDto(artistService.update(id, artist)), "Artist updated");
    }

    @DeleteMapping("/api/v1/admin/artists/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        artistService.delete(id);
        return ApiResponse.ok(null, "Artist deleted");
    }

    /** Body: { "status": "ACTIVE" | "INACTIVE" } */
    @PatchMapping("/api/v1/admin/artists/{id}/status")
    public ApiResponse<ArtistDto> changeStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        ActiveStatus status = ActiveStatus.valueOf(body.get("status").toUpperCase());
        return ApiResponse.ok(artistMapper.toDto(artistService.changeStatus(id, status)), "Artist status updated");
    }
}
