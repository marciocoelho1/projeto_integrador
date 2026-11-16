package br.com.senac.sgsst.repository;
import br.com.senac.sgsst.entity.LogAuditoria;
import org.springframework.data.jpa.repository.JpaRepository;
public interface LogAuditoriaRepository extends JpaRepository<LogAuditoria, Integer> {
}
