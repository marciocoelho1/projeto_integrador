package br.com.senac.sgsst.repository;

import br.com.senac.sgsst.entity.Colaborador;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ColaboradorRepository extends JpaRepository<Colaborador, Integer> {

  boolean existsByMatricula(String matricula);

  boolean existsByMatriculaAndIdNot(
    String matricula,
    Integer id
  );

  boolean existsByCpf(String cpf);

  boolean existsByCpfAndIdNot(
    String cpf,
    Integer id
  );

  boolean existsByEmail(String email);

  boolean existsByEmailAndIdNot(
    String email,
    Integer id
  );

  /** Contagem por status ('Ativo', 'Inativo', 'Afastado') — usada nos indicadores do dashboard. */
  long countByStatus(String status);
}
