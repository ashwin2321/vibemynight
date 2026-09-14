package com.vibemynight.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.resource.PathResourceResolver;

import java.io.IOException;
import java.util.Set;
import java.util.concurrent.TimeUnit;

@Configuration
public class WebSpaConfig implements WebMvcConfigurer {

    private static final Set<String> STATIC_EXTENSIONS = Set.of(
            "js", "mjs", "css", "png", "jpg", "jpeg", "gif", "ico", "svg", "webp",
            "json", "map", "wasm", "ttf", "otf", "woff", "woff2", "mp4", "webm"
    );

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/**")
                .addResourceLocations("classpath:/static/")
                .setCacheControl(CacheControl.maxAge(7, TimeUnit.DAYS).cachePublic())
                .resourceChain(true)
                .addResolver(new PathResourceResolver() {
                    @Override
                    protected Resource getResource(String resourcePath, Resource location) throws IOException {
                        if (resourcePath.startsWith("api/") || resourcePath.startsWith("actuator/") || resourcePath.startsWith("uploads/")) {
                            return null;
                        }

                        Resource requestedResource = location.createRelative(resourcePath);
                        if (requestedResource.exists() && requestedResource.isReadable()) {
                            return requestedResource;
                        }

                        // If the request points to a specific static file (has extension) and was not found, return 404 (null)
                        // NEVER return index.html for missing JavaScript, CSS, or binary assets!
                        int lastDotIndex = resourcePath.lastIndexOf('.');
                        if (lastDotIndex != -1 && lastDotIndex < resourcePath.length() - 1) {
                            String extension = resourcePath.substring(lastDotIndex + 1).toLowerCase();
                            if (STATIC_EXTENSIONS.contains(extension)) {
                                return null;
                            }
                        }

                        // Fall back to SPA index.html for client-side routing paths (e.g. /events, /admin/login)
                        return new ClassPathResource("/static/index.html");
                    }
                });
    }
}
