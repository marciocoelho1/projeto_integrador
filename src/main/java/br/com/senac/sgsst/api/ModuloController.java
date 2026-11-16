package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.ModuloResponse;
import br.com.senac.sgsst.service.ModuloService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/modulos")
public class ModuloController {

  private final ModuloService service;

  public ModuloController(ModuloService service) {
    this.service = service;
  }

  @GetMapping
  public List<ModuloResponse> listar() {
    return service.listar();
  }
}
