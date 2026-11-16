package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.ReciclagemResponse;
import br.com.senac.sgsst.service.ReciclagemService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Reciclagens derivadas da validade dos vínculos (vencidos ou vencendo em até 60 dias). */
@RestController
@RequestMapping("/api/reciclagens")
public class ReciclagemController {

  private final ReciclagemService service;

  public ReciclagemController(ReciclagemService service) {
    this.service = service;
  }

  @GetMapping
  public List<ReciclagemResponse> listar() {
    return service.listar();
  }
}
