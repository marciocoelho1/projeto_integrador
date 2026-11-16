package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.Parametro;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface ParametroRepository extends JpaRepository<Parametro, String> {
  List<Parametro> findAllByOrderByChaveAsc();
}
