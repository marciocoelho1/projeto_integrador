package br.com.senac.sgsst.service;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.entity.*;
import br.com.senac.sgsst.repository.*;
import br.com.senac.sgsst.exception.*;
import org.junit.jupiter.api.Test;
import java.time.LocalDate;
import java.util.*;
import org.springframework.data.domain.Sort;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class EpiServiceTest {
  final EpiRepository repository = mock(EpiRepository.class);
  final EpiService service = new EpiService(repository);
  final EpiRequest request = new EpiRequest("Capacete", "123", LocalDate.of(2026,1,1), LocalDate.of(2027,1,1), 0);
  @Test void criaTodosOsCampos() {
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
    assertFields(service.criar(request));
  }
  @Test void listaOrdenada() {
    var entity = new Epi(); entity.setDescricao("Capacete");
    when(repository.findAll(Sort.by("descricao", "id"))).thenReturn(List.of(entity));
    assertEquals("Capacete", service.listar().get(0).descricao());
  }
  @Test void buscaPorId() {
    var entity = new Epi(); entity.setCa("123");
    when(repository.findById(1)).thenReturn(Optional.of(entity));
    assertEquals("123", service.buscarPorId(1).ca());
  }
  @Test void atualizaTodosOsCampos() {
    var entity = new Epi();
    when(repository.findById(1)).thenReturn(Optional.of(entity));
    when(repository.saveAndFlush(entity)).thenReturn(entity);
    assertFields(service.atualizar(1, request));
  }
  @Test void excluiEExecutaFlush() {
    var entity = new Epi();
    when(repository.findById(1)).thenReturn(Optional.of(entity));
    service.excluir(1); verify(repository).delete(entity); verify(repository).flush();
  }
  @Test void inexistenteEmTodasOperacoes() {
    assertThrows(RecursoNaoEncontradoException.class, () -> service.buscarPorId(1));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.atualizar(1, request));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.excluir(1));
  }
  private void assertFields(EpiResponse response) {
    assertEquals(request.descricao(), response.descricao());
    assertEquals(request.ca(), response.ca());
    assertEquals(request.inclusao(), response.inclusao());
    assertEquals(request.validade(), response.validade());
    assertEquals(0, response.quantidade());
  }
}
