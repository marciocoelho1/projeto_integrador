package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.GrupoRequest;
import br.com.senac.sgsst.dto.GrupoResponse;
import br.com.senac.sgsst.entity.GrupoAcesso;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.GrupoAcessoRepository;
import br.com.senac.sgsst.repository.ModuloRepository;
import br.com.senac.sgsst.repository.UsuarioRepository;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class GrupoAcessoServiceTest {

  final GrupoAcessoRepository repository = mock(GrupoAcessoRepository.class);
  final ModuloRepository modulos = mock(ModuloRepository.class);
  final UsuarioRepository usuarios = mock(UsuarioRepository.class);
  final GrupoAcessoService service = new GrupoAcessoService(repository, modulos, usuarios);

  @Test void criarRejeitaNomenclaturaRepetida() {
    when(repository.existsByNomenclatura("Colaborador")).thenReturn(true);

    assertThrows(
      ConflitoException.class,
      () -> service.criar(new GrupoRequest("Colaborador", "Teste", List.of()))
    );
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void criarRejeitaModuloDesconhecido() {
    when(modulos.existsById("sgst_inexistente")).thenReturn(false);

    assertThrows(
      RequisicaoInvalidaException.class,
      () -> service.criar(new GrupoRequest("Grupo Novo", "Teste", List.of("sgst_inexistente")))
    );
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void criarGuardaSomenteModulosExistentes() {
    when(modulos.existsById("sgst_epis")).thenReturn(true);
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    var response = service.criar(new GrupoRequest("Grupo Novo", "Teste", List.of("sgst_epis")));

    assertEquals(List.of("sgst_epis"), response.modulos());
    assertEquals("Grupo Novo", response.nomenclatura());
  }

  @Test void definirModulosSubstituiOConjunto() {
    var grupo = grupo(2, "Colaborador");
    when(repository.findById(2)).thenReturn(Optional.of(grupo));
    when(modulos.existsById("sgst_config")).thenReturn(true);
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    var response = service.definirModulos(2, List.of("sgst_config"));

    assertEquals(List.of("sgst_config"), response.modulos());
    assertEquals(new LinkedHashSet<>(List.of("sgst_config")), grupo.getModuloChaves());
  }

  @Test void alterarNomenclaturaNaoPodeRepetirOutroGrupo() {
    when(repository.findById(2)).thenReturn(Optional.of(grupo(2, "Colaborador")));
    when(repository.existsByNomenclaturaAndIdNot("Administrador TST", 2)).thenReturn(true);

    assertThrows(
      ConflitoException.class,
      () -> service.atualizar(2, new GrupoRequest("Administrador TST", "Teste", List.of()))
    );
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void excluirBloqueiaGrupoComUsuarios() {
    when(repository.findById(2)).thenReturn(Optional.of(grupo(2, "Colaborador")));
    when(usuarios.existsByGrupoId(2)).thenReturn(true);

    assertThrows(ConflitoException.class, () -> service.excluir(2));
    verify(repository, never()).delete(any());
  }

  @Test void inexistenteRetornaErroEmTodasOperacoes() {
    assertThrows(RecursoNaoEncontradoException.class, () -> service.buscarPorId(404));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.excluir(404));
    assertThrows(
      RecursoNaoEncontradoException.class,
      () -> service.definirModulos(404, List.of())
    );
  }

  private GrupoAcesso grupo(Integer id, String nomenclatura) {
    var grupo = new GrupoAcesso();
    grupo.setNomenclatura(nomenclatura);
    grupo.setFinalidade("Teste");
    grupo.setModuloChaves(new LinkedHashSet<>(List.of("sgst_epis")));

    try {
      var field = GrupoAcesso.class.getDeclaredField("id");
      field.setAccessible(true);
      field.set(grupo, id);
    } catch (ReflectiveOperationException e) {
      throw new IllegalStateException(e);
    }

    return grupo;
  }
}
