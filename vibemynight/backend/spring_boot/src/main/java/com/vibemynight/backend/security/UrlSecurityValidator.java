package com.vibemynight.backend.security;

import com.vibemynight.backend.exception.BadRequestException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.net.Inet4Address;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.URI;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * SSRF (Server-Side Request Forgery) protection validator for outgoing web requests.
 * Ensures the system only fetches from authorized, public web addresses.
 */
@Slf4j
@Component
public class UrlSecurityValidator {

    private static final Set<String> ALLOWED_SCHEMES = Set.of("http", "https");
    private static final Set<Integer> ALLOWED_PORTS = Set.of(80, 443, 8080, 8443);

    private static final List<String> BLOCKED_HOSTNAMES = List.of(
            "localhost",
            "localhost.localdomain",
            "ip6-localhost",
            "ip6-loopback",
            "metadata.google.internal",
            "instance-data",
            "169.254.169.254"
    );

    /**
     * Extracts and cleans the best event URL from potentially dirty or concatenated input strings.
     */
    public String extractAndCleanSingleUrl(String rawInput) {
        if (rawInput == null || rawInput.isBlank()) {
            throw new BadRequestException("Event URL cannot be blank.");
        }

        String input = rawInput.trim();

        // 1. Regex to find all http/https URLs in the input
        Pattern urlPattern = Pattern.compile("https?://[^\\s\"'<>]+", Pattern.CASE_INSENSITIVE);
        Matcher matcher = urlPattern.matcher(input);
        List<String> foundUrls = new ArrayList<>();
        while (matcher.find()) {
            String u = matcher.group();
            // In case of joined https://...https://... without spaces, split at secondary 'https?://'
            String[] splits = u.split("(?=https?://)");
            for (String s : splits) {
                if (!s.isBlank()) {
                    foundUrls.add(s.trim());
                }
            }
        }

        if (foundUrls.isEmpty()) {
            if (input.startsWith("www.") || input.contains(".com") || input.contains(".in") || input.contains(".org")) {
                return "https://" + input;
            }
            throw new BadRequestException("Please enter a valid web URL starting with https:// or http://");
        }

        // 2. Prioritize specific event detail links over generic explore/city pages
        for (String u : foundUrls) {
            String lower = u.toLowerCase();
            if (lower.contains("/events/") || lower.contains("/event/") || lower.contains("/buy-tickets/")
                    || lower.contains("/et00") || lower.contains("/p/")) {
                return u;
            }
        }

        // Return the first valid URL
        return foundUrls.get(0);
    }

    /**
     * Validates that a given URL is safe to fetch externally.
     * Throws BadRequestException if the URL violates SSRF safety rules.
     */
    public URI validateAndSanitizeUrl(String rawUrl) {
        String cleanedUrl = extractAndCleanSingleUrl(rawUrl);

        if (cleanedUrl.length() > 2048) {
            throw new BadRequestException("URL is excessively long.");
        }

        URI uri;
        try {
            uri = URI.create(cleanedUrl);
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("Invalid URL format: " + e.getMessage());
        }

        // 1. Check scheme
        String scheme = uri.getScheme();
        if (scheme == null || !ALLOWED_SCHEMES.contains(scheme.toLowerCase())) {
            throw new BadRequestException("Only HTTP and HTTPS protocols are allowed.");
        }

        // 2. Reject credentials in URL (e.g. http://user:pass@example.com)
        if (uri.getUserInfo() != null) {
            throw new BadRequestException("URLs containing embedded user credentials are not allowed.");
        }

        // 3. Check Host
        String host = uri.getHost();
        if (host == null || host.isBlank()) {
            throw new BadRequestException("URL must contain a valid hostname.");
        }

        String hostLower = host.toLowerCase();
        for (String blocked : BLOCKED_HOSTNAMES) {
            if (hostLower.equals(blocked) || hostLower.endsWith("." + blocked)) {
                throw new BadRequestException("Requests to internal or metadata endpoints are strictly forbidden.");
            }
        }

        // 4. Check Port
        int port = uri.getPort();
        if (port != -1 && !ALLOWED_PORTS.contains(port)) {
            throw new BadRequestException("Port " + port + " is not permitted. Only standard HTTP(S) ports are allowed.");
        }

        // 5. DNS Resolution & IP Range Validation
        validateResolvedIps(host);

        return uri;
    }

