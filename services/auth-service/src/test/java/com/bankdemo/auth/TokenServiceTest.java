package com.bankdemo.auth;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class TokenServiceTest {
    @Test
    void issuedTokenVerifies() {
        var t = new TokenService("s3cret", 60);
        assertEquals("asha", t.verify(t.issue("asha")).orElseThrow());
    }

    @Test
    void tamperedTokenIsRejected() {
        var t = new TokenService("s3cret", 60);
        assertTrue(t.verify(t.issue("asha") + "x").isEmpty());
        assertTrue(new TokenService("other", 60).verify(t.issue("asha")).isEmpty());
    }

    @Test
    void expiredTokenIsRejected() {
        var t = new TokenService("s3cret", -1);
        assertTrue(t.verify(t.issue("asha")).isEmpty());
    }
}
