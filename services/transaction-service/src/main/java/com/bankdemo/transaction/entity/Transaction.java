package com.bankdemo.transaction.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "transactions")
public class Transaction {
    @Id private Long id;
    @Column(name = "idempotency_key") private String idempotencyKey;
    @Column(name = "from_account") private String fromAccount;
    @Column(name = "to_account") private String toAccount;
    private BigDecimal amount;
    private String status;
    @Column(name = "created_at") private OffsetDateTime createdAt;

    protected Transaction() {}
    public Transaction(Long id, String from, String to, BigDecimal amount, String status) {
        this.id = id; this.fromAccount = from; this.toAccount = to; this.amount = amount; this.status = status;
    }
    public Long getId() { return id; }
    public String getFromAccount() { return fromAccount; }
    public String getToAccount() { return toAccount; }
    public BigDecimal getAmount() { return amount; }
    public String getStatus() { return status; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
}
