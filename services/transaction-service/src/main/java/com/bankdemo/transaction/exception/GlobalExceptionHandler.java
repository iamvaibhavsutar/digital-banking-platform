package com.bankdemo.transaction.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> generic(Exception e) {
        log.error("Unhandled error", e);
        return ResponseEntity.status(500).body(Map.of("timestamp", Instant.now().toString(),
                "status", 500, "error", "Unexpected error"));
    }
}
