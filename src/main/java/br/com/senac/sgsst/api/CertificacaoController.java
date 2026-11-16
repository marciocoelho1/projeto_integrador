package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.CertificacaoRequest;
import br.com.senac.sgsst.dto.CertificacaoResponse;
import br.com.senac.sgsst.service.CertificacaoService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/certificacoes")
public class CertificacaoController {

  private final CertificacaoService service;

  public CertificacaoController(CertificacaoService service) {
    this.service = service;
  }

  @GetMapping
  public List<CertificacaoResponse> listar(
    @RequestParam(name = "colaboradorId", required = false) Integer colaboradorId
  ) {
    return service.listar(colaboradorId);
  }

  @GetMapping("/{id}")
  public CertificacaoResponse buscarPorId(
    @PathVariable("id") Integer id
  ) {
    return service.buscarPorId(id);
  }

  @PostMapping
  public ResponseEntity<CertificacaoResponse> criar(
    @Valid @RequestBody CertificacaoRequest request
  ) {
    CertificacaoResponse response = service.criar(request);

    URI location = URI.create(
      "/api/certificacoes/" + response.id()
    );

    return ResponseEntity.created(location).body(response);
  }

  @PutMapping("/{id}")
  public CertificacaoResponse atualizar(
    @PathVariable("id") Integer id,
    @Valid @RequestBody CertificacaoRequest request
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
