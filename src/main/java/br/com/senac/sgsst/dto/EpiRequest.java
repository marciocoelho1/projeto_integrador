package br.com.senac.sgsst.dto;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
public record EpiRequest(
  @NotBlank @Size(max = 180) String descricao,
  @NotBlank @Size(max = 30) String ca,
  @NotNull LocalDate inclusao,
  @NotNull LocalDate validade,
  @NotNull @PositiveOrZero Integer quantidade
) {
  public EpiRequest {
    descricao = descricao == null ? null : descricao.trim();
    ca = ca == null ? null : ca.trim();
  }
}
