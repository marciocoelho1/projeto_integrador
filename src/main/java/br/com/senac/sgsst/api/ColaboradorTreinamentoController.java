package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.ColaboradorTreinamentoRequest;
import br.com.senac.sgsst.dto.ColaboradorTreinamentoResponse;
import br.com.senac.sgsst.service.ColaboradorTreinamentoService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/vinculos")
public class ColaboradorTreinamentoController {

  private final ColaboradorTreinamentoService service;

  public ColaboradorTreinamentoController(ColaboradorTreinamentoService service) {
    this.service = service;
  }

  @GetMapping
  public List<ColaboradorTreinamentoResponse> listar(
    @RequestParam(name = "colaboradorId", required = false) Integer colaboradorId
  ) {
    return service.listar(colaboradorId);
  }

  @GetMapping("/{id}")
  public ColaboradorTreinamentoResponse buscarPorId(
    @PathVariable("id") Integer id
  ) {
    return service.buscarPorId(id);
  }

  @PostMapping
  public ResponseEntity<ColaboradorTreinamentoResponse> criar(
    @Valid @RequestBody ColaboradorTreinamentoRequest request
  ) {
    ColaboradorTreinamentoResponse response = service.criar(request);

    URI location = URI.create(
      "/api/vinculos/" + response.id()
    );

    return ResponseEntity.created(location).body(response);
  }

  @PutMapping("/{id}")
  public ColaboradorTreinamentoResponse atualizar(
    @PathVariable("id") Integer id,
    @Valid @RequestBody ColaboradorTreinamentoRequest request
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
