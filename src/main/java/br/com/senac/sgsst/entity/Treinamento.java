package br.com.senac.sgsst.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "treinamentos", schema = "public")
public class Treinamento {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Integer id;
  public Integer getId() { return id; }
  @Column(name = "codigo", nullable = false, length = 30, unique = true)
  private String codigo;
  public String getCodigo() { return codigo; }
  public void setCodigo(String value) { this.codigo = value; }
  @Column(name = "nome", nullable = false, length = 180)
  private String nome;
  public String getNome() { return nome; }
  public void setNome(String value) { this.nome = value; }
  @Column(name = "classificacao", nullable = false, length = 60)
  private String classificacao;
  public String getClassificacao() { return classificacao; }
  public void setClassificacao(String value) { this.classificacao = value; }
  @Column(name = "nr", nullable = true, length = 60)
  private String nr;
  public String getNr() { return nr; }
  public void setNr(String value) { this.nr = value; }
  @Column(name = "carga_horaria", nullable = false, length = 30)
  private String cargaHoraria;
  public String getCargaHoraria() { return cargaHoraria; }
  public void setCargaHoraria(String value) { this.cargaHoraria = value; }
  @Column(name = "validade_meses", nullable = true)
  private Integer validadeMeses;
  public Integer getValidadeMeses() { return validadeMeses; }
  public void setValidadeMeses(Integer value) { this.validadeMeses = value; }
  @Column(name = "status", nullable = false, length = 20)
  private String status;
  public String getStatus() { return status; }
  public void setStatus(String value) { this.status = value; }
}
