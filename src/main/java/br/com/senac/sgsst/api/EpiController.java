package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.EpiRequest;
import br.com.senac.sgsst.dto.EpiResponse;
import br.com.senac.sgsst.service.EpiService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/epis")
public class EpiController {

  private final EpiService service;

  public EpiController(EpiService service) {
    this.service = service;
  }

  @GetMapping
  public List<EpiResponse> listar() {
    return service.listar();
  }

  @GetMapping("/{id}")
  public EpiResponse buscarPorId(
    @PathVariable("id") Integer id
  ) {
    return service.buscarPorId(id);
  }

  @PostMapping
  public ResponseEntity<EpiResponse> criar(
    @Valid @RequestBody EpiRequest request
  ) {
    EpiResponse response = service.criar(request);

    URI location = URI.create(
      "/api/epis/" + response.id()
    );

    return ResponseEntity.created(location).body(response);
  }

  @PutMapping("/{id}")
  public EpiResponse atualizar(
    @PathVariable("id") Integer id,
    @Valid @RequestBody EpiRequest request
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
