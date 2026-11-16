package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.LoginRequest;
import br.com.senac.sgsst.dto.LoginResponse;
import br.com.senac.sgsst.dto.MensagemResponse;
import br.com.senac.sgsst.dto.RecuperarSenhaRequest;
import br.com.senac.sgsst.dto.RecuperarSenhaResponse;
import br.com.senac.sgsst.dto.RedefinirSenhaRequest;
import br.com.senac.sgsst.dto.UsuarioRequest;
import br.com.senac.sgsst.dto.UsuarioResponse;
import br.com.senac.sgsst.dto.UsuarioSessaoResponse;
import br.com.senac.sgsst.exception.CredencialInvalidaException;
import br.com.senac.sgsst.security.ContextoUsuario;
import br.com.senac.sgsst.service.AuthService;
import br.com.senac.sgsst.service.UsuarioService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

  private final AuthService auth;
  private final UsuarioService usuarios;

  public AuthController(AuthService auth, UsuarioService usuarios) {
    this.auth = auth;
    this.usuarios = usuarios;
  }

  @PostMapping("/login")
  public LoginResponse entrar(
    @Valid @RequestBody LoginRequest request
  ) {
    return auth.entrar(request);
  }

  @PostMapping("/logout")
  public ResponseEntity<Void> sair(
    @RequestHeader(
      value = "Authorization",
      required = false
    ) String cabecalhoAutorizacao
  ) {
    auth.sair(cabecalhoAutorizacao);
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/sessao")
  public UsuarioSessaoResponse sessao() {
    return UsuarioSessaoResponse.from(
      ContextoUsuario.atual().orElseThrow(() -> new CredencialInvalidaException(
        "Sessão ausente ou expirada."
      ))
    );
  }

  /**
   * Cria o primeiro usuário (administrador) de um banco novo. Só funciona com a tabela
   * usuarios vazia; depois disso, 409.
   */
  @PostMapping("/bootstrap")
  public ResponseEntity<UsuarioResponse> bootstrap(
    @Valid @RequestBody UsuarioRequest request
  ) {
    UsuarioResponse response =
      usuarios.criarPrimeiroAdministrador(request);

    return ResponseEntity
      .created(URI.create("/api/usuarios/" + response.id()))
      .body(response);
  }

  @PostMapping("/recuperar-senha")
  public MensagemResponse recuperarSenha(
    @Valid @RequestBody RecuperarSenhaRequest request
  ) {
    return auth.solicitarRedefinicao(request);
  }

  @GetMapping("/redefinicoes")
  public List<RecuperarSenhaResponse> redefinicoesPendentes() {
    return auth.listarRedefinicoesPendentes();
  }

  @PostMapping("/redefinir-senha")
  public ResponseEntity<Void> redefinirSenha(
    @Valid @RequestBody RedefinirSenhaRequest request
  ) {
    auth.redefinirSenha(request);
    return ResponseEntity.noContent().build();
  }
}
