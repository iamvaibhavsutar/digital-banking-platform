package com.bankdemo.notification;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class NotificationControllerTest {
    @Test
    void keepsOnlyLatest50() {
        var c = new NotificationController();
        for (int i = 0; i < 60; i++) c.send(new NotificationController.NotificationRequest("ACC1001", "m" + i));
        assertEquals(50, c.recent().size());
        assertEquals("m59", c.recent().get(0).message());
    }
}
