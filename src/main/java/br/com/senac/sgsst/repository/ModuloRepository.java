package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.Modulo;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface ModuloRepository extends JpaRepository<Modulo, String> {
  List<Modulo> findAllByOrderByTituloAsc();
}
