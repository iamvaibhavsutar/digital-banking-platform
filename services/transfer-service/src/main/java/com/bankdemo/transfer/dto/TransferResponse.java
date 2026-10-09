package com.bankdemo.transfer.dto;

import com.bankdemo.transfer.entity.Transaction;
import java.math.BigDecimal;

public record TransferResponse(Long id, String idempotencyKey, String fromAccount,
                               String toAccount, BigDecimal amount, String status) {
    public static TransferResponse from(Transaction t) {
        return new TransferResponse(t.getId(), t.getIdempotencyKey(), t.getFromAccount(),
                                    t.getToAccount(), t.getAmount(), t.getStatus());
    }
}
