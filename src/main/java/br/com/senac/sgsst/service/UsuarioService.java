package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.UsuarioRequest;
import br.com.senac.sgsst.dto.UsuarioResponse;
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
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class UsuarioService {

  static final String GRUPO_ADMINISTRADOR = "Administrador TST";

  private final UsuarioRepository repository;
  private final GrupoAcessoRepository grupos;
  private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

  public UsuarioService(
    UsuarioRepository repository,
    GrupoAcessoRepository grupos
  ) {
    this.repository = repository;
    this.grupos = grupos;
  }

  public List<UsuarioResponse> listar() {
    return repository.findAll(Sort.by("nomeCompleto", "id"))
      .stream()
      .map(UsuarioResponse::from)
      .toList();
  }

  public UsuarioResponse buscarPorId(Integer id) {
    return UsuarioResponse.from(encontrar(id));
  }

  @Transactional
  public UsuarioResponse criar(UsuarioRequest request) {
    validarSenhaInformada(request);
    validarUnicidade(request, null);

    Usuario usuario = new Usuario();
    usuario.setCriadoEm(Instant.now());
    preencher(usuario, request);
    usuario.setSenhaHash(encoder.encode(request.senha()));

    return UsuarioResponse.from(repository.saveAndFlush(usuario));
  }

  @Transactional
  public UsuarioResponse atualizar(Integer id, UsuarioRequest request) {
    Usuario usuario = encontrar(id);
    validarUnicidade(request, id);

    preencher(usuario, request);

    if (request.senha() != null) {
      usuario.setSenhaHash(encoder.encode(request.senha()));
    }

    return UsuarioResponse.from(repository.saveAndFlush(usuario));
  }

  @Transactional
  public void alterarSenha(Integer id, String senha) {
    Usuario usuario = encontrar(id);
    usuario.setSenhaHash(encoder.encode(senha));
    repository.saveAndFlush(usuario);
  }

  @Transactional
  public void excluir(Integer id) {
    Usuario usuario = encontrar(id);

    ContextoUsuario.atual().ifPresent(sessao -> {
      if (sessao.id().equals(id)) {
        throw new RequisicaoInvalidaException(
          "Não é possível excluir o próprio usuário."
        );
      }
    });

    repository.delete(usuario);
    repository.flush();
  }

  @Transactional
  public UsuarioResponse criarPrimeiroAdministrador(UsuarioRequest request) {
    if (repository.count() > 0) {
      throw new ConflitoException(
        "Já existe usuário cadastrado. Cadastre os demais pela tela de usuários."
      );
    }

    validarSenhaInformada(request);

    GrupoAcesso grupo = grupos.findByNomenclatura(GRUPO_ADMINISTRADOR)
      .orElseThrow(() -> new RecursoNaoEncontradoException(
        "Grupo de acesso " + GRUPO_ADMINISTRADOR + " não encontrado."
      ));

    Usuario usuario = new Usuario();
    usuario.setNomeCompleto(request.nomeCompleto());
    usuario.setLogin(request.login());
    usuario.setEmail(request.email());
    usuario.setCpf(request.cpf());
    usuario.setGrupo(grupo);
    usuario.setStatus("Ativo");
    usuario.setCriadoEm(Instant.now());
    usuario.setSenhaHash(encoder.encode(request.senha()));

    return UsuarioResponse.from(repository.saveAndFlush(usuario));
  }

  public Usuario autenticar(String login, String senha) {
    Usuario usuario = repository.findByLogin(login)
      .orElseThrow(() -> new CredencialInvalidaException(
        "Usuário ou senha inválidos."
      ));

    if (!encoder.matches(senha, usuario.getSenhaHash())) {
      throw new CredencialInvalidaException("Usuário ou senha inválidos.");
    }

    if (!"Ativo".equals(usuario.getStatus())) {
      throw new AcessoNegadoException("Usuário inativo. Procure o administrador.");
    }

    return usuario;
  }

  public Usuario buscarPorIdEntidade(Integer id) {
    return encontrar(id);
  }

  public Usuario buscarPorLoginOuEmail(String loginOuEmail) {
    return repository.findByLoginOrEmail(loginOuEmail, loginOuEmail)
      .orElseThrow(() -> new RecursoNaoEncontradoException(
        "Usuário não encontrado."
      ));
  }

  @Transactional
  public void gravarNovaSenha(Usuario usuario, String senha) {
    usuario.setSenhaHash(encoder.encode(senha));
    repository.saveAndFlush(usuario);
  }

  private Usuario encontrar(Integer id) {
    return repository.findById(id)
      .orElseThrow(() -> new RecursoNaoEncontradoException(
        "Usuário não encontrado."
      ));
  }

  private void validarSenhaInformada(UsuarioRequest request) {
    if (request.senha() == null) {
      throw new RequisicaoInvalidaException(
        "Informe a senha de acesso do usuário."
      );
    }
  }

  private void validarUnicidade(UsuarioRequest request, Integer id) {
    boolean duplicado = id == null
      ? repository.existsByLogin(request.login())
      : repository.existsByLoginAndIdNot(request.login(), id);

    if (duplicado) {
      throw new ConflitoException(
        id == null
          ? "Já existe um usuário com este login."
          : "Já existe outro usuário com este login."
      );
    }

    duplicado = id == null
      ? repository.existsByEmail(request.email())
      : repository.existsByEmailAndIdNot(request.email(), id);

    if (duplicado) {
      throw new ConflitoException(
        id == null
          ? "Já existe um usuário com este e-mail."
          : "Já existe outro usuário com este e-mail."
      );
    }

    duplicado = id == null
      ? repository.existsByCpf(request.cpf())
      : repository.existsByCpfAndIdNot(request.cpf(), id);

    if (duplicado) {
      throw new ConflitoException(
        id == null
          ? "Já existe um usuário com este CPF."
          : "Já existe outro usuário com este CPF."
      );
    }
  }

  private void preencher(Usuario usuario, UsuarioRequest request) {
    usuario.setNomeCompleto(request.nomeCompleto());
    usuario.setLogin(request.login());
    usuario.setEmail(request.email());
    usuario.setCpf(request.cpf());
    usuario.setGrupo(encontrarGrupo(request.grupoId()));
    usuario.setStatus(request.status());
  }

  private GrupoAcesso encontrarGrupo(Integer grupoId) {
    return grupos.findById(grupoId)
      .orElseThrow(() -> new RequisicaoInvalidaException(
        "Grupo de acesso não encontrado."
      ));
  }
}
