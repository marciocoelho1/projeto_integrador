package br.com.senac.sgsst.service;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.entity.*;
import br.com.senac.sgsst.repository.*;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class TreinamentoServiceTest {
  final TreinamentoRepository repository = mock(TreinamentoRepository.class);
  final TreinamentoService service = new TreinamentoService(repository);
  final TreinamentoRequest request = new TreinamentoRequest("TR01", "Segurança", "Obrigatório", "NR-10", "8 horas", null, "Ativo");
  @Test void criaPreservandoTodosOsCamposEValidadeNula() {
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
    var result = service.criar(request);
    assertEquals(request.codigo(), result.codigo());
    assertEquals(request.nome(), result.nome());
    assertEquals(request.classificacao(), result.classificacao());
    assertEquals(request.nr(), result.nr());
    assertEquals(request.cargaHoraria(), result.cargaHoraria());
    assertNull(result.validadeMeses());
    assertEquals(request.status(), result.status());
  }
  @Test void rejeitaCodigoDuplicado() {
    when(repository.existsByCodigo("TR01")).thenReturn(true);
    assertThrows(br.com.senac.sgsst.exception.ConflitoException.class, () -> service.criar(request));
    verify(repository, never()).saveAndFlush(any());
  }
  @Test void listaOrdenada() {
    var entity = new Treinamento(); entity.setNome("Segurança");
    when(repository.findAll(org.springframework.data.domain.Sort.by("nome", "id"))).thenReturn(java.util.List.of(entity));
    assertEquals("Segurança", service.listar().get(0).nome());
  }
  @Test void buscaPorId() {
    var entity = new Treinamento(); entity.setCodigo("TR01");
    when(repository.findById(1)).thenReturn(java.util.Optional.of(entity));
    assertEquals("TR01", service.buscarPorId(1).codigo());
  }
  @Test void atualizaTodosOsCampos() {
    var entity = new Treinamento();
    when(repository.findById(1)).thenReturn(java.util.Optional.of(entity));
    when(repository.saveAndFlush(entity)).thenReturn(entity);
    var result = service.atualizar(1, request);
    assertEquals(request.codigo(), result.codigo());
    assertEquals(request.nome(), result.nome());
    assertEquals(request.classificacao(), result.classificacao());
    assertEquals(request.nr(), result.nr());
    assertEquals(request.cargaHoraria(), result.cargaHoraria());
    assertNull(result.validadeMeses());
    assertEquals(request.status(), result.status());
  }
  @Test void excluiEExecutaFlush() {
    var entity = new Treinamento();
    when(repository.findById(1)).thenReturn(java.util.Optional.of(entity));
    service.excluir(1); verify(repository).delete(entity); verify(repository).flush();
  }
  @Test void inexistenteRetornaErroEmTodasOperacoes() {
    assertThrows(br.com.senac.sgsst.exception.RecursoNaoEncontradoException.class, () -> service.buscarPorId(1));
    assertThrows(br.com.senac.sgsst.exception.RecursoNaoEncontradoException.class, () -> service.atualizar(1, request));
    assertThrows(br.com.senac.sgsst.exception.RecursoNaoEncontradoException.class, () -> service.excluir(1));
  }
  @Test void atualizacaoNaoPermiteCodigoDeOutroRegistro() {
    when(repository.findById(1)).thenReturn(java.util.Optional.of(new Treinamento()));
    when(repository.existsByCodigoAndIdNot("TR01", 1)).thenReturn(true);
    assertThrows(br.com.senac.sgsst.exception.ConflitoException.class, () -> service.atualizar(1, request));
    verify(repository, never()).saveAndFlush(any());
  }
}
