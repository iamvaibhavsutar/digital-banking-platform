package com.bankdemo.notification;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ConcurrentLinkedDeque;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {
    private static final Logger log = LoggerFactory.getLogger(NotificationController.class);
    public record NotificationRequest(@NotBlank String account, @NotBlank String message) {}
    public record Notification(String id, String account, String message, Instant at) {}

    private final ConcurrentLinkedDeque<Notification> recent = new ConcurrentLinkedDeque<>();

    @PostMapping
    @ResponseStatus(HttpStatus.ACCEPTED)
    public Notification send(@Valid @RequestBody NotificationRequest req) {
        var n = new Notification(UUID.randomUUID().toString(), req.account(), req.message(), Instant.now());
        // Lab stand-in for SMS/email: a structured log line (Fluent Bit ships it to Kibana).
        log.info("notification account={} id={}", n.account(), n.id());
        recent.addFirst(n);
        while (recent.size() > 50) recent.pollLast();
        return n;
    }

    @GetMapping("/recent")
    public List<Notification> recent() { return new ArrayList<>(recent); }
}
