package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.TurmaReciclagemRequest;
import br.com.senac.sgsst.dto.TurmaReciclagemResponse;
import br.com.senac.sgsst.entity.TurmaReciclagem;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.TreinamentoRepository;
import br.com.senac.sgsst.repository.TurmaReciclagemRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class TurmaReciclagemService {
  private final TurmaReciclagemRepository repository;
  private final TreinamentoRepository treinamentoRepository;

  public TurmaReciclagemService(TurmaReciclagemRepository repository, TreinamentoRepository treinamentoRepository) {
    this.repository = repository;
    this.treinamentoRepository = treinamentoRepository;
  }

  public List<TurmaReciclagemResponse> listar(Integer treinamentoId) {
    var turmas = treinamentoId == null
      ? repository.findAll(Sort.by("id"))
      : repository.findByTreinamentoIdOrderByIdAsc(treinamentoId);
    return turmas.stream().map(TurmaReciclagemResponse::from).toList();
  }

  public TurmaReciclagemResponse buscarPorId(Integer id) {
    return TurmaReciclagemResponse.from(encontrar(id));
  }

  @Transactional
  public TurmaReciclagemResponse criar(TurmaReciclagemRequest request) {
    return salvar(new TurmaReciclagem(), request);
  }

  @Transactional
  public TurmaReciclagemResponse atualizar(Integer id, TurmaReciclagemRequest request) {
    return salvar(encontrar(id), request);
  }

  @Transactional
  public void excluir(Integer id) {
    repository.delete(encontrar(id));
    repository.flush();
  }

  private TurmaReciclagemResponse salvar(TurmaReciclagem entity, TurmaReciclagemRequest request) {
    entity.setTreinamento(treinamentoRepository.findById(request.treinamentoId())
      .orElseThrow(() -> new RequisicaoInvalidaException("Treinamento informado não existe.")));
    entity.setInstrutor(request.instrutor());
    entity.setDataAgendada(request.dataAgendada());
    entity.setVagas(request.vagas());
    entity.setStatus(request.status());
    return TurmaReciclagemResponse.from(repository.saveAndFlush(entity));
  }

  private TurmaReciclagem encontrar(Integer id) {
    return repository.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Turma de reciclagem não encontrada."));
  }
}
