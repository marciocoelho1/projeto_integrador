package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.UsuarioRequest;
import br.com.senac.sgsst.entity.GrupoAcesso;
import br.com.senac.sgsst.entity.Usuario;
import br.com.senac.sgsst.exception.AcessoNegadoException;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.CredencialInvalidaException;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.GrupoAcessoRepository;
import br.com.senac.sgsst.repository.UsuarioRepository;
import br.com.senac.sgsst.security.ContextoUsuario;
import br.com.senac.sgsst.security.UsuarioSessao;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class UsuarioServiceTest {

  final UsuarioRepository repository = mock(UsuarioRepository.class);
  final GrupoAcessoRepository grupos = mock(GrupoAcessoRepository.class);
  final UsuarioService service = new UsuarioService(repository, grupos);
  final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

  final UsuarioRequest request = new UsuarioRequest(
    "Ana Souza", "ana.souza", "ana@example.test", "12345678901", 1, "Ativo", "senha123"
  );

  @AfterEach void limparContexto() {
    ContextoUsuario.limpar();
  }

  @Test void criarExigeSenha() {
    var semSenha = new UsuarioRequest("Ana Souza", "ana.souza", "ana@example.test", "12345678901", 1, "Ativo", null);

    assertThrows(RequisicaoInvalidaException.class, () -> service.criar(semSenha));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void criarRejeitaLoginEmailECpfRepetidos() {
    when(repository.existsByLogin("ana.souza")).thenReturn(true);
    assertThrows(ConflitoException.class, () -> service.criar(request));

    reset(repository);
    when(repository.existsByEmail("ana@example.test")).thenReturn(true);
    assertThrows(ConflitoException.class, () -> service.criar(request));

    reset(repository);
    when(repository.existsByCpf("12345678901")).thenReturn(true);
    assertThrows(ConflitoException.class, () -> service.criar(request));

    verify(repository, never()).saveAndFlush(any());
  }

  @Test void criarGravaHashENaoASenha() {
    when(grupos.findById(1)).thenReturn(Optional.of(grupo(1, "Administrador TST")));
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    var response = service.criar(request);

    var capturado = ArgumentCaptor.forClass(Usuario.class);
    verify(repository).saveAndFlush(capturado.capture());
    var salvo = capturado.getValue();

    assertNotEquals("senha123", salvo.getSenhaHash());
    assertTrue(encoder.matches("senha123", salvo.getSenhaHash()));
    assertEquals("ana.souza", response.login());
    assertEquals("Administrador TST", response.grupo());
    assertNotNull(salvo.getCriadoEm());
  }

  @Test void criarRejeitaGrupoInexistente() {
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    assertThrows(RequisicaoInvalidaException.class, () -> service.criar(request));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void atualizarSemSenhaMantemHashEChecaUnicidadePorId() {
    var usuario = usuario(7, "hash-antigo");
    when(repository.findById(7)).thenReturn(Optional.of(usuario));
    when(grupos.findById(1)).thenReturn(Optional.of(grupo(1, "Administrador TST")));
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    var semSenha = new UsuarioRequest("Ana Souza", "ana.souza", "ana@example.test", "12345678901", 1, "Inativo", null);
    var response = service.atualizar(7, semSenha);

    assertEquals("hash-antigo", usuario.getSenhaHash());
    assertEquals("Inativo", response.status());
    verify(repository).existsByLoginAndIdNot("ana.souza", 7);
    verify(repository).existsByEmailAndIdNot("ana@example.test", 7);
    verify(repository).existsByCpfAndIdNot("12345678901", 7);
  }

  @Test void atualizarComSenhaTrocaHash() {
    var usuario = usuario(7, "hash-antigo");
    when(repository.findById(7)).thenReturn(Optional.of(usuario));
    when(grupos.findById(1)).thenReturn(Optional.of(grupo(1, "Administrador TST")));
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    service.atualizar(7, request);

    assertNotEquals("hash-antigo", usuario.getSenhaHash());
    assertTrue(encoder.matches("senha123", usuario.getSenhaHash()));
  }

  @Test void excluirNaoPermiteOProprioUsuario() {
    when(repository.findById(7)).thenReturn(Optional.of(usuario(7, "h")));
    ContextoUsuario.definir(new UsuarioSessao(7, "ana", "Ana Souza", "Administrador TST", Set.of()));

    assertThrows(RequisicaoInvalidaException.class, () -> service.excluir(7));
    verify(repository, never()).delete(any());

    ContextoUsuario.limpar();
    service.excluir(7);
    verify(repository).delete(any());
  }

  @Test void criarPrimeiroAdministradorSomenteComTabelaVazia() {
    when(repository.count()).thenReturn(1L);
    assertThrows(ConflitoException.class, () -> service.criarPrimeiroAdministrador(request));

    reset(repository);
    when(repository.count()).thenReturn(0L);
    when(grupos.findByNomenclatura("Administrador TST"))
      .thenReturn(Optional.of(grupo(1, "Administrador TST")));
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    var response = service.criarPrimeiroAdministrador(
      new UsuarioRequest("Admin", "admin", "admin@example.test", "12345678901", null, "Ativo", "senha123")
    );

    assertEquals("Ativo", response.status());
    assertEquals("Administrador TST", response.grupo());
  }

  @Test void autenticarDistingueSenhaErradaInativoEInexistente() {
    var usuario = usuario(1, encoder.encode("senha123"));
    when(repository.findByLogin("ana.souza")).thenReturn(Optional.of(usuario));

    assertThrows(CredencialInvalidaException.class, () -> service.autenticar("ana.souza", "errada"));
    assertThrows(CredencialInvalidaException.class, () -> service.autenticar("outro", "senha123"));

    usuario.setStatus("Inativo");
    assertThrows(AcessoNegadoException.class, () -> service.autenticar("ana.souza", "senha123"));

    usuario.setStatus("Ativo");
    assertEquals("ana.souza", service.autenticar("ana.souza", "senha123").getLogin());
  }

  @Test void buscarInexistenteRetorna404Logico() {
    assertThrows(RecursoNaoEncontradoException.class, () -> service.buscarPorId(404));
  }

  private GrupoAcesso grupo(Integer id, String nomenclatura) {
    var grupo = new GrupoAcesso();
    grupo.setNomenclatura(nomenclatura);
    grupo.setFinalidade("Teste");
    grupo.setModuloChaves(new LinkedHashSet<>(List.of("sgst_epis")));
    var campo = "id";
    try {
      var field = GrupoAcesso.class.getDeclaredField(campo);
      field.setAccessible(true);
      field.set(grupo, id);
    } catch (ReflectiveOperationException e) {
      throw new IllegalStateException(e);
    }
    return grupo;
  }

  private Usuario usuario(Integer id, String hash) {
    var usuario = new Usuario();
    usuario.setNomeCompleto("Ana Souza");
    usuario.setLogin("ana.souza");
    usuario.setEmail("ana@example.test");
    usuario.setCpf("12345678901");
    usuario.setStatus("Ativo");
    usuario.setSenhaHash(hash);
    usuario.setGrupo(grupo(id, "Administrador TST"));
    try {
      var field = Usuario.class.getDeclaredField("id");
      field.setAccessible(true);
      field.set(usuario, id);
    } catch (ReflectiveOperationException e) {
      throw new IllegalStateException(e);
    }
    return usuario;
  }
}
