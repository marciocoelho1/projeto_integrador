package br.com.senac.sgsst.exception;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.List;
import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler {

  @ExceptionHandler(RecursoNaoEncontradoException.class)
  public ResponseEntity<Map<String, Object>> naoEncontrado(
    RecursoNaoEncontradoException exception
  ) {
    return erro(HttpStatus.NOT_FOUND, exception.getMessage());
  }

  @ExceptionHandler(ConflitoException.class)
  public ResponseEntity<Map<String, Object>> conflito(
    ConflitoException exception
  ) {
    return erro(HttpStatus.CONFLICT, exception.getMessage());
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<Map<String, Object>> validacao(
    MethodArgumentNotValidException exception
  ) {
    List<String> detalhes = exception.getBindingResult()
      .getFieldErrors()
      .stream()
      .map(erro -> erro.getField() + ": "
        + erro.getDefaultMessage())
      .toList();

    Map<String, Object> body = Map.of(
      "mensagem", "Verifique os campos informados.",
      "detalhes", detalhes
    );

    return ResponseEntity.badRequest().body(body);
  }

  @ExceptionHandler({
    HttpMessageNotReadableException.class,
    MethodArgumentTypeMismatchException.class
  })
  public ResponseEntity<Map<String, Object>> requisicaoInvalida(
    Exception exception
  ) {
    return erro(
      HttpStatus.BAD_REQUEST,
      "JSON ou parâmetro da requisição inválido."
    );
  }

  @ExceptionHandler(DataIntegrityViolationException.class)
  public ResponseEntity<Map<String, Object>> integridade(
    DataIntegrityViolationException exception
  ) {
    return erro(
      HttpStatus.CONFLICT,
      "A operação viola uma restrição do banco. "
        + "Confira duplicidades ou registros vinculados."
    );
  }

  private ResponseEntity<Map<String, Object>> erro(
    HttpStatus status,
    String mensagem
  ) {
    Map<String, Object> body = Map.of("mensagem", mensagem);
    return ResponseEntity.status(status).body(body);
  }
}
