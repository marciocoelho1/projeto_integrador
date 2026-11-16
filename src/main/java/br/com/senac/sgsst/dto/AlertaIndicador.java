package br.com.senac.sgsst.dto;

/**
 * Alerta exibido no card "Atenção Requerida" do dashboard.
 *
 * <p>Criticidade: {@code alta} (prazo já estourado), {@code media} (dentro da janela de alerta) ou
 * {@code baixa} (informativo).</p>
 */
public record AlertaIndicador(
  String tipo,
  String mensagem,
  String criticidade
) {
}
