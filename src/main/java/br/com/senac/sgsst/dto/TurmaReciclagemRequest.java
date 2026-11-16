package br.com.senac.sgsst.dto;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
public record TurmaReciclagemRequest(
  @NotNull Integer treinamentoId,
  @NotBlank @Size(max = 150) String instrutor,
  @NotNull LocalDate dataAgendada,
  @NotNull @PositiveOrZero Integer vagas,
  @NotBlank @Pattern(regexp = "Agendada|Concluída|Cancelada") String status
) {
  public TurmaReciclagemRequest {
    instrutor = instrutor == null ? null : instrutor.trim();
    status = status == null ? null : status.trim();
  }
}
