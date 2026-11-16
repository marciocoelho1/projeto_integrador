package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.RegraAlertaResponse;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.repository.RegraAlertaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class RegraAlertaService {

  private final RegraAlertaRepository repository;

  public RegraAlertaService(RegraAlertaRepository repository) {
    this.repository = repository;
  }

  public List<RegraAlertaResponse> listar() {
    return repository.findAllByOrderByNomeRegraAsc()
      .stream()
      .map(RegraAlertaResponse::from)
      .toList();
  }

  public RegraAlertaResponse buscarPorCodigo(String codigo) {
    return RegraAlertaResponse.from(encontrar(codigo));
  }

  public boolean ativa(String codigo) {
    return repository.findById(codigo)
      .map(regra -> Boolean.TRUE.equals(regra.getAtiva()))
      .orElse(false);
  }

  @Transactional
  public RegraAlertaResponse definirAtiva(String codigo, Boolean ativa) {
    var regra = encontrar(codigo);
    regra.setAtiva(ativa);
    return RegraAlertaResponse.from(repository.saveAndFlush(regra));
  }

  private br.com.senac.sgsst.entity.RegraAlerta encontrar(String codigo) {
    return repository.findById(codigo)
      .orElseThrow(() -> new RecursoNaoEncontradoException(
        "Regra de alerta não encontrada."
      ));
  }
}
