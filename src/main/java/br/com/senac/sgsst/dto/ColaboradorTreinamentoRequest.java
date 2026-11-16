package br.com.senac.sgsst.dto;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
public record ColaboradorTreinamentoRequest(
  @NotNull Integer colaboradorId,
  @NotNull Integer treinamentoId,
  LocalDate dataConclusao,
  @NotBlank @Pattern(regexp = "Concluído|Em Andamento|Pendente") String status
) {
  public ColaboradorTreinamentoRequest {
    status = status == null ? null : status.trim();
  }
}
