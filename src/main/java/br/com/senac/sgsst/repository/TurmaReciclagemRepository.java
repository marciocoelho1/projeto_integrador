package br.com.senac.sgsst.repository;

import br.com.senac.sgsst.entity.TurmaReciclagem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface TurmaReciclagemRepository extends JpaRepository<TurmaReciclagem, Integer> {
  List<TurmaReciclagem> findByTreinamentoIdOrderByIdAsc(Integer treinamentoId);
}
