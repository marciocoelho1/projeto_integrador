package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.ModuloResponse;
import br.com.senac.sgsst.repository.ModuloRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class ModuloService {

  private final ModuloRepository repository;

  public ModuloService(ModuloRepository repository) {
    this.repository = repository;
  }

  public List<ModuloResponse> listar() {
    return repository.findAllByOrderByTituloAsc()
      .stream()
      .map(ModuloResponse::from)
      .toList();
  }
}
