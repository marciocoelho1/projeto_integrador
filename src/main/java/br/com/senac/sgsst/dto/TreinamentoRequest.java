package br.com.senac.sgsst.dto;
import jakarta.validation.constraints.*;
public record TreinamentoRequest(
  @NotBlank @Size(max = 30) String codigo,
  @NotBlank @Size(max = 180) String nome,
  @NotBlank @Size(max = 60) String classificacao,
  @Size(max = 60) String nr,
  @NotBlank @Size(max = 30) String cargaHoraria,
  @PositiveOrZero Integer validadeMeses,
  @NotBlank @Pattern(regexp = "Ativo|Inativo") String status
) {
  public TreinamentoRequest {
    codigo = limpar(codigo); nome = limpar(nome);
    classificacao = limpar(classificacao); nr = limpar(nr);
    cargaHoraria = limpar(cargaHoraria); status = limpar(status);
  }
  private static String limpar(String value) { return value == null ? null : value.trim(); }
}
