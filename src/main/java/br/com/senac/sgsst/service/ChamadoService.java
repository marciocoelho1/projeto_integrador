package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.ChamadoRequest;
import br.com.senac.sgsst.dto.ChamadoResponse;
import br.com.senac.sgsst.entity.Chamado;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.CredencialInvalidaException;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.ChamadoRepository;
import br.com.senac.sgsst.repository.UsuarioRepository;
import br.com.senac.sgsst.security.ContextoUsuario;
import br.com.senac.sgsst.security.UsuarioSessao;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * Chamados de suporte (item 9). O colaborador vê apenas os próprios (meus=true, filtrado pela
 * sessão); a administração vê todos e muda o status.
 */
@Service
@Transactional(readOnly = true)
public class ChamadoService {

  static final String EM_ANDAMENTO = "Em andamento";
  static final String CONCLUIDA = "Concluída";
  static final String CANCELADA = "Cancelada";
  static final Set<String> STATUS_VALIDOS = Set.of(EM_ANDAMENTO, CONCLUIDA, CANCELADA);

  private final ChamadoRepository repository;
  private final UsuarioRepository usuarios;

  public ChamadoService(ChamadoRepository repository, UsuarioRepository usuarios) {
    this.repository = repository;
    this.usuarios = usuarios;
  }

  public List<ChamadoResponse> listar(String status, boolean meus) {
    List<Chamado> base = meus
      ? repository.findByUsuarioId(usuarioDaSessao())
      : repository.findAll();

    return base.stream()
      .filter(chamado -> status == null || status.isBlank() || status.equals(chamado.getStatus()))
      .sorted(Comparator.comparing(Chamado::getAbertoEm).reversed())
      .map(ChamadoResponse::from)
      .toList();
  }

  public ChamadoResponse buscarPorId(Integer id) {
    return ChamadoResponse.from(encontrar(id));
  }

  @Transactional
  public ChamadoResponse criar(ChamadoRequest request) {
    var sessao = ContextoUsuario.atual();

    Chamado chamado = new Chamado();
    chamado.setTipo(request.tipo());
    chamado.setDescricao(request.descricao());
    chamado.setStatus(EM_ANDAMENTO);
    chamado.setAbertoEm(Instant.now());
    chamado.setConcluidoEm(null);
    chamado.setSolicitante(solicitante(request, sessao));
    chamado.setUsuario(
      sessao.map(usuario -> usuarios.getReferenceById(usuario.id())).orElse(null)
    );

    return ChamadoResponse.from(repository.saveAndFlush(chamado));
  }

  @Transactional
  public ChamadoResponse atualizarStatus(Integer id, String novoStatus) {
    if (novoStatus == null || !STATUS_VALIDOS.contains(novoStatus)) {
      throw new RequisicaoInvalidaException("Status de chamado inválido.");
    }

    Chamado chamado = encontrar(id);

    if (CANCELADA.equals(chamado.getStatus())) {
      throw new ConflitoException("Chamado cancelado não pode ser alterado.");
    }

    chamado.setStatus(novoStatus);
    chamado.setConcluidoEm(CONCLUIDA.equals(novoStatus) ? Instant.now() : null);

    return ChamadoResponse.from(repository.saveAndFlush(chamado));
  }

  @Transactional
  public void excluir(Integer id) {
    repository.delete(encontrar(id));
    repository.flush();
  }

  private String solicitante(ChamadoRequest request, Optional<UsuarioSessao> sessao) {
    if (request.solicitante() != null && !request.solicitante().isBlank()) {
      return request.solicitante();
    }
    return sessao
      .map(usuario -> usuario.nomeCompleto())
      .orElseThrow(() -> new CredencialInvalidaException("Sessão ausente ou expirada."));
  }

  private Integer usuarioDaSessao() {
    return ContextoUsuario.atual()
      .orElseThrow(() -> new CredencialInvalidaException("Sessão ausente ou expirada."))
      .id();
  }

  private Chamado encontrar(Integer id) {
    return repository.findById(id)
      .orElseThrow(() -> new RecursoNaoEncontradoException("Chamado não encontrado."));
  }
}
