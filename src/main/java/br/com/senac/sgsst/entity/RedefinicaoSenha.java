package br.com.senac.sgsst.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "redefinicoes_senha", schema = "public")
public class RedefinicaoSenha {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Integer id;
  public Integer getId() { return id; }
  @ManyToOne(fetch = FetchType.EAGER, optional = false)
  @JoinColumn(name = "usuario_id", nullable = false)
  private Usuario usuario;
  public Usuario getUsuario() { return usuario; }
  public void setUsuario(Usuario value) { this.usuario = value; }
  @Column(name = "token", nullable = false, unique = true, length = 64)
  private String token;
  public String getToken() { return token; }
  public void setToken(String value) { this.token = value; }
  @Column(name = "criada_em", nullable = false)
  private Instant criadaEm;
  public Instant getCriadaEm() { return criadaEm; }
  public void setCriadaEm(Instant value) { this.criadaEm = value; }
  @Column(name = "expira_em", nullable = false)
  private Instant expiraEm;
  public Instant getExpiraEm() { return expiraEm; }
  public void setExpiraEm(Instant value) { this.expiraEm = value; }
  @Column(name = "usada_em")
  private Instant usadaEm;
  public Instant getUsadaEm() { return usadaEm; }
  public void setUsadaEm(Instant value) { this.usadaEm = value; }
}
