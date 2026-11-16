package br.com.senac.sgsst.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "cargo_treinamentos", schema = "public")
public class CargoTreinamento {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Integer id;
  public Integer getId() { return id; }
  @ManyToOne(fetch = FetchType.EAGER, optional = false)
  @JoinColumn(name = "cargo_id", nullable = false)
  private Cargo cargo;
  public Cargo getCargo() { return cargo; }
  public void setCargo(Cargo value) { this.cargo = value; }
  @ManyToOne(fetch = FetchType.EAGER, optional = false)
  @JoinColumn(name = "treinamento_id", nullable = false)
  private Treinamento treinamento;
  public Treinamento getTreinamento() { return treinamento; }
  public void setTreinamento(Treinamento value) { this.treinamento = value; }
  @Column(name = "obrigatorio", nullable = false)
  private Boolean obrigatorio;
  public Boolean getObrigatorio() { return obrigatorio; }
  public void setObrigatorio(Boolean value) { this.obrigatorio = value; }
}
