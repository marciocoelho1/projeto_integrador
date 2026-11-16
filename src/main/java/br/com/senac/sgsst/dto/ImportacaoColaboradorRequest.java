package br.com.senac.sgsst.dto;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

/**
 * Lote de colaboradores para importação em massa.
 *
 * <p>A lista não pode ser vazia, mas as linhas NÃO são validadas em cascata
 * de propósito: a validação de cada linha acontece no
 * {@code ImportacaoService}, linha a linha, para que uma linha inválida
 * vire um erro daquela linha em vez de derrubar o lote inteiro.</p>
 */
public record ImportacaoColaboradorRequest(
  @NotEmpty(message = "Informe ao menos uma linha para importar.")
  List<ColaboradorRequest> linhas
) {
}
