package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GalleryImageResponse {
    private Long id;
    private String imageUrl;
    private String caption;
    private Integer sortOrder;
}
