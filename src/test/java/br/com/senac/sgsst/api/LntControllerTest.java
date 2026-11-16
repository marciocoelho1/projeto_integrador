package br.com.senac.sgsst.api;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.exception.ApiExceptionHandler;
import br.com.senac.sgsst.service.LntService;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.util.List;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
class LntControllerTest {
  final LntService service = mock(LntService.class);
  final MockMvc mvc = MockMvcBuilders.standaloneSetup(new LntController(service))
    .setControllerAdvice(new ApiExceptionHandler()).build();

  @Test void listaCargosComOsTreinamentosObrigatorios() throws Exception {
    when(service.listarCargos()).thenReturn(List.of(new LntResponse(1, "Operador de Empilhadeira",
      "Estoque / Logística", "Ativo", List.of(new CargoTreinamentoResponse(1, 2, "NR-11 Operação Segura de Empilhadeira", "NR-11", true)))));
    mvc.perform(get("/api/lnt"))
      .andExpect(status().isOk())
      .andExpect(content().json("[{\"id\":1,\"cargo\":\"Operador de Empilhadeira\",\"setor\":\"Estoque / Logística\",\"status\":\"Ativo\"}]"))
      .andExpect(jsonPath("$[0].treinamentos[0].treinamentoId").value(2))
      .andExpect(jsonPath("$[0].treinamentos[0].obrigatorio").value(true));
  }

  @Test void listaColaboradoresPendentesEConformes() throws Exception {
    when(service.listarColaboradores()).thenReturn(List.of(
      new LntColaboradorResponse(1, "Carlos Eduardo Silva", "Operador de Empilhadeira", "Estoque / Logística",
        List.of("NR-11 Operação Segura de Empilhadeira"), "Pendente"),
      new LntColaboradorResponse(2, "Maria Joana Oliveira", "Operadora de Caixa", "Frente de Loja", List.of(), "Conforme")
    ));
    mvc.perform(get("/api/lnt/colaboradores"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$[0].colaboradorId").value(1))
      .andExpect(jsonPath("$[0].status").value("Pendente"))
      .andExpect(jsonPath("$[0].treinamentosPendentes[0]").value("NR-11 Operação Segura de Empilhadeira"))
      .andExpect(jsonPath("$[1].status").value("Conforme"))
      .andExpect(jsonPath("$[1].treinamentosPendentes").isEmpty());
  }
}
