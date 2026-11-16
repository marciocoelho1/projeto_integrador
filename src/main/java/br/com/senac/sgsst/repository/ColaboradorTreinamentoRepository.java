package br.com.senac.sgsst.repository;

import br.com.senac.sgsst.entity.ColaboradorTreinamento;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;

public interface ColaboradorTreinamentoRepository extends JpaRepository<ColaboradorTreinamento, Integer> {
  List<ColaboradorTreinamento> findByColaboradorIdOrderByIdAsc(Integer colaboradorId);
  boolean existsByColaboradorIdAndTreinamentoId(Integer colaboradorId, Integer treinamentoId);
  boolean existsByColaboradorIdAndTreinamentoIdAndIdNot(Integer colaboradorId, Integer treinamentoId, Integer id);

  /** Vínculos por status ('Concluído', 'Em Andamento', 'Pendente') — progresso do dashboard. */
  long countByStatus(String status);

  /** Vínculos cuja validade já passou: reciclagem em atraso. */
  long countByValidadeLessThan(LocalDate validade);
}
