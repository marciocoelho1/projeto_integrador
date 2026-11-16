package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.EpiEntrega;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.List;
public interface EpiEntregaRepository extends JpaRepository<EpiEntrega, Integer> {
  List<EpiEntrega> findByColaboradorId(Integer colaboradorId, Sort sort);

  /** Unidades entregues no período (inclusive nas duas pontas), para os indicadores do dashboard. */
  @Query("select coalesce(sum(e.quantidade), 0) from EpiEntrega e where e.dataEntrega between :inicio and :fim")
  long somarQuantidadesNoPeriodo(
    @Param("inicio") LocalDate inicio,
    @Param("fim") LocalDate fim
  );
}
