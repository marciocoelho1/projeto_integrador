package br.com.senac.sgsst.entity;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * Registro de auditoria (item 8). Guarda o nome do usuário denormalizado (usuario_nome) para que a
 * listagem filtre sem depender do vínculo, e o vínculo usuario_id só para rastreabilidade.
 */
@Entity
@Table(name = "logs_auditoria", schema = "public")
public class LogAuditoria {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Integer id;
  public Integer getId() { return id; }
  @Column(name = "data_hora", nullable = false)
  private Instant dataHora;
  public Instant getDataHora() { return dataHora; }
  public void setDataHora(Instant value) { this.dataHora = value; }
  @ManyToOne(fetch = FetchType.LAZY, optional = true)
  @JoinColumn(name = "usuario_id", nullable = true)
  private Usuario usuario;
  public Usuario getUsuario() { return usuario; }
  public void setUsuario(Usuario value) { this.usuario = value; }
  @Column(name = "usuario_nome", nullable = true, length = 150)
  private String usuarioNome;
  public String getUsuarioNome() { return usuarioNome; }
  public void setUsuarioNome(String value) { this.usuarioNome = value; }
  @Column(name = "modulo", nullable = false, length = 60)
  private String modulo;
  public String getModulo() { return modulo; }
  public void setModulo(String value) { this.modulo = value; }
  @Column(name = "acao", nullable = false, length = 20)
  private String acao;
  public String getAcao() { return acao; }
  public void setAcao(String value) { this.acao = value; }
  @Column(name = "descricao", nullable = false, length = 300)
  private String descricao;
  public String getDescricao() { return descricao; }
  public void setDescricao(String value) { this.descricao = value; }
  @Column(name = "metodo", nullable = false, length = 10)
  private String metodo;
  public String getMetodo() { return metodo; }
  public void setMetodo(String value) { this.metodo = value; }
  @Column(name = "caminho", nullable = false, length = 300)
  private String caminho;
  public String getCaminho() { return caminho; }
  public void setCaminho(String value) { this.caminho = value; }
  @Column(name = "status_http", nullable = false)
  private Integer statusHttp;
  public Integer getStatusHttp() { return statusHttp; }
  public void setStatusHttp(Integer value) { this.statusHttp = value; }
}
