package br.com.senac.sgsst.api;
import br.com.senac.sgsst.dto.ReciclagemResponse;
import br.com.senac.sgsst.exception.ApiExceptionHandler;
import br.com.senac.sgsst.service.ReciclagemService;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.time.LocalDate;
import java.util.List;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
class ReciclagemControllerTest {
  final ReciclagemService service = mock(ReciclagemService.class);
  final MockMvc mvc = MockMvcBuilders.standaloneSetup(new ReciclagemController(service))
    .setControllerAdvice(new ApiExceptionHandler()).build();

  @Test void listaReciclagensDerivadasDaValidade() throws Exception {
    when(service.listar()).thenReturn(List.of(new ReciclagemResponse(1, "Carlos Eduardo Silva", "Operador de Empilhadeira",
      2, "NR-11 Operação Segura de Empilhadeira", LocalDate.of(2026, 5, 31), -1, "Vencido")));
    mvc.perform(get("/api/reciclagens"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$[0].prazoMaximo").value("2026-05-31"))
      .andExpect(jsonPath("$[0].diasRestantes").value(-1))
      .andExpect(jsonPath("$[0].status").value("Vencido"))
      .andExpect(jsonPath("$[0].treinamento").value("NR-11 Operação Segura de Empilhadeira"));
  }

  @Test void listaVaziaQuandoNinguemEstaNaJanela() throws Exception {
    when(service.listar()).thenReturn(List.of());
    mvc.perform(get("/api/reciclagens")).andExpect(status().isOk()).andExpect(content().json("[]"));
  }
}
