package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.UsuarioResponse;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.service.UsuarioService;
import static org.mockito.Mockito.*;

class UsuarioControllerTest extends CrudControllerContractTest {
  UsuarioService service;

  Object controller() {
    service = mock(UsuarioService.class);
    var response = new UsuarioResponse(
      1, "Ana Souza", "ana", "ana@example.test", "12345678901",
      1, "Administrador TST", "Ativo", java.util.List.of("sgst_epis"), null
    );
    when(service.listar()).thenReturn(java.util.List.of(response));
    when(service.buscarPorId(1)).thenReturn(response);
    when(service.criar(any())).thenReturn(response);
    when(service.atualizar(eq(1), any())).thenReturn(response);
    when(service.buscarPorId(404)).thenThrow(new br.com.senac.sgsst.exception.RecursoNaoEncontradoException("Não encontrado."));
    when(service.atualizar(eq(404), any())).thenThrow(new br.com.senac.sgsst.exception.RecursoNaoEncontradoException("Não encontrado."));
    doThrow(new br.com.senac.sgsst.exception.RecursoNaoEncontradoException("Não encontrado.")).when(service).excluir(404);
    return new UsuarioController(service);
  }

  String endpoint() { return "/api/usuarios"; }

  String payload() {
    return "{\"nomeCompleto\": \"Ana Souza\", \"login\": \"ana\", \"email\": \"ana@example.test\", \"cpf\": \"12345678901\", \"grupoId\": 1, \"status\": \"Ativo\"}";
  }

  void conflict() {
    when(service.criar(any())).thenThrow(new org.springframework.dao.DataIntegrityViolationException("test"));
  }

  @org.junit.jupiter.api.Test void cadastroSemSenhaRetorna400() throws Exception {
    when(service.criar(any())).thenThrow(new RequisicaoInvalidaException("Informe a senha de acesso do usuário."));

    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload()))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest())
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath("$.mensagem")
        .value("Informe a senha de acesso do usuário."));
  }

  @org.junit.jupiter.api.Test void grupoObrigatorioERetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"grupoId\": 1", "\"grupoId\": null")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }

  @org.junit.jupiter.api.Test void trocaDeSenhaResponde204() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/1/senha")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content("{\"senha\": \"novaSenha1\"}"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isNoContent());

    verify(service).alterarSenha(1, "novaSenha1");
  }

  @org.junit.jupiter.api.Test void senhaCurtaRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/1/senha")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content("{\"senha\": \"123\"}"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());

    verify(service, never()).alterarSenha(any(), any());
  }
}
