package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.ColaboradorRequest;
import br.com.senac.sgsst.dto.ColaboradorResponse;
import br.com.senac.sgsst.service.ColaboradorService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/colaboradores")
public class ColaboradorController {

  private final ColaboradorService service;

  public ColaboradorController(ColaboradorService service) {
    this.service = service;
  }

  @GetMapping
  public List<ColaboradorResponse> listar() {
    return service.listar();
  }

  @GetMapping("/{id}")
  public ColaboradorResponse buscarPorId(
    @PathVariable("id") Integer id
  ) {
    return service.buscarPorId(id);
  }

  @PostMapping
  public ResponseEntity<ColaboradorResponse> criar(
    @Valid @RequestBody ColaboradorRequest request
  ) {
    ColaboradorResponse response = service.criar(request);

    URI location = URI.create(
      "/api/colaboradores/" + response.id()
    );

    return ResponseEntity.created(location).body(response);
  }

  @PutMapping("/{id}")
  public ColaboradorResponse atualizar(
    @PathVariable("id") Integer id,
    @Valid @RequestBody ColaboradorRequest request
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
