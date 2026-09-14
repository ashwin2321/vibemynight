package com.vibemynight.backend.dto.importing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ValidationMessageDto {
    private String level; // "INFO", "WARNING", "ERROR"
    private String sheet;
    private Integer row;
    private String field;
    private String message;

    public static ValidationMessageDto error(String sheet, Integer row, String field, String message) {
        return new ValidationMessageDto("ERROR", sheet, row, field, message);
    }

    public static ValidationMessageDto warning(String sheet, Integer row, String field, String message) {
        return new ValidationMessageDto("WARNING", sheet, row, field, message);
    }

    public static ValidationMessageDto info(String sheet, Integer row, String field, String message) {
        return new ValidationMessageDto("INFO", sheet, row, field, message);
    }
}
