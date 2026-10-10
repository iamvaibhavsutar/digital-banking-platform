package com.bankdemo.auth;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;

/** Lab-grade signed token: base64url(sub|expEpoch).base64url(HMAC-SHA256). Production: use OIDC/JWT. */
@Service
public class TokenService {
    private final byte[] secret;
    private final long ttlSeconds;

    public TokenService(@Value("${AUTH_SECRET:change-me-in-a-secret}") String secret,
                        @Value("${AUTH_TTL_SECONDS:3600}") long ttlSeconds) {
        this.secret = secret.getBytes(StandardCharsets.UTF_8);
        this.ttlSeconds = ttlSeconds;
    }

    public String issue(String subject) {
        String payload = subject + "|" + (Instant.now().getEpochSecond() + ttlSeconds);
        String p = b64(payload.getBytes(StandardCharsets.UTF_8));
        return p + "." + b64(hmac(p));
    }

    public Optional<String> verify(String token) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 2) return Optional.empty();
            if (!MessageDigest.isEqual(hmac(parts[0]), Base64.getUrlDecoder().decode(parts[1]))) return Optional.empty();
            String[] payload = new String(Base64.getUrlDecoder().decode(parts[0]), StandardCharsets.UTF_8).split("\\|");
            if (Long.parseLong(payload[1]) < Instant.now().getEpochSecond()) return Optional.empty();
            return Optional.of(payload[0]);
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    private byte[] hmac(String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret, "HmacSHA256"));
            return mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) { throw new IllegalStateException(e); }
    }
    private static String b64(byte[] b) { return Base64.getUrlEncoder().withoutPadding().encodeToString(b); }
}
