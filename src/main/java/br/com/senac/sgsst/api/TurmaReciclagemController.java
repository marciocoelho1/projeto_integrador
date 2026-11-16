package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.TurmaReciclagemRequest;
import br.com.senac.sgsst.dto.TurmaReciclagemResponse;
import br.com.senac.sgsst.service.TurmaReciclagemService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/turmas-reciclagem")
public class TurmaReciclagemController {

  private final TurmaReciclagemService service;

  public TurmaReciclagemController(TurmaReciclagemService service) {
    this.service = service;
  }

  @GetMapping
  public List<TurmaReciclagemResponse> listar(
    @RequestParam(name = "treinamentoId", required = false) Integer treinamentoId
  ) {
    return service.listar(treinamentoId);
  }

  @GetMapping("/{id}")
  public TurmaReciclagemResponse buscarPorId(
    @PathVariable("id") Integer id
  ) {
    return service.buscarPorId(id);
  }

  @PostMapping
  public ResponseEntity<TurmaReciclagemResponse> criar(
    @Valid @RequestBody TurmaReciclagemRequest request
  ) {
    TurmaReciclagemResponse response = service.criar(request);

    URI location = URI.create(
      "/api/turmas-reciclagem/" + response.id()
    );

    return ResponseEntity.created(location).body(response);
  }

  @PutMapping("/{id}")
  public TurmaReciclagemResponse atualizar(
    @PathVariable("id") Integer id,
    @Valid @RequestBody TurmaReciclagemRequest request
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
