package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.EpiRequest;
import br.com.senac.sgsst.dto.EpiResponse;
import br.com.senac.sgsst.entity.Epi;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.repository.EpiRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class EpiService {
  private final EpiRepository repository;
  public EpiService(EpiRepository repository) { this.repository = repository; }

  public List<EpiResponse> listar() {
    return repository.findAll(Sort.by("descricao", "id")).stream().map(EpiResponse::from).toList();
  }

  public EpiResponse buscarPorId(Integer id) { return EpiResponse.from(encontrar(id)); }

  @Transactional
  public EpiResponse criar(EpiRequest request) {
    var entity = new Epi();
    preencher(entity, request);
    return EpiResponse.from(repository.saveAndFlush(entity));
  }

  @Transactional
  public EpiResponse atualizar(Integer id, EpiRequest request) {
    var entity = encontrar(id);
    preencher(entity, request);
    return EpiResponse.from(repository.saveAndFlush(entity));
  }

  @Transactional
  public void excluir(Integer id) {
    repository.delete(encontrar(id));
    repository.flush();
  }

  private Epi encontrar(Integer id) {
    return repository.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Epi não encontrado."));
  }

  private void preencher(Epi entity, EpiRequest request) {
    entity.setDescricao(request.descricao());
    entity.setCa(request.ca());
    entity.setInclusao(request.inclusao());
    entity.setValidade(request.validade());
    entity.setQuantidade(request.quantidade());
  }
}
