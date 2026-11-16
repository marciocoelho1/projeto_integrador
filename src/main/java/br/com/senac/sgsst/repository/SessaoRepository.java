package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.Sessao;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface SessaoRepository extends JpaRepository<Sessao, Integer> {
  Optional<Sessao> findByToken(String token);
  void deleteByToken(String token);
}
