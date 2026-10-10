package com.bankdemo.transaction.dto;

import com.bankdemo.transaction.entity.Transaction;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

public record TransactionResponse(Long id, String fromAccount, String toAccount, BigDecimal amount,
                                  String status, OffsetDateTime createdAt, String direction) {
    public static TransactionResponse from(Transaction t, String viewer) {
        return new TransactionResponse(t.getId(), t.getFromAccount(), t.getToAccount(), t.getAmount(),
            t.getStatus(), t.getCreatedAt(), t.getFromAccount().equals(viewer) ? "DEBIT" : "CREDIT");
    }
}
