package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.entity.Cargo;
import br.com.senac.sgsst.entity.CargoTreinamento;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.CargoRepository;
import br.com.senac.sgsst.repository.CargoTreinamentoRepository;
import br.com.senac.sgsst.repository.TreinamentoRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service
@Transactional(readOnly = true)
public class CargoService {
  private final CargoRepository repository;
  private final CargoTreinamentoRepository matrizRepository;
  private final TreinamentoRepository treinamentoRepository;

  public CargoService(
    CargoRepository repository,
    CargoTreinamentoRepository matrizRepository,
    TreinamentoRepository treinamentoRepository
  ) {
    this.repository = repository;
    this.matrizRepository = matrizRepository;
    this.treinamentoRepository = treinamentoRepository;
  }

  public List<CargoResponse> listar() {
    return repository.findAll(Sort.by("nome", "id")).stream().map(CargoResponse::from).toList();
  }

  public CargoResponse buscarPorId(Integer id) { return CargoResponse.from(encontrar(id)); }

  @Transactional
  public CargoResponse criar(CargoRequest request) {
    if (repository.existsByNome(request.nome())) {
      throw new ConflitoException("Já existe um cargo com este nome.");
    }
    return salvar(new Cargo(), request);
  }

  @Transactional
  public CargoResponse atualizar(Integer id, CargoRequest request) {
    var entity = encontrar(id);
    if (repository.existsByNomeAndIdNot(request.nome(), id)) {
      throw new ConflitoException("Já existe outro cargo com este nome.");
    }
    return salvar(entity, request);
  }

  @Transactional
  public void excluir(Integer id) {
    var entity = encontrar(id);
    matrizRepository.deleteByCargoId(id);
    matrizRepository.flush();
    repository.delete(entity);
    repository.flush();
  }

  /** LNT: todos os cargos com a matriz de treinamentos obrigatórios/vinculados. */
  public List<LntResponse> listarLnt() {
    return repository.findAll(Sort.by("nome", "id")).stream().map(this::matrizDe).toList();
  }

  public LntResponse matrizPorCargo(Integer cargoId) { return matrizDe(encontrar(cargoId)); }

  /** Substitui integralmente a matriz de treinamentos do cargo. */
  @Transactional
  public LntResponse substituirMatriz(Integer cargoId, CargoTreinamentosRequest request) {
    var cargo = encontrar(cargoId);
    var itens = request.treinamentos();
    var ids = new LinkedHashSet<Integer>();
    for (var item : itens) {
      if (!ids.add(item.treinamentoId())) {
        throw new RequisicaoInvalidaException("O treinamento " + item.treinamentoId() + " foi informado mais de uma vez.");
      }
    }
    var novidades = new ArrayList<CargoTreinamento>();
    for (var item : itens) {
      var treinamento = treinamentoRepository.findById(item.treinamentoId())
        .orElseThrow(() -> new RequisicaoInvalidaException("Treinamento informado não existe: " + item.treinamentoId()));
      var vinculo = new CargoTreinamento();
      vinculo.setCargo(cargo);
      vinculo.setTreinamento(treinamento);
      vinculo.setObrigatorio(item.obrigatorioEfetivo());
      novidades.add(vinculo);
    }
    matrizRepository.deleteByCargoId(cargoId);
    matrizRepository.flush();
    var salvos = novidades.stream().map(matrizRepository::saveAndFlush).toList();
    return LntResponse.from(cargo, salvos.stream().map(CargoTreinamentoResponse::from).toList());
  }

  private LntResponse matrizDe(Cargo cargo) {
    var vinculos = matrizRepository.findByCargoIdOrderByIdAsc(cargo.getId()).stream()
      .map(CargoTreinamentoResponse::from)
      .toList();
    return LntResponse.from(cargo, vinculos);
  }

  private CargoResponse salvar(Cargo entity, CargoRequest request) {
    entity.setNome(request.nome());
    entity.setSetor(request.setor());
    entity.setStatus(request.status());
    return CargoResponse.from(repository.saveAndFlush(entity));
  }

  private Cargo encontrar(Integer id) {
    return repository.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Cargo não encontrado."));
  }
}
