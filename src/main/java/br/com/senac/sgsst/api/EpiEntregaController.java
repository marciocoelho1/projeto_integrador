package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.EpiEntregaRequest;
import br.com.senac.sgsst.dto.EpiEntregaResponse;
import br.com.senac.sgsst.service.EpiEntregaService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/entregas-epis")
public class EpiEntregaController {

  private final EpiEntregaService service;

  public EpiEntregaController(EpiEntregaService service) {
    this.service = service;
  }

  @GetMapping
  public List<EpiEntregaResponse> listar(
    @RequestParam(name = "colaboradorId", required = false) Integer colaboradorId
  ) {
    return service.listar(colaboradorId);
  }

  @GetMapping("/{id}")
  public EpiEntregaResponse buscarPorId(
    @PathVariable("id") Integer id
  ) {
    return service.buscarPorId(id);
  }

  @PostMapping
  public ResponseEntity<EpiEntregaResponse> registrar(
    @Valid @RequestBody EpiEntregaRequest request
  ) {
    EpiEntregaResponse response = service.registrar(request);

    URI location = URI.create(
      "/api/entregas-epis/" + response.id()
    );

    return ResponseEntity.created(location).body(response);
  }

  @PutMapping("/{id}")
  public EpiEntregaResponse atualizar(
    @PathVariable("id") Integer id,
    @Valid @RequestBody EpiEntregaRequest request
  ) {
    return service.atualizar(id, request);
  }

  @DeleteMapping("/{id}")
  public ResponseEntity<Void> excluir(
    @PathVariable("id") Integer id
  ) {
    service.excluir(id);
    return ResponseEntity.noContent().build();
  }
}
