package com.bankdemo.account.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(AccountNotFoundException.class)
    public ResponseEntity<Map<String, Object>> notFound(AccountNotFoundException e) {
        return body(HttpStatus.NOT_FOUND, e.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> invalid(MethodArgumentNotValidException e) {
        return body(HttpStatus.BAD_REQUEST, "Validation failed: "
                + e.getBindingResult().getFieldErrors().stream()
                   .map(f -> f.getField() + " " + f.getDefaultMessage()).toList());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> generic(Exception e) {
        // Never leak stack traces to a bank customer. Log it, return a generic message.
        log.error("Unhandled error", e);
        return body(HttpStatus.INTERNAL_SERVER_ERROR, "Unexpected error");
    }

    private ResponseEntity<Map<String, Object>> body(HttpStatus s, Object msg) {
        return ResponseEntity.status(s)
            .body(Map.of("timestamp", Instant.now().toString(),
                         "status", s.value(), "error", msg));
    }
}
