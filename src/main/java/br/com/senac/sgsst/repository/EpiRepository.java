package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.Epi;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
public interface EpiRepository extends JpaRepository<Epi, Integer> {
  boolean existsByCa(String ca);
  boolean existsByCaAndIdNot(String ca, Integer id);

  /** Soma das quantidades em estoque — o saldo já vem abatido pelas entregas de EPI. */
  @Query("select coalesce(sum(e.quantidade), 0) from Epi e")
  long somarQuantidades();

  /** Unidades em estoque cujo CA já venceu antes de {@code referencia}. */
  @Query("select coalesce(sum(e.quantidade), 0) from Epi e where e.validade < :referencia")
  long somarQuantidadesComValidadeAnterior(@Param("referencia") LocalDate referencia);

  /** Unidades em estoque cujo CA vence entre {@code inicio} e {@code fim}, inclusive. */
  @Query("select coalesce(sum(e.quantidade), 0) from Epi e where e.validade between :inicio and :fim")
  long somarQuantidadesComValidadeEntre(
    @Param("inicio") LocalDate inicio,
    @Param("fim") LocalDate fim
  );
}
