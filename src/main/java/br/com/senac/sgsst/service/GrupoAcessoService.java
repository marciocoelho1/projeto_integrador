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
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashSet;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class GrupoAcessoService {

  private final GrupoAcessoRepository repository;
  private final ModuloRepository modulos;
  private final UsuarioRepository usuarios;

  public GrupoAcessoService(
    GrupoAcessoRepository repository,
    ModuloRepository modulos,
    UsuarioRepository usuarios
  ) {
    this.repository = repository;
    this.modulos = modulos;
    this.usuarios = usuarios;
  }

  public List<GrupoResponse> listar() {
    return repository.findAll(Sort.by("nomenclatura", "id"))
      .stream()
      .map(GrupoResponse::from)
      .toList();
  }

  public GrupoResponse buscarPorId(Integer id) {
    return GrupoResponse.from(encontrar(id));
  }

  @Transactional
  public GrupoResponse criar(GrupoRequest request) {
    if (repository.existsByNomenclatura(request.nomenclatura())) {
      throw new ConflitoException("Já existe um grupo com esta nomenclatura.");
    }

    GrupoAcesso grupo = new GrupoAcesso();
    grupo.setNomenclatura(request.nomenclatura());
    grupo.setFinalidade(request.finalidade());
    grupo.setModuloChaves(conferirModulos(request.modulos()));

    return GrupoResponse.from(repository.saveAndFlush(grupo));
  }

  @Transactional
  public GrupoResponse atualizar(Integer id, GrupoRequest request) {
    GrupoAcesso grupo = encontrar(id);

    if (repository.existsByNomenclaturaAndIdNot(
      request.nomenclatura(),
      id
    )) {
      throw new ConflitoException(
        "Já existe outro grupo com esta nomenclatura."
      );
    }

    grupo.setNomenclatura(request.nomenclatura());
    grupo.setFinalidade(request.finalidade());
    grupo.setModuloChaves(conferirModulos(request.modulos()));

    return GrupoResponse.from(repository.saveAndFlush(grupo));
  }

  @Transactional
  public GrupoResponse definirModulos(Integer id, List<String> chaves) {
    GrupoAcesso grupo = encontrar(id);
    grupo.setModuloChaves(conferirModulos(chaves));
    return GrupoResponse.from(repository.saveAndFlush(grupo));
  }

  @Transactional
  public void excluir(Integer id) {
    GrupoAcesso grupo = encontrar(id);

    if (usuarios.existsByGrupoId(id)) {
      throw new ConflitoException(
        "Há usuários vinculados a este grupo. Mova-os antes de excluir."
      );
    }

    repository.delete(grupo);
    repository.flush();
  }

  private GrupoAcesso encontrar(Integer id) {
    return repository.findById(id)
      .orElseThrow(() -> new RecursoNaoEncontradoException(
        "Grupo de acesso não encontrado."
      ));
  }

  private LinkedHashSet<String> conferirModulos(List<String> chaves) {
    LinkedHashSet<String> selecionados = new LinkedHashSet<>(
      chaves == null ? List.of() : chaves
    );

    selecionados.forEach(chave -> {
      if (!modulos.existsById(chave)) {
        throw new RequisicaoInvalidaException(
          "Módulo desconhecido: " + chave
        );
      }
    });

    return selecionados;
  }
}
