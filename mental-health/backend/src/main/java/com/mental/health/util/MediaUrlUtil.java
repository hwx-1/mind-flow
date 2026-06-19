package com.mental.health.util;

public final class MediaUrlUtil {
    private MediaUrlUtil() {
    }

    public static String avatar(String value) {
        if (value == null) {
            return "";
        }
        String trimmed = value.trim();
        if (trimmed.isEmpty()) {
            return "";
        }
        String lower = trimmed.toLowerCase();
        if (lower.contains("/static/default-avatar.png")) {
            return "";
        }
        return trimmed;
    }
}
