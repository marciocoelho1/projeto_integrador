package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.RedefinicaoSenha;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface RedefinicaoSenhaRepository extends JpaRepository<RedefinicaoSenha, Integer> {
  Optional<RedefinicaoSenha> findByToken(String token);
}
