package com.bankdemo.transfer.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

/** Same table as account-service (shared DB shortcut, documented as a known gap). */
@Entity
@Table(name = "accounts")
public class Account {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "account_number", nullable = false, unique = true, length = 20)
    private String accountNumber;

    @Column(name = "holder_name", nullable = false)
    private String holderName;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal balance = BigDecimal.ZERO;

    @Column(nullable = false, length = 3)
    private String currency = "INR";

    @Column(nullable = false, length = 10)
    private String status = "ACTIVE";

    @Version
    private Long version;

    @Column(name = "created_at", insertable = false, updatable = false)
    private OffsetDateTime createdAt;

    protected Account() {}

    public Account(String accountNumber, String holderName, BigDecimal balance) {
        this.accountNumber = accountNumber;
        this.holderName = holderName;
        this.balance = balance;
    }

    public void debit(BigDecimal amt) {
        if (balance.compareTo(amt) < 0) throw new IllegalStateException("Insufficient funds");
        balance = balance.subtract(amt);
    }
    public void credit(BigDecimal amt) { balance = balance.add(amt); }

    public Long getId() { return id; }
    public String getAccountNumber() { return accountNumber; }
    public String getHolderName() { return holderName; }
    public BigDecimal getBalance() { return balance; }
    public String getStatus() { return status; }
}