    private void validateResolvedIps(String host) {
        try {
            InetAddress[] addresses = InetAddress.getAllByName(host);
            if (addresses == null || addresses.length == 0) {
                throw new BadRequestException("Could not resolve host: " + host);
            }

            for (InetAddress address : addresses) {
                if (isPrivateOrRestrictedIp(address)) {
                    log.warn("Blocked SSRF attempt targeting IP: {} for host: {}", address.getHostAddress(), host);
                    throw new BadRequestException("Target resolves to a private or restricted network address.");
                }
            }
        } catch (UnknownHostException e) {
            throw new BadRequestException("Host not found or unreachable: " + host);
        }
    }

    /**
     * Checks if the IP address belongs to any private, loopback, link-local, multicast, or cloud metadata ranges.
     */
    public boolean isPrivateOrRestrictedIp(InetAddress address) {
        if (address.isLoopbackAddress() || address.isAnyLocalAddress() || address.isLinkLocalAddress() || address.isSiteLocalAddress() || address.isMulticastAddress()) {
            return true;
        }

        byte[] bytes = address.getAddress();

        if (address instanceof Inet4Address) {
            int b0 = bytes[0] & 0xFF;
            int b1 = bytes[1] & 0xFF;
            int b2 = bytes[2] & 0xFF;

            // 0.0.0.0/8
            if (b0 == 0) return true;
            // 10.0.0.0/8 (Private)
            if (b0 == 10) return true;
            // 100.64.0.0/10 (Carrier Grade NAT)
            if (b0 == 100 && (b1 >= 64 && b1 <= 127)) return true;
            // 127.0.0.0/8 (Loopback)
            if (b0 == 127) return true;
            // 169.254.0.0/16 (Link Local / Cloud Metadata 169.254.169.254)
            if (b0 == 169 && b1 == 254) return true;
            // 172.16.0.0/12 (Private)
            if (b0 == 172 && (b1 >= 16 && b1 <= 31)) return true;
            // 192.0.0.0/24 (IETF Protocol Assignments)
            if (b0 == 192 && b1 == 0 && b2 == 0) return true;
            // 192.0.2.0/24 (TEST-NET-1)
            if (b0 == 192 && b1 == 0 && b2 == 2) return true;
            // 192.168.0.0/16 (Private)
            if (b0 == 192 && b1 == 168) return true;
            // 198.18.0.0/15 (Benchmarking)
            if (b0 == 198 && (b1 == 18 || b1 == 19)) return true;
            // 198.51.100.0/24 (TEST-NET-2)
            if (b0 == 198 && b1 == 51 && b2 == 100) return true;
            // 203.0.113.0/24 (TEST-NET-3)
            if (b0 == 203 && b1 == 0 && b2 == 113) return true;
            // 224.0.0.0/4 (Multicast) & 240.0.0.0/4 (Reserved) & 255.255.255.255 (Broadcast)
            if (b0 >= 224) return true;

        } else if (address instanceof Inet6Address) {
            // Check Unique Local Address (fc00::/7)
            int b0 = bytes[0] & 0xFF;
            if ((b0 & 0xFE) == 0xFC) return true;

            // Check Link-Local (fe80::/10)
            int b1 = bytes[1] & 0xFF;
            if (b0 == 0xFE && (b1 & 0xC0) == 0x80) return true;

            // IPv4-mapped IPv6 address (::ffff:127.0.0.1, etc.)
            if (bytes.length == 16) {
                boolean isMapped = true;
                for (int i = 0; i < 10; i++) {
                    if (bytes[i] != 0) { isMapped = false; break; }
                }
                if (isMapped && (bytes[10] & 0xFF) == 0xFF && (bytes[11] & 0xFF) == 0xFF) {
                    try {
                        byte[] ipv4Bytes = Arrays.copyOfRange(bytes, 12, 16);
                        InetAddress ipv4 = InetAddress.getByAddress(ipv4Bytes);
                        return isPrivateOrRestrictedIp(ipv4);
                    } catch (UnknownHostException ignored) {
                        return true;
                    }
                }
            }
        }

        return false;
    }
}
