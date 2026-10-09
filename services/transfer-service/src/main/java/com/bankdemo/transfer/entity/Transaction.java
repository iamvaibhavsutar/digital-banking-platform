package com.bankdemo.transfer.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "transactions")
public class Transaction {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "idempotency_key", nullable = false, unique = true, length = 64)
    private String idempotencyKey;

    @Column(name = "from_account", nullable = false, length = 20)
    private String fromAccount;

    @Column(name = "to_account", nullable = false, length = 20)
    private String toAccount;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(nullable = false, length = 15)
    private String status;

    @Column(name = "created_at", insertable = false, updatable = false)
    private OffsetDateTime createdAt;

    protected Transaction() {}

    public Transaction(String idempotencyKey, String fromAccount, String toAccount,
                       BigDecimal amount, String status) {
        this.idempotencyKey = idempotencyKey;
        this.fromAccount = fromAccount;
        this.toAccount = toAccount;
        this.amount = amount;
        this.status = status;
    }

    public Long getId() { return id; }
    public String getIdempotencyKey() { return idempotencyKey; }
    public String getFromAccount() { return fromAccount; }
    public String getToAccount() { return toAccount; }
    public BigDecimal getAmount() { return amount; }
    public String getStatus() { return status; }
}
