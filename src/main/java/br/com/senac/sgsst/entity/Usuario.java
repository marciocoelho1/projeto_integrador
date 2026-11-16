package br.com.senac.sgsst.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "usuarios", schema = "public")
public class Usuario {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Integer id;
  public Integer getId() { return id; }
  @Column(name = "nome_completo", nullable = false, length = 150)
  private String nomeCompleto;
  public String getNomeCompleto() { return nomeCompleto; }
  public void setNomeCompleto(String value) { this.nomeCompleto = value; }
  @Column(name = "login", nullable = false, unique = true, length = 60)
  private String login;
  public String getLogin() { return login; }
  public void setLogin(String value) { this.login = value; }
  @Column(name = "email", nullable = false, unique = true, length = 180)
  private String email;
  public String getEmail() { return email; }
  public void setEmail(String value) { this.email = value; }
  @Column(name = "cpf", nullable = false, unique = true, length = 14)
  private String cpf;
  public String getCpf() { return cpf; }
  public void setCpf(String value) { this.cpf = value; }
  @Column(name = "senha_hash", nullable = false, length = 100)
  private String senhaHash;
  public String getSenhaHash() { return senhaHash; }
  public void setSenhaHash(String value) { this.senhaHash = value; }
  @ManyToOne(fetch = FetchType.EAGER, optional = false)
  @JoinColumn(name = "grupo_id", nullable = false)
  private GrupoAcesso grupo;
  public GrupoAcesso getGrupo() { return grupo; }
  public void setGrupo(GrupoAcesso value) { this.grupo = value; }
  @Column(name = "status", nullable = false, length = 20)
  private String status;
  public String getStatus() { return status; }
  public void setStatus(String value) { this.status = value; }
  @Column(name = "criado_em", nullable = false)
  private Instant criadoEm;
  public Instant getCriadoEm() { return criadoEm; }
  public void setCriadoEm(Instant value) { this.criadoEm = value; }
}
