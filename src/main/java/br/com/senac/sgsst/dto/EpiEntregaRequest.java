package br.com.senac.sgsst.dto;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
public record EpiEntregaRequest(
  @NotNull @Positive Integer colaboradorId,
  @NotNull @Positive Integer epiId,
  @NotNull @Positive Integer quantidade,
  @NotNull LocalDate dataEntrega,
  @NotBlank @Size(max = 150) String assinatura
) {
  public EpiEntregaRequest {
    assinatura = assinatura == null ? null : assinatura.trim();
  }
}
