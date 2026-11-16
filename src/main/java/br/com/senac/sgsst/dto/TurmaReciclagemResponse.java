package br.com.senac.sgsst.dto;
import br.com.senac.sgsst.entity.TurmaReciclagem;
import java.time.LocalDate;
public record TurmaReciclagemResponse(
  Integer id,
  Integer treinamentoId,
  String treinamento,
  String instrutor,
  LocalDate dataAgendada,
  Integer vagas,
  String status
) {
  public static TurmaReciclagemResponse from(TurmaReciclagem entity) {
    var treinamento = entity.getTreinamento();
    return new TurmaReciclagemResponse(
      entity.getId(),
      treinamento == null ? null : treinamento.getId(),
      treinamento == null ? null : treinamento.getNome(),
      entity.getInstrutor(),
      entity.getDataAgendada(),
      entity.getVagas(),
      entity.getStatus()
    );
  }
}
