package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.ColaboradorRequest;
import br.com.senac.sgsst.dto.EpiRequest;
import br.com.senac.sgsst.dto.ImportacaoErroResponse;
import br.com.senac.sgsst.dto.ImportacaoResultadoResponse;
import br.com.senac.sgsst.dto.TreinamentoRequest;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.function.Consumer;

/**
 * Importação em massa de planilhas já desserializadas.
 *
 * <p>Cada linha é processada de forma independente: as linhas válidas são
 * gravadas pelos serviços de domínio e as inválidas viram um
 * {@link ImportacaoErroResponse} com o número da linha. Uma linha com erro
 * nunca impede a gravação das demais.</p>
 *
 * <p>Nenhuma regra de negócio é duplicada aqui: a validação de campos usa o
 * bean validation sobre o próprio {@code *Request} e a checagem de
 * unicidade/duplicidade continua nos serviços de domínio
 * ({@link ColaboradorService}, {@link TreinamentoService} e
 * {@link EpiService}), cujos {@link ConflitoException} e
 * {@link RequisicaoInvalidaException} são convertidos em erro da linha.</p>
 */
@Service
public class ImportacaoService {

  /**
   * A planilha tem o cabeçalho na linha 1, então a primeira linha de dados
   * (índice 0 da lista) é reportada como linha 2.
   */
  static final int PRIMEIRA_LINHA_DE_DADOS = 2;

  private final ColaboradorService colaboradorService;
  private final TreinamentoService treinamentoService;
  private final EpiService epiService;
  private final Validator validator;

  public ImportacaoService(
    ColaboradorService colaboradorService,
    TreinamentoService treinamentoService,
    EpiService epiService,
    Validator validator
  ) {
    this.colaboradorService = colaboradorService;
    this.treinamentoService = treinamentoService;
    this.epiService = epiService;
    this.validator = validator;
  }

  public ImportacaoResultadoResponse importarColaboradores(
    List<ColaboradorRequest> linhas
  ) {
    return importar(linhas, colaboradorService::criar);
  }

  public ImportacaoResultadoResponse importarTreinamentos(
    List<TreinamentoRequest> linhas
  ) {
    return importar(linhas, treinamentoService::criar);
  }

  public ImportacaoResultadoResponse importarEpis(List<EpiRequest> linhas) {
    return importar(linhas, epiService::criar);
  }

  private <T> ImportacaoResultadoResponse importar(
    List<T> linhas,
    Consumer<T> gravador
  ) {
    if (linhas == null || linhas.isEmpty()) {
      return new ImportacaoResultadoResponse(0, 0, 0, List.of());
    }

    List<ImportacaoErroResponse> erros = new ArrayList<>();
    int importados = 0;

    for (int indice = 0; indice < linhas.size(); indice++) {
      int numeroLinha = indice + PRIMEIRA_LINHA_DE_DADOS;
      T linha = linhas.get(indice);

      List<String> problemas = problemasDa(linha);

      if (!problemas.isEmpty()) {
        erros.add(
          new ImportacaoErroResponse(numeroLinha, String.join(" ", problemas))
        );
        continue;
      }

      try {
        gravador.accept(linha);
        importados++;
      } catch (ConflitoException | RequisicaoInvalidaException excecao) {
        erros.add(new ImportacaoErroResponse(numeroLinha, mensagem(excecao)));
      }
    }

    return new ImportacaoResultadoResponse(
      linhas.size(),
      importados,
      linhas.size() - importados,
      List.copyOf(erros)
    );
  }

  private List<String> problemasDa(Object linha) {
    if (linha == null) {
      return List.of("Linha vazia.");
    }

    List<ConstraintViolation<Object>> violacoes =
      new ArrayList<>(validator.validate(linha));

    violacoes.sort(
      Comparator.comparing(violacao -> violacao.getPropertyPath().toString())
    );

    return violacoes.stream()
      .map(ConstraintViolation::getMessage)
      .toList();
  }

  private static String mensagem(RuntimeException excecao) {
    String mensagem = excecao.getMessage();
    return mensagem == null || mensagem.isBlank()
      ? "Não foi possível importar esta linha."
      : mensagem;
  }
}
