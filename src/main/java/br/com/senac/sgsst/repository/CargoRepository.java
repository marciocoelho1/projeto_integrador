package br.com.senac.sgsst.repository;

import br.com.senac.sgsst.entity.Cargo;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CargoRepository extends JpaRepository<Cargo, Integer> {
  boolean existsByNome(String nome);
  boolean existsByNomeAndIdNot(String nome, Integer id);
}
