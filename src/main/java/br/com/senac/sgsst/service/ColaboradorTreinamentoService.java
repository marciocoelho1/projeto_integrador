package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.ColaboradorTreinamentoRequest;
import br.com.senac.sgsst.dto.ColaboradorTreinamentoResponse;
import br.com.senac.sgsst.entity.Colaborador;
import br.com.senac.sgsst.entity.ColaboradorTreinamento;
import br.com.senac.sgsst.entity.Treinamento;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.ColaboradorRepository;
import br.com.senac.sgsst.repository.ColaboradorTreinamentoRepository;
import br.com.senac.sgsst.repository.TreinamentoRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class ColaboradorTreinamentoService {
  private final ColaboradorTreinamentoRepository repository;
  private final ColaboradorRepository colaboradorRepository;
  private final TreinamentoRepository treinamentoRepository;

  public ColaboradorTreinamentoService(
    ColaboradorTreinamentoRepository repository,
    ColaboradorRepository colaboradorRepository,
    TreinamentoRepository treinamentoRepository
  ) {
    this.repository = repository;
    this.colaboradorRepository = colaboradorRepository;
    this.treinamentoRepository = treinamentoRepository;
  }

  public List<ColaboradorTreinamentoResponse> listar(Integer colaboradorId) {
    var vinculos = colaboradorId == null
      ? repository.findAll(Sort.by("id"))
      : repository.findByColaboradorIdOrderByIdAsc(colaboradorId);
    return vinculos.stream().map(ColaboradorTreinamentoResponse::from).toList();
  }

  public ColaboradorTreinamentoResponse buscarPorId(Integer id) {
    return ColaboradorTreinamentoResponse.from(encontrar(id));
  }

  @Transactional
  public ColaboradorTreinamentoResponse criar(ColaboradorTreinamentoRequest request) {
    if (repository.existsByColaboradorIdAndTreinamentoId(request.colaboradorId(), request.treinamentoId())) {
      throw new ConflitoException("Este colaborador já possui vínculo com este treinamento.");
    }
    return salvar(new ColaboradorTreinamento(), request);
  }

  @Transactional
  public ColaboradorTreinamentoResponse atualizar(Integer id, ColaboradorTreinamentoRequest request) {
    var entity = encontrar(id);
    if (repository.existsByColaboradorIdAndTreinamentoIdAndIdNot(request.colaboradorId(), request.treinamentoId(), id)) {
      throw new ConflitoException("Este colaborador já possui vínculo com este treinamento.");
    }
    return salvar(entity, request);
  }

  @Transactional
  public void excluir(Integer id) {
    repository.delete(encontrar(id));
    repository.flush();
  }

  /** Validade do vínculo: data de conclusão + validade padrão (meses) do treinamento. */
  public static LocalDate calcularValidade(LocalDate dataConclusao, Integer validadeMeses) {
    return dataConclusao == null || validadeMeses == null
      ? null
      : dataConclusao.plusMonths(validadeMeses);
  }

  private ColaboradorTreinamentoResponse salvar(ColaboradorTreinamento entity, ColaboradorTreinamentoRequest request) {
    var colaborador = encontrarColaborador(request.colaboradorId());
    var treinamento = encontrarTreinamento(request.treinamentoId());
    entity.setColaborador(colaborador);
    entity.setTreinamento(treinamento);
    entity.setDataConclusao(request.dataConclusao());
    entity.setStatus(request.status());
    entity.setValidade(calcularValidade(request.dataConclusao(), treinamento.getValidadeMeses()));
    return ColaboradorTreinamentoResponse.from(repository.saveAndFlush(entity));
  }

  private ColaboradorTreinamento encontrar(Integer id) {
    return repository.findById(id)
      .orElseThrow(() -> new RecursoNaoEncontradoException("Vínculo colaborador/treinamento não encontrado."));
  }

  private Colaborador encontrarColaborador(Integer id) {
    return colaboradorRepository.findById(id)
      .orElseThrow(() -> new RequisicaoInvalidaException("Colaborador informado não existe."));
  }

  private Treinamento encontrarTreinamento(Integer id) {
    return treinamentoRepository.findById(id)
      .orElseThrow(() -> new RequisicaoInvalidaException("Treinamento informado não existe."));
  }
}
