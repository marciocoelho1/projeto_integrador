package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.EpiEntregaRequest;
import br.com.senac.sgsst.dto.EpiEntregaResponse;
import br.com.senac.sgsst.entity.Colaborador;
import br.com.senac.sgsst.entity.Epi;
import br.com.senac.sgsst.entity.EpiEntrega;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.repository.ColaboradorRepository;
import br.com.senac.sgsst.repository.EpiEntregaRepository;
import br.com.senac.sgsst.repository.EpiRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class EpiEntregaService {
  /** Mais recentes primeiro: a data da entrega e, no empate, o id (ordem de cadastro). */
  static final Sort RECENTES_PRIMEIRO = Sort.by(Sort.Order.desc("dataEntrega"), Sort.Order.desc("id"));

  private final EpiEntregaRepository repository;
  private final EpiRepository epiRepository;
  private final ColaboradorRepository colaboradorRepository;

  public EpiEntregaService(EpiEntregaRepository repository, EpiRepository epiRepository, ColaboradorRepository colaboradorRepository) {
    this.repository = repository;
    this.epiRepository = epiRepository;
    this.colaboradorRepository = colaboradorRepository;
  }

  /** Sem filtro devolve todas as entregas; com colaboradorId, apenas as daquele colaborador. */
  public List<EpiEntregaResponse> listar(Integer colaboradorId) {
    var entregas = colaboradorId == null
      ? repository.findAll(RECENTES_PRIMEIRO)
      : repository.findByColaboradorId(colaboradorId, RECENTES_PRIMEIRO);
    return entregas.stream().map(EpiEntregaResponse::from).toList();
  }

  public EpiEntregaResponse buscarPorId(Integer id) { return EpiEntregaResponse.from(encontrar(id)); }

  /** Registra a entrega abatendo o estoque do EPI na mesma transação; 409 se faltar estoque. */
  @Transactional
  public EpiEntregaResponse registrar(EpiEntregaRequest request) {
    var colaborador = encontrarColaborador(request.colaboradorId());
    var epi = encontrarEpi(request.epiId());
    debitar(epi, request.quantidade());
    var entrega = new EpiEntrega();
    entrega.setColaborador(colaborador);
    entrega.setEpi(epi);
    entrega.setQuantidade(request.quantidade());
    entrega.setDataEntrega(request.dataEntrega());
    entrega.setAssinatura(request.assinatura());
    entrega.setCaNoAto(epi.getCa());
    entrega.setValidadeCaNoAto(epi.getValidade());
    entrega.setRegistradoEm(Instant.now());
    return EpiEntregaResponse.from(repository.saveAndFlush(entrega));
  }

  /**
   * Mantém o estoque coerente na edição: estorna a quantidade antiga ao EPI original e abate a
   * nova no EPI escolhido (409 se faltar estoque). O CA no ato é regravado com o EPI atual.
   */
  @Transactional
  public EpiEntregaResponse atualizar(Integer id, EpiEntregaRequest request) {
    var entrega = encontrar(id);
    var colaborador = encontrarColaborador(request.colaboradorId());
    var epi = encontrarEpi(request.epiId());
    entrega.getEpi().setQuantidade(entrega.getEpi().getQuantidade() + entrega.getQuantidade());
    debitar(epi, request.quantidade());
    entrega.setColaborador(colaborador);
    entrega.setEpi(epi);
    entrega.setQuantidade(request.quantidade());
    entrega.setDataEntrega(request.dataEntrega());
    entrega.setAssinatura(request.assinatura());
    entrega.setCaNoAto(epi.getCa());
    entrega.setValidadeCaNoAto(epi.getValidade());
    return EpiEntregaResponse.from(repository.saveAndFlush(entrega));
  }

  /**
   * Exclui a entrega e ESTORNA ao estoque do EPI a quantidade que havia sido entregue, para que o
   * saldo volte a refletir o que existe fisicamente. Corrigir um histórico que será mantido é
   * papel do atualizar(...), não desta exclusão.
   */
  @Transactional
  public void excluir(Integer id) {
    var entrega = encontrar(id);
    var epi = entrega.getEpi();
    epi.setQuantidade(epi.getQuantidade() + entrega.getQuantidade());
    epiRepository.saveAndFlush(epi);
    repository.delete(entrega);
    repository.flush();
  }

  private void debitar(Epi epi, Integer quantidade) {
    if (quantidade > epi.getQuantidade()) {
      throw new ConflitoException("Estoque insuficiente para esta entrega. Disponível: " + epi.getQuantidade() + ".");
    }
    epi.setQuantidade(epi.getQuantidade() - quantidade);
    epiRepository.saveAndFlush(epi);
  }

  private EpiEntrega encontrar(Integer id) {
    return repository.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Entrega de EPI não encontrada."));
  }

  private Epi encontrarEpi(Integer id) {
    return epiRepository.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Epi não encontrado."));
  }

  private Colaborador encontrarColaborador(Integer id) {
    return colaboradorRepository.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Colaborador não encontrado."));
  }
}
