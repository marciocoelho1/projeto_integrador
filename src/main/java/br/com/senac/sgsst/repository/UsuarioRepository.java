package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface UsuarioRepository extends JpaRepository<Usuario, Integer> {
  Optional<Usuario> findByLogin(String login);
  Optional<Usuario> findByLoginOrEmail(String login, String email);
  boolean existsByLogin(String login);
  boolean existsByLoginAndIdNot(String login, Integer id);
  boolean existsByEmail(String email);
  boolean existsByEmailAndIdNot(String email, Integer id);
  boolean existsByCpf(String cpf);
  boolean existsByCpfAndIdNot(String cpf, Integer id);
  boolean existsByGrupoId(Integer grupoId);
}
