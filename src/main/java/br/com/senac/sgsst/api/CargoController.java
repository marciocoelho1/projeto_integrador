package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.CargoRequest;
import br.com.senac.sgsst.dto.CargoResponse;
import br.com.senac.sgsst.dto.CargoTreinamentosRequest;
import br.com.senac.sgsst.dto.LntResponse;
import br.com.senac.sgsst.service.CargoService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/cargos")
public class CargoController {

  private final CargoService service;

  public CargoController(CargoService service) {
    this.service = service;
  }

  @GetMapping
  public List<CargoResponse> listar() {
    return service.listar();
  }

  @GetMapping("/{id}")
  public CargoResponse buscarPorId(
    @PathVariable("id") Integer id
  ) {
    return service.buscarPorId(id);
  }

  @PostMapping
  public ResponseEntity<CargoResponse> criar(
    @Valid @RequestBody CargoRequest request
  ) {
    CargoResponse response = service.criar(request);

    URI location = URI.create(
      "/api/cargos/" + response.id()
    );

    return ResponseEntity.created(location).body(response);
  }

  @PutMapping("/{id}")
  public CargoResponse atualizar(
    @PathVariable("id") Integer id,
    @Valid @RequestBody CargoRequest request
  ) {
    return service.atualizar(id, request);
  }

  /** Matriz LNT do cargo: substitui integralmente os treinamentos obrigatórios. */
  @PutMapping("/{id}/treinamentos")
  public LntResponse substituirMatriz(
    @PathVariable("id") Integer id,
    @Valid @RequestBody CargoTreinamentosRequest request
  ) {
    return service.substituirMatriz(id, request);
  }

  @DeleteMapping("/{id}")
  public ResponseEntity<Void> excluir(
    @PathVariable("id") Integer id
  ) {
    service.excluir(id);
    return ResponseEntity.noContent().build();
  }
}
