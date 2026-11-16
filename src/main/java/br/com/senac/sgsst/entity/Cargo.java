package br.com.senac.sgsst.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "cargos", schema = "public")
public class Cargo {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Integer id;
  public Integer getId() { return id; }
  @Column(name = "nome", nullable = false, unique = true, length = 120)
  private String nome;
  public String getNome() { return nome; }
  public void setNome(String value) { this.nome = value; }
  @Column(name = "setor", nullable = false, length = 120)
  private String setor;
  public String getSetor() { return setor; }
  public void setSetor(String value) { this.setor = value; }
  @Column(name = "status", nullable = false, length = 20)
  private String status;
  public String getStatus() { return status; }
  public void setStatus(String value) { this.status = value; }
}
