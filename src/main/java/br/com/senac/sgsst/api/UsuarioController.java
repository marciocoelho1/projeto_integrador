package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.SenhaRequest;
import br.com.senac.sgsst.dto.UsuarioRequest;
import br.com.senac.sgsst.dto.UsuarioResponse;
import br.com.senac.sgsst.service.UsuarioService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

  private final UsuarioService service;

  public UsuarioController(UsuarioService service) {
    this.service = service;
  }

  @GetMapping
  public List<UsuarioResponse> listar() {
    return service.listar();
  }

  @GetMapping("/{id}")
  public UsuarioResponse buscarPorId(@PathVariable("id") Integer id) {
    return service.buscarPorId(id);
  }

  @PostMapping
  public ResponseEntity<UsuarioResponse> criar(
    @Valid @RequestBody UsuarioRequest request
  ) {
    UsuarioResponse response = service.criar(request);

    return ResponseEntity
      .created(URI.create("/api/usuarios/" + response.id()))
      .body(response);
  }

  @PutMapping("/{id}")
  public UsuarioResponse atualizar(
    @PathVariable("id") Integer id,
    @Valid @RequestBody UsuarioRequest request
  ) {
    return service.atualizar(id, request);
  }

  @PutMapping("/{id}/senha")
  public ResponseEntity<Void> alterarSenha(
    @PathVariable("id") Integer id,
    @Valid @RequestBody SenhaRequest request
  ) {
    service.alterarSenha(id, request.senha());
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{id}")
  public ResponseEntity<Void> excluir(@PathVariable("id") Integer id) {
    service.excluir(id);
    return ResponseEntity.noContent().build();
  }
}
