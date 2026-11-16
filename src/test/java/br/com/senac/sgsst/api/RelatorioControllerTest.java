package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.RelatorioCsv;
import br.com.senac.sgsst.exception.ApiExceptionHandler;
import br.com.senac.sgsst.service.RelatorioService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.nio.charset.StandardCharsets;

import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class RelatorioControllerTest {

  RelatorioService service;
  MockMvc mvc;

  @BeforeEach void setup() {
    service = mock(RelatorioService.class);
    mvc = MockMvcBuilders
      .standaloneSetup(new RelatorioController(service))
      .setControllerAdvice(new ApiExceptionHandler())
      .build();
  }

  @Test void dashboardBaixaComoAnexoCsvComBom() throws Exception {
    when(service.dashboard()).thenReturn(new RelatorioCsv(
      "dashboard-indicadores.csv",
      "\ufeffCategoria;Métrica;Valor\nColaboradores;Total;16\n"
    ));

    var resposta = mvc.perform(get("/api/relatorios/dashboard.csv"))
      .andExpect(status().isOk())
      .andExpect(header().string("Content-Type", containsString("text/csv")))
      .andExpect(header().string("Content-Disposition", containsString("dashboard-indicadores.csv")))
      .andReturn()
      .getResponse();

    var bytes = resposta.getContentAsByteArray();
    assertEquals(0xEF, bytes[0] & 0xFF);
    assertEquals(0xBB, bytes[1] & 0xFF);
    assertEquals(0xBF, bytes[2] & 0xFF);
    assertTrue(new String(bytes, StandardCharsets.UTF_8).contains("Categoria;Métrica;Valor"));
  }

  @Test void demaisRelatoriosRespondemComCsv() throws Exception {
    when(service.matrizTreinamentos()).thenReturn(new RelatorioCsv("matriz-treinamentos.csv", "\ufeffColaborador\n"));
    when(service.colaboradores()).thenReturn(new RelatorioCsv("colaboradores.csv", "\ufeffMatrícula\n"));
    when(service.epis()).thenReturn(new RelatorioCsv("epis-estoque.csv", "\ufeffDescrição\n"));
    when(service.certificacoes()).thenReturn(new RelatorioCsv("certificacoes.csv", "\ufeffColaborador\n"));
    when(service.entregasEpi()).thenReturn(new RelatorioCsv("entregas-epis.csv", "\ufeffColaborador\n"));

    mvc.perform(get("/api/relatorios/matriz-treinamentos.csv"))
      .andExpect(status().isOk())
      .andExpect(header().string("Content-Disposition", containsString("matriz-treinamentos.csv")));
    mvc.perform(get("/api/relatorios/colaboradores.csv"))
      .andExpect(status().isOk())
      .andExpect(header().string("Content-Disposition", containsString("colaboradores.csv")));
    mvc.perform(get("/api/relatorios/epis.csv"))
      .andExpect(status().isOk())
      .andExpect(header().string("Content-Disposition", containsString("epis-estoque.csv")));
    mvc.perform(get("/api/relatorios/certificacoes.csv")).andExpect(status().isOk());
    mvc.perform(get("/api/relatorios/entregas-epis.csv")).andExpect(status().isOk());
  }
}
