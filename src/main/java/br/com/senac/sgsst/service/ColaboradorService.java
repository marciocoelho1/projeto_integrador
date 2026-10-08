package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.ColaboradorRequest;
import br.com.senac.sgsst.dto.ColaboradorResponse;
import br.com.senac.sgsst.entity.Colaborador;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.repository.ColaboradorRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class ColaboradorService {

  private final ColaboradorRepository repository;

  public ColaboradorService(ColaboradorRepository repository) {
    this.repository = repository;
  }

  public List<ColaboradorResponse> listar() {
    return repository.findAll(Sort.by("nome", "id"))
      .stream()
      .map(ColaboradorResponse::from)
      .toList();
  }

  public ColaboradorResponse buscarPorId(Integer id) {
    return ColaboradorResponse.from(encontrar(id));
  }

  @Transactional
  public ColaboradorResponse criar(ColaboradorRequest request) {
    if (repository.existsByMatricula(request.matricula())) {
      throw new ConflitoException(
        "Já existe um colaborador com esta matrícula."
      );
    }

    Colaborador colaborador = new Colaborador();
    preencher(colaborador, request);

    return ColaboradorResponse.from(
      repository.saveAndFlush(colaborador)
    );
  }

  @Transactional
  public ColaboradorResponse atualizar(
    Integer id,
    ColaboradorRequest request
  ) {
    Colaborador colaborador = encontrar(id);

    if (repository.existsByMatriculaAndIdNot(
      request.matricula(),
      id
    )) {
      throw new ConflitoException(
        "Já existe outro colaborador com esta matrícula."
      );
    }

    preencher(colaborador, request);

    return ColaboradorResponse.from(
      repository.saveAndFlush(colaborador)
    );
  }

  @Transactional
  public void excluir(Integer id) {
    Colaborador colaborador = encontrar(id);
    repository.delete(colaborador);
    repository.flush();
  }

  private Colaborador encontrar(Integer id) {
    return repository.findById(id)
      .orElseThrow(() -> new RecursoNaoEncontradoException(
        "Colaborador não encontrado."
      ));
  }

  private void preencher(
    Colaborador colaborador,
    ColaboradorRequest request
  ) {
    colaborador.setMatricula(request.matricula());
    colaborador.setNome(request.nome());
    colaborador.setCpf(request.cpf());
    colaborador.setEmail(request.email());
    colaborador.setCargo(request.cargo());
    colaborador.setSetor(request.setor());
    colaborador.setStatus(request.status());
  }
}
