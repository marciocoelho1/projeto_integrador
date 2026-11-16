package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.AlertaIndicador;
import br.com.senac.sgsst.dto.DashboardIndicadoresResponse;
import br.com.senac.sgsst.dto.ResumoCertificacoes;
import br.com.senac.sgsst.dto.ResumoColaboradores;
import br.com.senac.sgsst.dto.ResumoEpis;
import br.com.senac.sgsst.dto.ResumoTreinamentos;
import br.com.senac.sgsst.exception.ApiExceptionHandler;
import br.com.senac.sgsst.service.DashboardService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.OffsetDateTime;
import java.util.List;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class DashboardControllerTest {

  DashboardService service;
  MockMvc mvc;

  @BeforeEach void setup() {
    service = mock(DashboardService.class);
    mvc = MockMvcBuilders
      .standaloneSetup(new DashboardController(service))
      .setControllerAdvice(new ApiExceptionHandler())
      .build();
  }

  @Test void devolveOsIndicadoresDoDashboard() throws Exception {
    when(service.indicadores()).thenReturn(new DashboardIndicadoresResponse(
      new ResumoColaboradores(16, 12, 3, 1),
      new ResumoCertificacoes(7, 5, 2, 1),
      new ResumoEpis(140, 12, 6, 9, 4),
      new ResumoTreinamentos(7, 5, 2, 10, 50),
      List.of(new AlertaIndicador("EPI", "6 unidade(s) de EPI com CA vencido no estoque.", "alta")),
      OffsetDateTime.parse("2026-06-01T10:00:00-03:00")
    ));

    mvc.perform(get("/api/dashboard/indicadores"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.colaboradores.total").value(16))
      .andExpect(jsonPath("$.colaboradores.ativos").value(12))
      .andExpect(jsonPath("$.certificacoes.ativas").value(5))
      .andExpect(jsonPath("$.certificacoes.vencidas").value(2))
      .andExpect(jsonPath("$.epis.emEstoque").value(140))
      .andExpect(jsonPath("$.epis.entreguesUltimos30Dias").value(9))
      .andExpect(jsonPath("$.treinamentos.pendentes").value(5))
      .andExpect(jsonPath("$.treinamentos.porcentagem").value(50))
      .andExpect(jsonPath("$.alertas[0].criticidade").value("alta"))
      .andExpect(jsonPath("$.alertas[0].tipo").value("EPI"))
      .andExpect(jsonPath("$.geradoEm").exists());
  }

  @Test void rotaAceitaSomenteGet() throws Exception {
    mvc.perform(post("/api/dashboard/indicadores")).andExpect(status().isMethodNotAllowed());
    mvc.perform(delete("/api/dashboard/indicadores")).andExpect(status().isMethodNotAllowed());
  }
}
