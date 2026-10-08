package br.com.senac.sgsst.api;

import br.com.senac.sgsst.service.DatabaseHealthService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/health")
public class HealthApiController {
  private final DatabaseHealthService healthService;

  public HealthApiController(DatabaseHealthService healthService) {
    this.healthService = healthService;
  }

  @GetMapping
  public ResponseEntity<Map<String, String>> health() {
    boolean available = healthService.isDatabaseAvailable();

    Map<String, String> response = Map.of(
      "status", available ? "UP" : "DOWN",
      "database", available ? "UP" : "DOWN"
    );

    HttpStatus status = available ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE;
    return ResponseEntity.status(status).body(response);
  }
}
