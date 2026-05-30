package fr.fshop;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

public class WelcomeControllerTest {
    private final WelcomeController controller = new WelcomeController();

    @Test
    void welcomeEndpointReturnWelcomeMessage() {
        assertTrue(controller.welcome().containsKey("message"));
    }
}
