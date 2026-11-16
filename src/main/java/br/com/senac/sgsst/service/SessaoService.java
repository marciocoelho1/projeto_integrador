package br.com.senac.sgsst.service;

import br.com.senac.sgsst.entity.Sessao;
import br.com.senac.sgsst.entity.Usuario;
import br.com.senac.sgsst.repository.SessaoRepository;
import br.com.senac.sgsst.security.UsuarioSessao;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class SessaoService {

  static final Duration VALIDADE = Duration.ofHours(8);

  private final SessaoRepository repository;

  public SessaoService(SessaoRepository repository) {
    this.repository = repository;
  }

  @Transactional
  public Sessao abrir(Usuario usuario) {
    Instant agora = Instant.now();

    Sessao sessao = new Sessao();
    sessao.setToken(novoToken());
    sessao.setUsuario(usuario);
    sessao.setCriadaEm(agora);
    sessao.setExpiraEm(agora.plus(VALIDADE));

    return repository.saveAndFlush(sessao);
  }

  public Optional<UsuarioSessao> validar(String token) {
    if (token == null || token.isBlank()) {
      return Optional.empty();
    }

    return repository.findByToken(token)
      .filter(sessao -> sessao.getExpiraEm().isAfter(Instant.now()))
      .map(sessao -> paraSessao(sessao.getUsuario()));
  }

  @Transactional
  public void encerrar(String token) {
    if (token != null && !token.isBlank()) {
      repository.deleteByToken(token);
    }
  }

  public static UsuarioSessao paraSessao(Usuario usuario) {
    return new UsuarioSessao(
      usuario.getId(),
      usuario.getLogin(),
      usuario.getNomeCompleto(),
      usuario.getGrupo().getNomenclatura(),
      usuario.getGrupo().getModuloChaves()
    );
  }

  private String novoToken() {
    return UUID.randomUUID().toString().replace("-", "")
      + UUID.randomUUID().toString().replace("-", "");
  }
}
