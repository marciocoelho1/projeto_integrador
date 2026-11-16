package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.RegraAlertaRequest;
import br.com.senac.sgsst.dto.RegraAlertaResponse;
import br.com.senac.sgsst.service.RegraAlertaService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/regras-alerta")
public class RegraAlertaController {

  private final RegraAlertaService service;

  public RegraAlertaController(RegraAlertaService service) {
    this.service = service;
  }

  @GetMapping
  public List<RegraAlertaResponse> listar() {
    return service.listar();
  }

  @GetMapping("/{codigo}")
  public RegraAlertaResponse buscarPorCodigo(
    @PathVariable("codigo") String codigo
  ) {
    return service.buscarPorCodigo(codigo);
  }

  @PutMapping("/{codigo}")
  public RegraAlertaResponse definirAtiva(
    @PathVariable("codigo") String codigo,
    @Valid @RequestBody RegraAlertaRequest request
  ) {
    return service.definirAtiva(codigo, request.ativa());
  }
}
