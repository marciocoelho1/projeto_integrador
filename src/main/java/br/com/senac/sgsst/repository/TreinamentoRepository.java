package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.Treinamento;
import org.springframework.data.jpa.repository.JpaRepository;
public interface TreinamentoRepository extends JpaRepository<Treinamento, Integer> {
  boolean existsByCodigo(String codigo);
  boolean existsByCodigoAndIdNot(String codigo, Integer id);
}
