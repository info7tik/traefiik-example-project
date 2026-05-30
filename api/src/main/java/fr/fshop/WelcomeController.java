package fr.fshop;

import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class WelcomeController {

    @GetMapping("/welcome")
    public Map<String, String> status() {
        return Map.of("message", "Welcome Home");
    }
}
