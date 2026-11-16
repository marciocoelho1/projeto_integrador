package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.LntColaboradorResponse;
import br.com.senac.sgsst.dto.LntResponse;
import br.com.senac.sgsst.entity.CargoTreinamento;
import br.com.senac.sgsst.repository.CargoTreinamentoRepository;
import br.com.senac.sgsst.repository.ColaboradorRepository;
import br.com.senac.sgsst.repository.ColaboradorTreinamentoRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

/**
 * LNT: matriz de treinamentos obrigatórios por cargo e situação de cada colaborador
 * (matriz do cargo x vínculos concluídos em colaborador_treinamentos).
 */
@Service
@Transactional(readOnly = true)
public class LntService {
  private final CargoService cargoService;
  private final CargoTreinamentoRepository matrizRepository;
  private final ColaboradorRepository colaboradorRepository;
  private final ColaboradorTreinamentoRepository vinculoRepository;

  public LntService(
    CargoService cargoService,
    CargoTreinamentoRepository matrizRepository,
    ColaboradorRepository colaboradorRepository,
    ColaboradorTreinamentoRepository vinculoRepository
  ) {
    this.cargoService = cargoService;
    this.matrizRepository = matrizRepository;
    this.colaboradorRepository = colaboradorRepository;
    this.vinculoRepository = vinculoRepository;
  }

  public List<LntResponse> listarCargos() { return cargoService.listarLnt(); }

  public List<LntColaboradorResponse> listarColaboradores() {
    var matrizPorCargo = new HashMap<String, List<CargoTreinamento>>();
    for (var item : matrizRepository.findByObrigatorioTrueOrderByIdAsc()) {
      if (item.getCargo() == null || item.getTreinamento() == null) continue;
      if (!Boolean.TRUE.equals(item.getObrigatorio())) continue;
      matrizPorCargo.computeIfAbsent(item.getCargo().getNome(), chave -> new ArrayList<>()).add(item);
    }
    var concluidos = new HashSet<String>();
    for (var vinculo : vinculoRepository.findAll()) {
      if ("Concluído".equals(vinculo.getStatus())
        && vinculo.getColaborador() != null
        && vinculo.getTreinamento() != null) {
        concluidos.add(vinculo.getColaborador().getId() + ":" + vinculo.getTreinamento().getId());
      }
    }
    return colaboradorRepository.findAll(Sort.by("nome", "id")).stream().map(colaborador -> {
      var obrigatorios = matrizPorCargo.getOrDefault(colaborador.getCargo(), List.of());
      var pendentes = obrigatorios.stream()
        .filter(item -> !concluidos.contains(colaborador.getId() + ":" + item.getTreinamento().getId()))
        .map(item -> item.getTreinamento().getNome())
        .toList();
      return new LntColaboradorResponse(
        colaborador.getId(),
        colaborador.getNome(),
        colaborador.getCargo(),
        colaborador.getSetor(),
        pendentes,
        pendentes.isEmpty() ? "Conforme" : "Pendente"
      );
    }).toList();
  }
}
