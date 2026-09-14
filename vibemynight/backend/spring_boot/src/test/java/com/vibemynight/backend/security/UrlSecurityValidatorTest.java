package com.vibemynight.backend.security;

import com.vibemynight.backend.exception.BadRequestException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.net.InetAddress;
import java.net.URI;

import static org.junit.jupiter.api.Assertions.*;

class UrlSecurityValidatorTest {

    private UrlSecurityValidator validator;

    @BeforeEach
    void setUp() {
        validator = new UrlSecurityValidator();
    }

    @Test
    void testBlankUrlThrowsException() {
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl(""));
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl("   "));
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl(null));
    }

    @Test
    void testDisallowedSchemes() {
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl("ftp://example.com/event"));
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl("file:///etc/passwd"));
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl("javascript:alert(1)"));
    }

    @Test
    void testBlockedInternalHostnames() {
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl("http://localhost/event"));
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl("http://127.0.0.1:8080/event"));
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl("http://metadata.google.internal/computeMetadata/v1/"));
    }

    @Test
    void testDisallowedPorts() {
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl("http://example.com:22/event"));
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl("http://example.com:3306/event"));
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl("http://example.com:5432/event"));
    }

    @Test
    void testEmbeddedCredentialsBlocked() {
        assertThrows(BadRequestException.class, () -> validator.validateAndSanitizeUrl("http://admin:secret@example.com/event"));
    }

    @Test
    void testPrivateIpRangeDetection() throws Exception {
        assertTrue(validator.isPrivateOrRestrictedIp(InetAddress.getByName("127.0.0.1")));
        assertTrue(validator.isPrivateOrRestrictedIp(InetAddress.getByName("10.0.0.1")));
        assertTrue(validator.isPrivateOrRestrictedIp(InetAddress.getByName("192.168.1.1")));
        assertTrue(validator.isPrivateOrRestrictedIp(InetAddress.getByName("172.16.0.1")));
        assertTrue(validator.isPrivateOrRestrictedIp(InetAddress.getByName("169.254.169.254")));
        assertTrue(validator.isPrivateOrRestrictedIp(InetAddress.getByName("100.64.0.1")));
        assertTrue(validator.isPrivateOrRestrictedIp(InetAddress.getByName("::1")));
    }
}
