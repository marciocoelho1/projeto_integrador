package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.LoginResponse;
import br.com.senac.sgsst.dto.UsuarioResponse;
import br.com.senac.sgsst.dto.UsuarioSessaoResponse;
import br.com.senac.sgsst.exception.ApiExceptionHandler;
import br.com.senac.sgsst.exception.CredencialInvalidaException;
import br.com.senac.sgsst.security.ContextoUsuario;
import br.com.senac.sgsst.security.UsuarioSessao;
import br.com.senac.sgsst.service.AuthService;
import br.com.senac.sgsst.service.UsuarioService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.Instant;
import java.util.Set;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class AuthControllerTest {

  AuthService auth;
  UsuarioService usuarios;
  MockMvc mvc;

  @BeforeEach void setup() {
    auth = mock(AuthService.class);
    usuarios = mock(UsuarioService.class);
    mvc = MockMvcBuilders
      .standaloneSetup(new AuthController(auth, usuarios))
      .setControllerAdvice(new ApiExceptionHandler())
      .build();
  }

  @Test void loginDevolveTokenEUsuario() throws Exception {
    when(auth.entrar(any())).thenReturn(new LoginResponse(
      "token-123",
      Instant.parse("2026-11-16T20:00:00Z"),
      new UsuarioSessaoResponse(1, "ana", "Ana Souza", "Administrador TST", java.util.List.of("sgst_epis"))
    ));

    mvc.perform(post("/api/auth/login")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{\"login\": \"ana\", \"senha\": \"senha123\"}"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.token").value("token-123"))
      .andExpect(jsonPath("$.usuario.grupo").value("Administrador TST"))
      .andExpect(jsonPath("$.usuario.modulos[0]").value("sgst_epis"))
      .andExpect(jsonPath("$.usuario.senha").doesNotExist());
  }

  @Test void credencialInvalidaRetorna401() throws Exception {
    when(auth.entrar(any())).thenThrow(new CredencialInvalidaException("Usuário ou senha inválidos."));

    mvc.perform(post("/api/auth/login")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{\"login\": \"ana\", \"senha\": \"errada\"}"))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.mensagem").value("Usuário ou senha inválidos."));
  }

  @Test void loginSemCamposRetorna400() throws Exception {
    mvc.perform(post("/api/auth/login")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{}"))
      .andExpect(status().isBadRequest());
  }

  @Test void bootstrapCriaPrimeiroAdministrador() throws Exception {
    when(usuarios.criarPrimeiroAdministrador(any())).thenReturn(new UsuarioResponse(
      1, "Admin", "admin", "admin@example.test", "12345678901",
      1, "Administrador TST", "Ativo", java.util.List.of(), null
    ));

    mvc.perform(post("/api/auth/bootstrap")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{\"nomeCompleto\": \"Admin\", \"login\": \"admin\", \"email\": \"admin@example.test\", \"cpf\": \"12345678901\", \"grupoId\": 1, \"status\": \"Ativo\", \"senha\": \"senha123\"}"))
      .andExpect(status().isCreated())
      .andExpect(header().string("Location", "/api/usuarios/1"))
      .andExpect(jsonPath("$.login").value("admin"));
  }

  @Test void sessaoSemContextoRetorna401EComContextoRetornaDados() throws Exception {
    mvc.perform(get("/api/auth/sessao"))
      .andExpect(status().isUnauthorized());

    var sessao = new UsuarioSessao(1, "ana", "Ana Souza", "Administrador TST", Set.of("sgst_epis"));
    ContextoUsuario.definir(sessao);

    try {
      mvc.perform(get("/api/auth/sessao"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.login").value("ana"))
        .andExpect(jsonPath("$.grupo").value("Administrador TST"))
        .andExpect(jsonPath("$.modulos[0]").value("sgst_epis"));
    } finally {
      ContextoUsuario.limpar();
    }
  }

  @Test void logoutResponde204EEncerraATokenRecebida() throws Exception {
    mvc.perform(post("/api/auth/logout").header("Authorization", "Bearer token-123"))
      .andExpect(status().isNoContent());

    verify(auth).sair("Bearer token-123");
  }

  @Test void recuperarSenhaRespondeMensagemGenerica() throws Exception {
    when(auth.solicitarRedefinicao(any()))
      .thenReturn(new br.com.senac.sgsst.dto.MensagemResponse("Solicitação registrada."));

    mvc.perform(post("/api/auth/recuperar-senha")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{\"login\": \"ana\"}"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.mensagem").value("Solicitação registrada."));
  }

  @Test void redefinirSenhaComCodigoInvalidoRetorna400() throws Exception {
    doThrow(new br.com.senac.sgsst.exception.RequisicaoInvalidaException("Código de redefinição inválido."))
      .when(auth).redefinirSenha(any());

    mvc.perform(post("/api/auth/redefinir-senha")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{\"token\": \"x\", \"senha\": \"novaSenha1\"}"))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.mensagem").value("Código de redefinição inválido."));
  }
}
