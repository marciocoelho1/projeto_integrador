package br.com.senac.sgsst.dto;
import java.util.List;
public record LntColaboradorResponse(
  Integer colaboradorId,
  String colaborador,
  String cargo,
  String setor,
  List<String> treinamentosPendentes,
  String status
) {
}
