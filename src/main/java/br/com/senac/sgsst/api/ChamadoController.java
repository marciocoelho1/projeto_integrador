package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.ChamadoRequest;
import br.com.senac.sgsst.dto.ChamadoResponse;
import br.com.senac.sgsst.service.ChamadoService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/chamados")
public class ChamadoController {

  private final ChamadoService service;

  public ChamadoController(ChamadoService service) {
    this.service = service;
  }

  @GetMapping
  public List<ChamadoResponse> listar(
    @RequestParam(required = false) String status,
    @RequestParam(required = false, defaultValue = "false") boolean meus
  ) {
    return service.listar(status, meus);
  }

  @GetMapping("/{id}")
  public ChamadoResponse buscarPorId(@PathVariable("id") Integer id) {
    return service.buscarPorId(id);
  }

  @PostMapping
  public ResponseEntity<ChamadoResponse> criar(
    @Valid @RequestBody ChamadoRequest request
  ) {
    ChamadoResponse response = service.criar(request);

    return ResponseEntity
      .created(URI.create("/api/chamados/" + response.id()))
      .body(response);
  }

  /** Usado para mudar o status (o corpo traz o campo status). */
  @PutMapping("/{id}")
  public ChamadoResponse atualizar(
    @PathVariable("id") Integer id,
    @Valid @RequestBody ChamadoRequest request
  ) {
    return service.atualizarStatus(id, request.status());
  }

  @DeleteMapping("/{id}")
  public ResponseEntity<Void> excluir(@PathVariable("id") Integer id) {
    service.excluir(id);
    return ResponseEntity.noContent().build();
  }
}
