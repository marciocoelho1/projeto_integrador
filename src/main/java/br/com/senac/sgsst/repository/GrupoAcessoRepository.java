package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.GrupoAcesso;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface GrupoAcessoRepository extends JpaRepository<GrupoAcesso, Integer> {
  Optional<GrupoAcesso> findByNomenclatura(String nomenclatura);
  boolean existsByNomenclatura(String nomenclatura);
  boolean existsByNomenclaturaAndIdNot(String nomenclatura, Integer id);
}
