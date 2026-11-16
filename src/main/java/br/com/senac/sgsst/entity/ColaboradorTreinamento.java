package br.com.senac.sgsst.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.OffsetDateTime;

@Entity
@Table(name = "colaborador_treinamentos", schema = "public")
public class ColaboradorTreinamento {
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
  @JoinColumn(name = "treinamento_id", nullable = false)
  private Treinamento treinamento;
  public Treinamento getTreinamento() { return treinamento; }
  public void setTreinamento(Treinamento value) { this.treinamento = value; }
  @Column(name = "data_conclusao")
  private LocalDate dataConclusao;
  public LocalDate getDataConclusao() { return dataConclusao; }
  public void setDataConclusao(LocalDate value) { this.dataConclusao = value; }
  @Column(name = "status", nullable = false, length = 20)
  private String status;
  public String getStatus() { return status; }
  public void setStatus(String value) { this.status = value; }
  @Column(name = "validade")
  private LocalDate validade;
  public LocalDate getValidade() { return validade; }
  public void setValidade(LocalDate value) { this.validade = value; }
  @Column(name = "criado_em", nullable = false, insertable = false, updatable = false)
  private OffsetDateTime criadoEm;
  public OffsetDateTime getCriadoEm() { return criadoEm; }
}
