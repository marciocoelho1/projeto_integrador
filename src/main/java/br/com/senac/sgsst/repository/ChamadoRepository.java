package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.Chamado;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface ChamadoRepository extends JpaRepository<Chamado, Integer> {
  List<Chamado> findByUsuarioId(Integer usuarioId);

  /** Chamados por status ('Em andamento', 'Concluída', 'Cancelada') — alertas do dashboard. */
  long countByStatus(String status);
}
