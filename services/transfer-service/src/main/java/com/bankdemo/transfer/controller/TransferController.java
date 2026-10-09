package com.bankdemo.transfer.controller;

import com.bankdemo.transfer.dto.*;
import com.bankdemo.transfer.service.TransferService;
import jakarta.validation.Valid;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/transfers")
public class TransferController {
    private final TransferService service;
    public TransferController(TransferService service) { this.service = service; }

    @PostMapping
    public TransferResponse transfer(@RequestHeader("Idempotency-Key") String key,
                                     @Valid @RequestBody TransferRequest req) {
        try {
            return service.transfer(key, req);
        } catch (DataIntegrityViolationException e) {
            // Two simultaneous requests with the same key: the loser's transaction rolled back,
            // so return the winner's stored result instead of an error.
            return service.findByKey(key);
        }
    }
}
