package com.vibemynight.backend.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager();

        // Default fallback builder
        cacheManager.setCaffeine(Caffeine.newBuilder()
                .maximumSize(200)
                .expireAfterWrite(120, TimeUnit.SECONDS)
                .recordStats());

        // Granular cache policies
        cacheManager.registerCustomCache("events",
                Caffeine.newBuilder()
                        .maximumSize(200)
                        .expireAfterWrite(120, TimeUnit.SECONDS)
                        .recordStats()
                        .build());

        cacheManager.registerCustomCache("event_details",
                Caffeine.newBuilder()
                        .maximumSize(500)
                        .expireAfterWrite(120, TimeUnit.SECONDS)
                        .recordStats()
                        .build());

        cacheManager.registerCustomCache("artists",
                Caffeine.newBuilder()
                        .maximumSize(200)
                        .expireAfterWrite(300, TimeUnit.SECONDS)
                        .recordStats()
                        .build());

        cacheManager.registerCustomCache("facilities",
                Caffeine.newBuilder()
                        .maximumSize(100)
                        .expireAfterWrite(600, TimeUnit.SECONDS)
                        .recordStats()
                        .build());

        cacheManager.registerCustomCache("settings",
                Caffeine.newBuilder()
                        .maximumSize(10)
                        .expireAfterWrite(600, TimeUnit.SECONDS)
                        .recordStats()
                        .build());

        cacheManager.registerCustomCache("settings_public",
                Caffeine.newBuilder()
                        .maximumSize(10)
                        .expireAfterWrite(600, TimeUnit.SECONDS)
                        .recordStats()
                        .build());

        return cacheManager;
    }
}

