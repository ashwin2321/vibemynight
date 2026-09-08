package com.vibemynight.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Consistent API envelope used by every controller:
 * { "success": true, "data": {...}, "message": "Success" }
 * { "success": false, "message": "...", "errors": [...] }
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ApiResponse<T> {

    private boolean success;
    private T data;
    private String message;
    private List<String> errors;

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, "Success", null);
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return new ApiResponse<>(true, data, message, null);
    }

    public static <T> ApiResponse<T> error(String message, List<String> errors) {
        return new ApiResponse<>(false, null, message, errors);
    }
}
