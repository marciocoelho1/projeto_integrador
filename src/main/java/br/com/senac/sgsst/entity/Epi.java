package br.com.senac.sgsst.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "epis", schema = "public")
public class Epi {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Integer id;
  public Integer getId() { return id; }
  @Column(name = "descricao", nullable = false, length = 180)
  private String descricao;
  public String getDescricao() { return descricao; }
  public void setDescricao(String value) { this.descricao = value; }
  @Column(name = "ca", nullable = false, length = 30)
  private String ca;
  public String getCa() { return ca; }
  public void setCa(String value) { this.ca = value; }
  @Column(name = "inclusao", nullable = false)
  private LocalDate inclusao;
  public LocalDate getInclusao() { return inclusao; }
  public void setInclusao(LocalDate value) { this.inclusao = value; }
  @Column(name = "validade", nullable = false)
  private LocalDate validade;
  public LocalDate getValidade() { return validade; }
  public void setValidade(LocalDate value) { this.validade = value; }
  @Column(name = "quantidade", nullable = false)
  private Integer quantidade;
  public Integer getQuantidade() { return quantidade; }
  public void setQuantidade(Integer value) { this.quantidade = value; }
}
