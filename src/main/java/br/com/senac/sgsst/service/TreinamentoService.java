package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.TreinamentoRequest;
import br.com.senac.sgsst.dto.TreinamentoResponse;
import br.com.senac.sgsst.entity.Treinamento;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.repository.TreinamentoRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class TreinamentoService {
  private final TreinamentoRepository repository;
  public TreinamentoService(TreinamentoRepository repository) { this.repository = repository; }

  public List<TreinamentoResponse> listar() {
    return repository.findAll(Sort.by("nome", "id")).stream().map(TreinamentoResponse::from).toList();
  }

  public TreinamentoResponse buscarPorId(Integer id) { return TreinamentoResponse.from(encontrar(id)); }

  @Transactional
  public TreinamentoResponse criar(TreinamentoRequest request) {
    if (repository.existsByCodigo(request.codigo())) {
      throw new ConflitoException("Já existe um registro com este código.");
    }
    var entity = new Treinamento();
    preencher(entity, request);
    return TreinamentoResponse.from(repository.saveAndFlush(entity));
  }

  @Transactional
  public TreinamentoResponse atualizar(Integer id, TreinamentoRequest request) {
    var entity = encontrar(id);
    if (repository.existsByCodigoAndIdNot(request.codigo(), id)) {
      throw new ConflitoException("Já existe outro registro com este código.");
    }
    preencher(entity, request);
    return TreinamentoResponse.from(repository.saveAndFlush(entity));
  }

  @Transactional
  public void excluir(Integer id) {
    repository.delete(encontrar(id));
    repository.flush();
  }

  private Treinamento encontrar(Integer id) {
    return repository.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Treinamento não encontrado."));
  }

  private void preencher(Treinamento entity, TreinamentoRequest request) {
    entity.setCodigo(request.codigo());
    entity.setNome(request.nome());
    entity.setClassificacao(request.classificacao());
    entity.setNr(request.nr());
    entity.setCargaHoraria(request.cargaHoraria());
    entity.setValidadeMeses(request.validadeMeses());
    entity.setStatus(request.status());
  }
}
