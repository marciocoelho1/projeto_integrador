package br.com.senac.sgsst.dto;
import java.time.LocalDate;
public record ReciclagemResponse(
  Integer colaboradorId,
  String colaborador,
  String cargo,
  Integer treinamentoId,
  String treinamento,
  LocalDate prazoMaximo,
  long diasRestantes,
  String status
) {
}
