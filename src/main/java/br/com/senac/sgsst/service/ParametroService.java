package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.ParametroResponse;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.repository.ParametroRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class ParametroService {

  private final ParametroRepository repository;

  public ParametroService(ParametroRepository repository) {
    this.repository = repository;
  }

  public List<ParametroResponse> listar() {
    return repository.findAllByOrderByChaveAsc()
      .stream()
      .map(ParametroResponse::from)
      .toList();
  }

  public ParametroResponse buscarPorChave(String chave) {
    return ParametroResponse.from(encontrar(chave));
  }

  public String valorDe(String chave, String padrao) {
    return repository.findById(chave)
      .map(parametro -> parametro.getValor())
      .orElse(padrao);
  }

  public int valorInteiroDe(String chave, int padrao) {
    try {
      return Integer.parseInt(valorDe(chave, String.valueOf(padrao)));
    } catch (NumberFormatException invalido) {
      return padrao;
    }
  }

  @Transactional
  public ParametroResponse atualizar(String chave, String valor) {
    var parametro = encontrar(chave);
    parametro.setValor(valor);
    return ParametroResponse.from(repository.saveAndFlush(parametro));
  }

  private br.com.senac.sgsst.entity.Parametro encontrar(String chave) {
    return repository.findById(chave)
      .orElseThrow(() -> new RecursoNaoEncontradoException(
        "Parâmetro não encontrado."
      ));
  }
}
