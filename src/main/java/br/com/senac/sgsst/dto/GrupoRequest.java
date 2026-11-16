package br.com.senac.sgsst.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

public record GrupoRequest(
  @NotBlank(message = "Informe a nomenclatura do grupo.")
  @Size(max = 120, message = "Nomenclatura: máximo de 120 caracteres.")
  String nomenclatura,

  @NotBlank(message = "Informe a finalidade do grupo.")
  @Size(max = 255, message = "Finalidade: máximo de 255 caracteres.")
  String finalidade,

  List<String> modulos
) {
  public GrupoRequest {
    nomenclatura = nomenclatura == null ? null : nomenclatura.trim();
    finalidade = finalidade == null ? null : finalidade.trim();
    modulos = modulos == null ? List.of() : List.copyOf(modulos);
  }
}
