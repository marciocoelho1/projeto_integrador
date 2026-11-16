package br.com.senac.sgsst.service;

import br.com.senac.sgsst.entity.Parametro;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.repository.ParametroRepository;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ParametroServiceTest {

  final ParametroRepository repository = mock(ParametroRepository.class);
  final ParametroService service = new ParametroService(repository);

  @Test void listaOrdenada() {
    when(repository.findAllByOrderByChaveAsc())
      .thenReturn(List.of(parametro("estoqueMinimoEpi", "5")));

    var lista = service.listar();

    assertEquals(1, lista.size());
    assertEquals("estoqueMinimoEpi", lista.get(0).chave());
  }

  @Test void atualizaValor() {
    var parametro = parametro("diasAvisoReciclagem", "60");
    when(repository.findById("diasAvisoReciclagem")).thenReturn(Optional.of(parametro));
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    var response = service.atualizar("diasAvisoReciclagem", "45");

    assertEquals("45", response.valor());
    assertEquals("45", parametro.getValor());
  }

  @Test void chaveInexistenteRetornaErroDeNaoEncontrado() {
    assertThrows(RecursoNaoEncontradoException.class, () -> service.atualizar("naoExiste", "1"));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.buscarPorChave("naoExiste"));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void valorDeUsaPadraoQuandoAusenteOuInvalido() {
    when(repository.findById("estoqueMinimoEpi")).thenReturn(Optional.of(parametro("estoqueMinimoEpi", "8")));
    when(repository.findById("diasAvisoVencimentoEpi")).thenReturn(Optional.empty());
    when(repository.findById("diasAvisoReciclagem"))
      .thenReturn(Optional.of(parametro("diasAvisoReciclagem", "nemNumero")));

    assertEquals(8, service.valorInteiroDe("estoqueMinimoEpi", 5));
    assertEquals(30, service.valorInteiroDe("diasAvisoVencimentoEpi", 30));
    assertEquals(60, service.valorInteiroDe("diasAvisoReciclagem", 60));
    assertEquals("padrao", service.valorDe("inexistente", "padrao"));
  }

  private Parametro parametro(String chave, String valor) {
    var parametro = new Parametro();
    parametro.setChave(chave);
    parametro.setValor(valor);
    parametro.setDescricao("Teste");
    return parametro;
  }
}
