package com.bankdemo.auth;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    public record LoginRequest(@NotBlank String username, @NotBlank String password) {}

    private final TokenService tokens;
    private final String demoPassword;

    public AuthController(TokenService tokens, @Value("${AUTH_DEMO_PASSWORD:demo123}") String demoPassword) {
        this.tokens = tokens; this.demoPassword = demoPassword;
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@Valid @RequestBody LoginRequest req) {
        // Demo users: asha, rohit, meera share one demo password (set AUTH_DEMO_PASSWORD from a Secret).
        boolean ok = java.util.Set.of("asha", "rohit", "meera").contains(req.username()) && demoPassword.equals(req.password());
        if (!ok) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Invalid credentials"));
        return ResponseEntity.ok(Map.of("token", tokens.issue(req.username()), "tokenType", "Bearer"));
    }

    @GetMapping("/verify")
    public ResponseEntity<Map<String, Object>> verify(@RequestHeader(value = "Authorization", defaultValue = "") String h) {
        String t = h.startsWith("Bearer ") ? h.substring(7) : "";
        return tokens.verify(t)
            .<ResponseEntity<Map<String, Object>>>map(s -> ResponseEntity.ok(Map.of("subject", s)))
            .orElseGet(() -> ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Invalid or expired token")));
    }
}
