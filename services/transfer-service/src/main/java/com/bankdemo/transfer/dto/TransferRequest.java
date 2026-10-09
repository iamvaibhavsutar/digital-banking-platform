package com.bankdemo.transfer.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record TransferRequest(
    @NotBlank String fromAccount,
    @NotBlank String toAccount,
    @NotNull @DecimalMin("0.01") BigDecimal amount) {}
