package br.com.senac.sgsst.repository;

import br.com.senac.sgsst.entity.Colaborador;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ColaboradorRepository extends JpaRepository<Colaborador, Integer> {

  boolean existsByMatricula(String matricula);

  boolean existsByMatriculaAndIdNot(
    String matricula,
    Integer id
  );
}
