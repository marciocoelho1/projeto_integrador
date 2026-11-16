package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.ReciclagemResponse;
import br.com.senac.sgsst.repository.ColaboradorTreinamentoRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;

/**
 * Reciclagem derivada: para cada vínculo com validade conhecida, o prazo-limite é a própria
 * validade do treinamento do colaborador. A lista devolve vencidos (prazo no passado) e
 * vencendo na janela de {@value #JANELA_ALERTA_DIAS} dias.
 */
@Service
@Transactional(readOnly = true)
public class ReciclagemService {
  public static final int JANELA_ALERTA_DIAS = 60;
  private final ColaboradorTreinamentoRepository repository;

  public ReciclagemService(ColaboradorTreinamentoRepository repository) {
    this.repository = repository;
  }

  public List<ReciclagemResponse> listar() { return listar(LocalDate.now()); }

  List<ReciclagemResponse> listar(LocalDate referencia) {
    return repository.findAll(Sort.by("id")).stream()
      .filter(vinculo -> vinculo.getValidade() != null)
      .map(vinculo -> {
        var validade = vinculo.getValidade();
        var dias = ChronoUnit.DAYS.between(referencia, validade);
        var colaborador = vinculo.getColaborador();
        var treinamento = vinculo.getTreinamento();
        return new ReciclagemResponse(
          colaborador == null ? null : colaborador.getId(),
          colaborador == null ? null : colaborador.getNome(),
          colaborador == null ? null : colaborador.getCargo(),
          treinamento == null ? null : treinamento.getId(),
          treinamento == null ? null : treinamento.getNome(),
          validade,
          dias,
          dias < 0 ? "Vencido" : "Próximo do Vencimento"
        );
      })
      .filter(item -> item.diasRestantes() <= JANELA_ALERTA_DIAS)
      .sorted(Comparator.comparing(ReciclagemResponse::prazoMaximo))
      .toList();
  }
}
