package br.com.senac.sgsst.repository;

import br.com.senac.sgsst.entity.Certificacao;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;

public interface CertificacaoRepository extends JpaRepository<Certificacao, Integer> {
  List<Certificacao> findByColaboradorIdOrderByIdAsc(Integer colaboradorId);
  boolean existsByColaboradorIdAndTreinamentoIdAndValidade(Integer colaboradorId, Integer treinamentoId, LocalDate validade);
  boolean existsByColaboradorIdAndTreinamentoIdAndValidadeAndIdNot(Integer colaboradorId, Integer treinamentoId, LocalDate validade, Integer id);

  /** Certificações ainda válidas na data informada (validade igual ou posterior). */
  long countByValidadeGreaterThanEqual(LocalDate validade);

  /** Certificações já vencidas na data informada. */
  long countByValidadeLessThan(LocalDate validade);

  /** Certificações que vencem na janela entre as duas datas, inclusive. */
  long countByValidadeBetween(LocalDate inicio, LocalDate fim);
}
