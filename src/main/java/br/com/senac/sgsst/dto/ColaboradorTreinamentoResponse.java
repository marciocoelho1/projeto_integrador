package br.com.senac.sgsst.dto;
import br.com.senac.sgsst.entity.ColaboradorTreinamento;
import java.time.LocalDate;
public record ColaboradorTreinamentoResponse(
  Integer id,
  Integer colaboradorId,
  String colaborador,
  String cargo,
  Integer treinamentoId,
  String treinamento,
  LocalDate dataConclusao,
  String status,
  LocalDate validade
) {
  public static ColaboradorTreinamentoResponse from(ColaboradorTreinamento entity) {
    var colaborador = entity.getColaborador();
    var treinamento = entity.getTreinamento();
    return new ColaboradorTreinamentoResponse(
      entity.getId(),
      colaborador == null ? null : colaborador.getId(),
      colaborador == null ? null : colaborador.getNome(),
      colaborador == null ? null : colaborador.getCargo(),
      treinamento == null ? null : treinamento.getId(),
      treinamento == null ? null : treinamento.getNome(),
      entity.getDataConclusao(),
      entity.getStatus(),
      entity.getValidade()
    );
  }
}
