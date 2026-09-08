package com.vibemynight.backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;

/**
 * Maps GET /uploads/** to files saved by LocalFileStorageService on disk.
 * Without this, an uploaded image's returned URL would 404 - the file
 * would be saved but never servable.
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Value("${app.image-storage.local-path}")
    private String localPath;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String absolutePath = new File(localPath).getAbsolutePath();
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + absolutePath + File.separator);
    }
}
