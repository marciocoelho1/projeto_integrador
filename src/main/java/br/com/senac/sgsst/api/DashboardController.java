package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.DashboardIndicadoresResponse;
import br.com.senac.sgsst.service.DashboardService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Indicadores do dashboard. Somente leitura: não há POST/PUT/DELETE aqui, então este controller
 * não passa pelo contrato de CRUD ({@code CrudControllerContractTest}).
 */
@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {
  private final DashboardService service;

  public DashboardController(DashboardService service) {
    this.service = service;
  }

  @GetMapping("/indicadores")
  public DashboardIndicadoresResponse indicadores() {
    return service.indicadores();
  }
}
