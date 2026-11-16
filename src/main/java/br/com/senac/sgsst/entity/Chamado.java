package br.com.senac.sgsst.entity;

import jakarta.persistence.*;
import java.time.Instant;

/** Chamado de suporte (item 9): tipo Ajuda/Erro, status e datas de abertura/conclusão. */
@Entity
@Table(name = "chamados", schema = "public")
public class Chamado {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Integer id;
  public Integer getId() { return id; }
  @Column(name = "tipo", nullable = false, length = 30)
  private String tipo;
  public String getTipo() { return tipo; }
  public void setTipo(String value) { this.tipo = value; }
  @Column(name = "descricao", nullable = false, length = 500)
  private String descricao;
  public String getDescricao() { return descricao; }
  public void setDescricao(String value) { this.descricao = value; }
  @ManyToOne(fetch = FetchType.LAZY, optional = true)
  @JoinColumn(name = "usuario_id", nullable = true)
  private Usuario usuario;
  public Usuario getUsuario() { return usuario; }
  public void setUsuario(Usuario value) { this.usuario = value; }
  @Column(name = "solicitante", nullable = false, length = 150)
  private String solicitante;
  public String getSolicitante() { return solicitante; }
  public void setSolicitante(String value) { this.solicitante = value; }
  @Column(name = "status", nullable = false, length = 20)
  private String status;
  public String getStatus() { return status; }
  public void setStatus(String value) { this.status = value; }
  @Column(name = "aberto_em", nullable = false)
  private Instant abertoEm;
  public Instant getAbertoEm() { return abertoEm; }
  public void setAbertoEm(Instant value) { this.abertoEm = value; }
  @Column(name = "concluido_em", nullable = true)
  private Instant concluidoEm;
  public Instant getConcluidoEm() { return concluidoEm; }
  public void setConcluidoEm(Instant value) { this.concluidoEm = value; }
}
