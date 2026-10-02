package com.vibemynight.backend.dto.importing;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class StagedEventDto {

    private Integer id;
    private String source;
    private String source_event_id;
    private String source_url;

    private String title;
    private String description;

    private String enhanced_title;
    private String catchy_description;

    private List<String> highlights;
    private List<String> genre_tags;
    private List<String> seo_keywords;
    private String whatsapp_teaser;

    private String poster_url;
    private String banner_url;

    private String event_start_date;
    private String event_end_date;
    private String start_time;
    private String end_time;

    private String venue_name;
    private String venue_address;
    private String city;
    private String state;

    private Double min_ticket_price;
    private Double max_ticket_price;
    private String currency;

    private String status;
    private Integer duplicate_of;
    private Boolean ai_processed;
    private String ai_error;
}
