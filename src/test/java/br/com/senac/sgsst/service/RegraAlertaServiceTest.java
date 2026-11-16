package br.com.senac.sgsst.service;

import br.com.senac.sgsst.entity.RegraAlerta;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.repository.RegraAlertaRepository;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class RegraAlertaServiceTest {

  final RegraAlertaRepository repository = mock(RegraAlertaRepository.class);
  final RegraAlertaService service = new RegraAlertaService(repository);

  @Test void listaTodasAsRegras() {
    when(repository.findAllByOrderByNomeRegraAsc())
      .thenReturn(List.of(regra("estoqueEpi", true), regra("treinamentoVencido", false)));

    var lista = service.listar();

    assertEquals(2, lista.size());
    assertFalse(lista.get(1).ativa());
  }

  @Test void alternaRegra() {
    var regra = regra("treinamentoVencido", false);
    when(repository.findById("treinamentoVencido")).thenReturn(Optional.of(regra));
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    assertFalse(service.ativa("treinamentoVencido"));
    var response = service.definirAtiva("treinamentoVencido", true);

    assertTrue(response.ativa());
    assertTrue(regra.getAtiva());
  }

  @Test void regraInexistenteRetornaErroEAtivaFalso() {
    when(repository.findById("naoExiste")).thenReturn(Optional.empty());

    assertFalse(service.ativa("naoExiste"));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.definirAtiva("naoExiste", true));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.buscarPorCodigo("naoExiste"));
  }

  private RegraAlerta regra(String codigo, Boolean ativa) {
    var regra = new RegraAlerta();
    regra.setCodigo(codigo);
    regra.setNomeRegra("Regra " + codigo);
    regra.setDescricaoRegra("Descrição");
    regra.setAtiva(ativa);
    return regra;
  }
}
