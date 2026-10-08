package com.vibemynight.backend.service;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;

public interface SeoService {
    boolean isCrawler(HttpServletRequest request);
    String generateEventHtml(String slug, HttpServletRequest request);
    String generateArtistHtml(String slug, HttpServletRequest request);
    String generateCityHtml(String city, HttpServletRequest request);
    String generateCategoryHtml(String category, HttpServletRequest request);
    String generateHomeHtml(HttpServletRequest request);
    String generateMainSitemapXml();
    String generateEventsSitemapXml();
    String generateArtistsSitemapXml();
    String generateCitiesSitemapXml();
    String generateRobotsTxt();
    Map<String, Object> getEventSeoData(String slug);
    Map<String, Object> getSeoHealth();
}
