package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.ParametroRequest;
import br.com.senac.sgsst.dto.ParametroResponse;
import br.com.senac.sgsst.service.ParametroService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/parametros")
public class ParametroController {

  private final ParametroService service;

  public ParametroController(ParametroService service) {
    this.service = service;
  }

  @GetMapping
  public List<ParametroResponse> listar() {
    return service.listar();
  }

  @GetMapping("/{chave}")
  public ParametroResponse buscarPorChave(@PathVariable("chave") String chave) {
    return service.buscarPorChave(chave);
  }

  @PutMapping("/{chave}")
  public ParametroResponse atualizar(
    @PathVariable("chave") String chave,
    @Valid @RequestBody ParametroRequest request
  ) {
    return service.atualizar(chave, request.valor());
  }
}
