package br.com.senac.sgsst.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "epi_entregas", schema = "public")
public class EpiEntrega {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Integer id;
  public Integer getId() { return id; }
  @ManyToOne(fetch = FetchType.EAGER, optional = false)
  @JoinColumn(name = "colaborador_id", nullable = false)
  private Colaborador colaborador;
  public Colaborador getColaborador() { return colaborador; }
  public void setColaborador(Colaborador value) { this.colaborador = value; }
  @ManyToOne(fetch = FetchType.EAGER, optional = false)
  @JoinColumn(name = "epi_id", nullable = false)
  private Epi epi;
  public Epi getEpi() { return epi; }
  public void setEpi(Epi value) { this.epi = value; }
  @Column(name = "quantidade", nullable = false)
  private Integer quantidade;
  public Integer getQuantidade() { return quantidade; }
  public void setQuantidade(Integer value) { this.quantidade = value; }
  @Column(name = "data_entrega", nullable = false)
  private LocalDate dataEntrega;
  public LocalDate getDataEntrega() { return dataEntrega; }
  public void setDataEntrega(LocalDate value) { this.dataEntrega = value; }
  @Column(name = "assinatura", nullable = false, length = 150)
  private String assinatura;
  public String getAssinatura() { return assinatura; }
  public void setAssinatura(String value) { this.assinatura = value; }
  @Column(name = "ca_no_ato", nullable = false, length = 30)
  private String caNoAto;
  public String getCaNoAto() { return caNoAto; }
  public void setCaNoAto(String value) { this.caNoAto = value; }
  @Column(name = "validade_ca_no_ato", nullable = false)
  private LocalDate validadeCaNoAto;
  public LocalDate getValidadeCaNoAto() { return validadeCaNoAto; }
  public void setValidadeCaNoAto(LocalDate value) { this.validadeCaNoAto = value; }
  @Column(name = "registrado_em", nullable = false)
  private Instant registradoEm;
  public Instant getRegistradoEm() { return registradoEm; }
  public void setRegistradoEm(Instant value) { this.registradoEm = value; }
}
