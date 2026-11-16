package br.com.senac.sgsst.dto;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
public record CertificacaoRequest(
  @NotNull Integer colaboradorId,
  @NotNull Integer treinamentoId,
  @NotBlank @Size(max = 150) String instituicao,
  @NotBlank @Size(max = 30) String cargaHoraria,
  @NotNull LocalDate emitidaEm,
  @NotNull LocalDate validade,
  @Size(max = 300) String arquivoUrl
) {
  public CertificacaoRequest {
    instituicao = instituicao == null ? null : instituicao.trim();
    cargaHoraria = cargaHoraria == null ? null : cargaHoraria.trim();
    arquivoUrl = arquivoUrl == null || arquivoUrl.isBlank() ? null : arquivoUrl.trim();
  }

  @AssertTrue(message = "A validade deve ser igual ou posterior à data de emissão.")
  public boolean isValidadePosteriorAEmissao() {
    return emitidaEm == null
      || validade == null
      || !validade.isBefore(emitidaEm);
  }
}
