package br.com.senac.sgsst.dto;
import jakarta.validation.constraints.*;
/**
 * Entrada de chamado. tipo segue o CHECK de chamados.tipo ('Ajuda'|'Erro') e descricao é obrigatória.
 * status é opcional (o criar sempre grava 'Em andamento'; o PUT /api/chamados/{id} usa este campo
 * para mudar o status). solicitante também é opcional: quando ausente o serviço usa a sessão.
 */
public record ChamadoRequest(
  @NotBlank @Pattern(regexp = "Ajuda|Erro") String tipo,
  @NotBlank @Size(max = 500) String descricao,
  @Pattern(regexp = "Em andamento|Concluída|Cancelada") String status,
  @Size(max = 150) String solicitante
) {
  public ChamadoRequest {
    tipo = limpar(tipo);
    descricao = limpar(descricao);
    status = limpar(status);
    solicitante = limpar(solicitante);
  }
  private static String limpar(String value) { return value == null ? null : value.trim(); }
}
