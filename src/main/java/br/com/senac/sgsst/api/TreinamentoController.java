package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.TreinamentoRequest;
import br.com.senac.sgsst.dto.TreinamentoResponse;
import br.com.senac.sgsst.service.TreinamentoService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/treinamentos")
public class TreinamentoController {

  private final TreinamentoService service;

  public TreinamentoController(TreinamentoService service) {
    this.service = service;
  }

  @GetMapping
  public List<TreinamentoResponse> listar() {
    return service.listar();
  }

  @GetMapping("/{id}")
  public TreinamentoResponse buscarPorId(
    @PathVariable("id") Integer id
  ) {
    return service.buscarPorId(id);
  }

  @PostMapping
  public ResponseEntity<TreinamentoResponse> criar(
    @Valid @RequestBody TreinamentoRequest request
  ) {
    TreinamentoResponse response = service.criar(request);

    URI location = URI.create(
      "/api/treinamentos/" + response.id()
    );

    return ResponseEntity.created(location).body(response);
  }

  @PutMapping("/{id}")
  public TreinamentoResponse atualizar(
    @PathVariable("id") Integer id,
    @Valid @RequestBody TreinamentoRequest request
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
