package br.com.senac.sgsst.security;

import java.util.Optional;

/**
 * Sessão do usuário no request atual. O filtro de autenticação preenche no início e limpa no
 * finally, para que serviços de auditoria e de "meus registros" leiam o usuário sem receber
 * parâmetro extra.
 */
public final class ContextoUsuario {

  private static final ThreadLocal<UsuarioSessao> ATUAL = new ThreadLocal<>();

  private ContextoUsuario() {
  }

  public static void definir(UsuarioSessao sessao) {
    ATUAL.set(sessao);
  }

  public static Optional<UsuarioSessao> atual() {
    return Optional.ofNullable(ATUAL.get());
  }

  public static void limpar() {
    ATUAL.remove();
  }
}
