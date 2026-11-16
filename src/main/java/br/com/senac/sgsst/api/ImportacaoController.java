package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.ImportacaoColaboradorRequest;
import br.com.senac.sgsst.dto.ImportacaoEpiRequest;
import br.com.senac.sgsst.dto.ImportacaoResultadoResponse;
import br.com.senac.sgsst.dto.ImportacaoTreinamentoRequest;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.service.ImportacaoService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Importação em massa de planilhas.
 *
 * <p>Recebe um lote ({@code {"linhas": [ ... ]}}) e devolve sempre {@code 200}
 * com o resumo, mesmo quando algumas linhas falham — o detalhamento vai em
 * {@code erros}, uma entrada por linha rejeitada.</p>
 */
@RestController
@RequestMapping("/api/importacao")
public class ImportacaoController {

  /** Limite defensivo de linhas por requisição. */
  public static final int LIMITE_DE_LINHAS = 500;

  private final ImportacaoService service;

  public ImportacaoController(ImportacaoService service) {
    this.service = service;
  }

  @PostMapping("/colaboradores")
  public ImportacaoResultadoResponse importarColaboradores(
    @Valid @RequestBody ImportacaoColaboradorRequest request
  ) {
    exigirLimite(request.linhas());
    return service.importarColaboradores(request.linhas());
  }

  @PostMapping("/treinamentos")
  public ImportacaoResultadoResponse importarTreinamentos(
    @Valid @RequestBody ImportacaoTreinamentoRequest request
  ) {
    exigirLimite(request.linhas());
    return service.importarTreinamentos(request.linhas());
  }

  @PostMapping("/epis")
  public ImportacaoResultadoResponse importarEpis(
    @Valid @RequestBody ImportacaoEpiRequest request
  ) {
    exigirLimite(request.linhas());
    return service.importarEpis(request.linhas());
  }

  private void exigirLimite(List<?> linhas) {
    if (linhas.size() > LIMITE_DE_LINHAS) {
      throw new RequisicaoInvalidaException(
        "O lote aceita no máximo " + LIMITE_DE_LINHAS
          + " linhas por requisição."
      );
    }
  }
}
