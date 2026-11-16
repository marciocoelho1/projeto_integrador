package br.com.senac.sgsst.dto;
import jakarta.validation.constraints.*;
public record CargoRequest(
  @NotBlank @Size(max = 120) String nome,
  @NotBlank @Size(max = 120) String setor,
  @NotBlank @Pattern(regexp = "Ativo|Inativo") String status
) {
  public CargoRequest {
    nome = nome == null ? null : nome.trim();
    setor = setor == null ? null : setor.trim();
    status = status == null ? null : status.trim();
  }
}
