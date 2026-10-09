package com.bankdemo.account.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record CreateAccountRequest(
    @NotBlank @Size(max = 100) String holderName,
    @NotNull @DecimalMin("0.00") BigDecimal openingBalance) {}
