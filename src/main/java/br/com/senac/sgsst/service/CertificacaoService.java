package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.CertificacaoRequest;
import br.com.senac.sgsst.dto.CertificacaoResponse;
import br.com.senac.sgsst.entity.Certificacao;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.CertificacaoRepository;
import br.com.senac.sgsst.repository.ColaboradorRepository;
import br.com.senac.sgsst.repository.TreinamentoRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class CertificacaoService {
  private final CertificacaoRepository repository;
  private final ColaboradorRepository colaboradorRepository;
  private final TreinamentoRepository treinamentoRepository;

  public CertificacaoService(
    CertificacaoRepository repository,
    ColaboradorRepository colaboradorRepository,
    TreinamentoRepository treinamentoRepository
  ) {
    this.repository = repository;
    this.colaboradorRepository = colaboradorRepository;
    this.treinamentoRepository = treinamentoRepository;
  }

  public List<CertificacaoResponse> listar(Integer colaboradorId) {
    var certificacoes = colaboradorId == null
      ? repository.findAll(Sort.by("id"))
      : repository.findByColaboradorIdOrderByIdAsc(colaboradorId);
    return certificacoes.stream().map(CertificacaoResponse::from).toList();
  }

  public CertificacaoResponse buscarPorId(Integer id) {
    return CertificacaoResponse.from(encontrar(id));
  }

  @Transactional
  public CertificacaoResponse criar(CertificacaoRequest request) {
    if (repository.existsByColaboradorIdAndTreinamentoIdAndValidade(
      request.colaboradorId(), request.treinamentoId(), request.validade()
    )) {
      throw new ConflitoException("Já existe certificação deste treinamento para o colaborador com esta validade.");
    }
    return salvar(new Certificacao(), request);
  }

  @Transactional
  public CertificacaoResponse atualizar(Integer id, CertificacaoRequest request) {
    var entity = encontrar(id);
    if (repository.existsByColaboradorIdAndTreinamentoIdAndValidadeAndIdNot(
      request.colaboradorId(), request.treinamentoId(), request.validade(), id
    )) {
      throw new ConflitoException("Já existe outra certificação deste treinamento para o colaborador com esta validade.");
    }
    return salvar(entity, request);
  }

  @Transactional
  public void excluir(Integer id) {
    repository.delete(encontrar(id));
    repository.flush();
  }

  private CertificacaoResponse salvar(Certificacao entity, CertificacaoRequest request) {
    entity.setColaborador(colaboradorRepository.findById(request.colaboradorId())
      .orElseThrow(() -> new RequisicaoInvalidaException("Colaborador informado não existe.")));
    entity.setTreinamento(treinamentoRepository.findById(request.treinamentoId())
      .orElseThrow(() -> new RequisicaoInvalidaException("Treinamento informado não existe.")));
    entity.setInstituicao(request.instituicao());
    entity.setCargaHoraria(request.cargaHoraria());
    entity.setEmitidaEm(request.emitidaEm());
    entity.setValidade(request.validade());
    entity.setArquivoUrl(request.arquivoUrl());
    return CertificacaoResponse.from(repository.saveAndFlush(entity));
  }

  private Certificacao encontrar(Integer id) {
    return repository.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Certificação não encontrada."));
  }
}
