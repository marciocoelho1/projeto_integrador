package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.RegraAlerta;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface RegraAlertaRepository extends JpaRepository<RegraAlerta, String> {
  List<RegraAlerta> findAllByOrderByNomeRegraAsc();
}
