package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.GrupoRequest;
import br.com.senac.sgsst.dto.GrupoResponse;
import br.com.senac.sgsst.dto.ModulosRequest;
import br.com.senac.sgsst.service.GrupoAcessoService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/grupos")
public class GrupoAcessoController {

  private final GrupoAcessoService service;

  public GrupoAcessoController(GrupoAcessoService service) {
    this.service = service;
  }

  @GetMapping
  public List<GrupoResponse> listar() {
    return service.listar();
  }

  @GetMapping("/{id}")
  public GrupoResponse buscarPorId(@PathVariable("id") Integer id) {
    return service.buscarPorId(id);
  }

  @PostMapping
  public ResponseEntity<GrupoResponse> criar(
    @Valid @RequestBody GrupoRequest request
  ) {
    GrupoResponse response = service.criar(request);

    return ResponseEntity
      .created(URI.create("/api/grupos/" + response.id()))
      .body(response);
  }

  @PutMapping("/{id}")
  public GrupoResponse atualizar(
    @PathVariable("id") Integer id,
    @Valid @RequestBody GrupoRequest request
  ) {
    return service.atualizar(id, request);
  }

  @PutMapping("/{id}/modulos")
  public GrupoResponse definirModulos(
    @PathVariable("id") Integer id,
    @RequestBody ModulosRequest request
  ) {
    return service.definirModulos(id, request.modulos());
  }

  @DeleteMapping("/{id}")
  public ResponseEntity<Void> excluir(@PathVariable("id") Integer id) {
    service.excluir(id);
    return ResponseEntity.noContent().build();
  }
}
