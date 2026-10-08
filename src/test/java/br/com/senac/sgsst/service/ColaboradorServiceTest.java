package br.com.senac.sgsst.service;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.entity.*;
import br.com.senac.sgsst.repository.*;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class ColaboradorServiceTest {
  final ColaboradorRepository repository = mock(ColaboradorRepository.class);
  final ColaboradorService service = new ColaboradorService(repository);
  final ColaboradorRequest request = new ColaboradorRequest("TR01", "Ana", "12345678901", "ana@example.test", "Técnica", "Produção", "Ativo");
  @Test void criaPreservandoTodosOsCampos() {
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
    var result = service.criar(request);
    assertEquals(request.matricula(), result.matricula());
    assertEquals(request.nome(), result.nome());
    assertEquals(request.cpf(), result.cpf());
    assertEquals(request.email(), result.email());
    assertEquals(request.cargo(), result.cargo());
    assertEquals(request.setor(), result.setor());
    assertEquals(request.status(), result.status());
  }
  @Test void rejeitaMatriculaDuplicado() {
    when(repository.existsByMatricula("TR01")).thenReturn(true);
    assertThrows(br.com.senac.sgsst.exception.ConflitoException.class, () -> service.criar(request));
    verify(repository, never()).saveAndFlush(any());
  }
  @Test void listaOrdenada() {
    var entity = new Colaborador(); entity.setNome("Segurança");
    when(repository.findAll(org.springframework.data.domain.Sort.by("nome", "id"))).thenReturn(java.util.List.of(entity));
    assertEquals("Segurança", service.listar().get(0).nome());
  }
  @Test void buscaPorId() {
    var entity = new Colaborador(); entity.setMatricula("TR01");
    when(repository.findById(1)).thenReturn(java.util.Optional.of(entity));
    assertEquals("TR01", service.buscarPorId(1).matricula());
  }
  @Test void atualizaTodosOsCampos() {
    var entity = new Colaborador();
    when(repository.findById(1)).thenReturn(java.util.Optional.of(entity));
    when(repository.saveAndFlush(entity)).thenReturn(entity);
    var result = service.atualizar(1, request);
    assertEquals(request.matricula(), result.matricula());
    assertEquals(request.nome(), result.nome());
    assertEquals(request.cpf(), result.cpf());
    assertEquals(request.email(), result.email());
    assertEquals(request.cargo(), result.cargo());
    assertEquals(request.setor(), result.setor());
    assertEquals(request.status(), result.status());
  }
  @Test void excluiEExecutaFlush() {
    var entity = new Colaborador();
    when(repository.findById(1)).thenReturn(java.util.Optional.of(entity));
    service.excluir(1); verify(repository).delete(entity); verify(repository).flush();
  }
  @Test void inexistenteRetornaErroEmTodasOperacoes() {
    assertThrows(br.com.senac.sgsst.exception.RecursoNaoEncontradoException.class, () -> service.buscarPorId(1));
    assertThrows(br.com.senac.sgsst.exception.RecursoNaoEncontradoException.class, () -> service.atualizar(1, request));
    assertThrows(br.com.senac.sgsst.exception.RecursoNaoEncontradoException.class, () -> service.excluir(1));
  }
  @Test void atualizacaoNaoPermiteMatriculaDeOutroRegistro() {
    when(repository.findById(1)).thenReturn(java.util.Optional.of(new Colaborador()));
    when(repository.existsByMatriculaAndIdNot("TR01", 1)).thenReturn(true);
    assertThrows(br.com.senac.sgsst.exception.ConflitoException.class, () -> service.atualizar(1, request));
    verify(repository, never()).saveAndFlush(any());
  }
}
