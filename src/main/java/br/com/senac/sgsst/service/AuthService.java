package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.LoginRequest;
import br.com.senac.sgsst.dto.LoginResponse;
import br.com.senac.sgsst.dto.MensagemResponse;
import br.com.senac.sgsst.dto.RecuperarSenhaRequest;
import br.com.senac.sgsst.dto.RecuperarSenhaResponse;
import br.com.senac.sgsst.dto.RedefinirSenhaRequest;
import br.com.senac.sgsst.dto.UsuarioSessaoResponse;
import br.com.senac.sgsst.entity.RedefinicaoSenha;
import br.com.senac.sgsst.entity.Sessao;
import br.com.senac.sgsst.entity.Usuario;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.RedefinicaoSenhaRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class AuthService {

  static final Duration VALIDADE_REDEFINICAO = Duration.ofHours(2);

  private final UsuarioService usuarios;
  private final SessaoService sessoes;
  private final RedefinicaoSenhaRepository redefinicoes;

  public AuthService(
    UsuarioService usuarios,
    SessaoService sessoes,
    RedefinicaoSenhaRepository redefinicoes
  ) {
    this.usuarios = usuarios;
    this.sessoes = sessoes;
    this.redefinicoes = redefinicoes;
  }

  @Transactional
  public LoginResponse entrar(LoginRequest request) {
    Usuario usuario = usuarios.autenticar(request.login(), request.senha());
    Sessao sessao = sessoes.abrir(usuario);

    return new LoginResponse(
      sessao.getToken(),
      sessao.getExpiraEm(),
      UsuarioSessaoResponse.from(SessaoService.paraSessao(usuario))
    );
  }

  @Transactional
  public void sair(String cabecalhoAutorizacao) {
    sessoes.encerrar(tokenDe(cabecalhoAutorizacao));
  }

  /**
   * Resposta sempre igual, exista ou não o usuário, para não revelar quem está cadastrado.
   * O código gerado aparece em GET /api/auth/redefinicoes, para o administrador repassar.
   */
  @Transactional
  public MensagemResponse solicitarRedefinicao(RecuperarSenhaRequest request) {
    try {
      Usuario usuario = usuarios.buscarPorLoginOuEmail(request.login());

      RedefinicaoSenha redefinicao = new RedefinicaoSenha();
      redefinicao.setUsuario(usuario);
      redefinicao.setToken(novoToken());
      redefinicao.setCriadaEm(Instant.now());
      redefinicao.setExpiraEm(Instant.now().plus(VALIDADE_REDEFINICAO));

      redefinicoes.saveAndFlush(redefinicao);
    } catch (RuntimeException naoEncontrado) {
      // resposta genérica de propósito
    }

    return new MensagemResponse(
      "Solicitação registrada. Procure o administrador para receber o código de "
        + "redefinição."
    );
  }

  public List<RecuperarSenhaResponse> listarRedefinicoesPendentes() {
    return redefinicoes.findAll(Sort.by("criadaEm").descending())
      .stream()
      .filter(redefinicao -> redefinicao.getUsadaEm() == null
        && redefinicao.getExpiraEm().isAfter(Instant.now()))
      .map(redefinicao -> new RecuperarSenhaResponse(
        redefinicao.getId(),
        redefinicao.getUsuario().getId(),
        redefinicao.getUsuario().getLogin(),
        redefinicao.getUsuario().getNomeCompleto(),
        redefinicao.getUsuario().getEmail(),
        redefinicao.getToken(),
        redefinicao.getCriadaEm(),
        redefinicao.getExpiraEm()
      ))
      .toList();
  }

  @Transactional
  public void redefinirSenha(RedefinirSenhaRequest request) {
    RedefinicaoSenha redefinicao = redefinicoes
      .findByToken(request.token())
      .orElseThrow(() -> new RequisicaoInvalidaException(
        "Código de redefinição inválido."
      ));

    if (redefinicao.getUsadaEm() != null) {
      throw new RequisicaoInvalidaException(
        "Este código já foi utilizado."
      );
    }

    if (redefinicao.getExpiraEm().isBefore(Instant.now())) {
      throw new RequisicaoInvalidaException("Código de redefinição expirado.");
    }

    usuarios.gravarNovaSenha(
      redefinicao.getUsuario(),
      request.senha()
    );

    redefinicao.setUsadaEm(Instant.now());
    redefinicoes.saveAndFlush(redefinicao);
  }

  public static String tokenDe(String cabecalhoAutorizacao) {
    if (cabecalhoAutorizacao == null
      || !cabecalhoAutorizacao.startsWith("Bearer ")) {
      return null;
    }
    return cabecalhoAutorizacao.substring("Bearer ".length()).trim();
  }

  private String novoToken() {
    return UUID.randomUUID().toString().replace("-", "")
      + UUID.randomUUID().toString().replace("-", "");
  }
}
