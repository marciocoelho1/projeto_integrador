package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.LntColaboradorResponse;
import br.com.senac.sgsst.dto.LntResponse;
import br.com.senac.sgsst.service.LntService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** LNT: matriz de treinamentos obrigatórios por cargo e pendências por colaborador. */
@RestController
@RequestMapping("/api/lnt")
public class LntController {

  private final LntService service;

  public LntController(LntService service) {
    this.service = service;
  }

  @GetMapping
  public List<LntResponse> listarCargos() {
    return service.listarCargos();
  }

  @GetMapping("/colaboradores")
  public List<LntColaboradorResponse> listarColaboradores() {
    return service.listarColaboradores();
  }
}
