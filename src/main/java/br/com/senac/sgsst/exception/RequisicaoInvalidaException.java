package br.com.senac.sgsst.exception;

public class RequisicaoInvalidaException extends RuntimeException {
  public RequisicaoInvalidaException(String mensagem) {
    super(mensagem);
  }
}
