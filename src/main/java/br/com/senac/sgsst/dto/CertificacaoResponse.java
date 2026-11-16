package br.com.senac.sgsst.dto;
import br.com.senac.sgsst.entity.Certificacao;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
public record CertificacaoResponse(
  Integer id,
  Integer colaboradorId,
  String colaborador,
  String cargo,
  Integer treinamentoId,
  String treinamento,
  String instituicao,
  String cargaHoraria,
  LocalDate emitidaEm,
  LocalDate validade,
  String arquivoUrl,
  String status
) {
  public static final int JANELA_ALERTA_DIAS = 60;

  public static CertificacaoResponse from(Certificacao entity) {
    return from(entity, LocalDate.now());
  }

  public static CertificacaoResponse from(Certificacao entity, LocalDate referencia) {
    var colaborador = entity.getColaborador();
    var treinamento = entity.getTreinamento();
    return new CertificacaoResponse(
      entity.getId(),
      colaborador == null ? null : colaborador.getId(),
      colaborador == null ? null : colaborador.getNome(),
      colaborador == null ? null : colaborador.getCargo(),
      treinamento == null ? null : treinamento.getId(),
      treinamento == null ? null : treinamento.getNome(),
      entity.getInstituicao(),
      entity.getCargaHoraria(),
      entity.getEmitidaEm(),
      entity.getValidade(),
      entity.getArquivoUrl(),
      statusDe(entity.getValidade(), referencia)
    );
  }

  public static String statusDe(LocalDate validade, LocalDate referencia) {
    if (validade == null) return "Ativa";
    long dias = ChronoUnit.DAYS.between(referencia, validade);
    if (dias < 0) return "Vencida";
    return dias <= JANELA_ALERTA_DIAS ? "Alerta" : "Ativa";
  }
}
