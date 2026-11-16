package br.com.senac.sgsst.repository;

import br.com.senac.sgsst.entity.CargoTreinamento;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CargoTreinamentoRepository extends JpaRepository<CargoTreinamento, Integer> {
  List<CargoTreinamento> findByCargoIdOrderByIdAsc(Integer cargoId);
  List<CargoTreinamento> findByObrigatorioTrueOrderByIdAsc();
  boolean existsByCargoIdAndTreinamentoId(Integer cargoId, Integer treinamentoId);
  void deleteByCargoId(Integer cargoId);
}
