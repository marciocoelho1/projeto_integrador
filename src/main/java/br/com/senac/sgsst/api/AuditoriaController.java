package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.LogAuditoriaRequest;
import br.com.senac.sgsst.dto.LogAuditoriaResponse;
import br.com.senac.sgsst.service.AuditoriaService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/auditoria")
public class AuditoriaController {

  private final AuditoriaService service;

  public AuditoriaController(AuditoriaService service) {
    this.service = service;
  }

  @GetMapping
  public List<LogAuditoriaResponse> listar(
    @RequestParam(required = false) String termo,
    @RequestParam(required = false)
    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
    @RequestParam(required = false)
    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim
  ) {
    return service.listar(termo, inicio, fim);
  }

  @PostMapping
  public ResponseEntity<LogAuditoriaResponse> registrar(
    @Valid @RequestBody LogAuditoriaRequest request
  ) {
    LogAuditoriaResponse response = service.registrar(request);

    return ResponseEntity
      .created(URI.create("/api/auditoria/" + response.id()))
      .body(response);
  }
}
