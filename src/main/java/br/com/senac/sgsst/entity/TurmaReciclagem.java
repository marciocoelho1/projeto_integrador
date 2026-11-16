package br.com.senac.sgsst.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "turmas_reciclagem", schema = "public")
public class TurmaReciclagem {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Integer id;
  public Integer getId() { return id; }
  @ManyToOne(fetch = FetchType.EAGER, optional = false)
  @JoinColumn(name = "treinamento_id", nullable = false)
  private Treinamento treinamento;
  public Treinamento getTreinamento() { return treinamento; }
  public void setTreinamento(Treinamento value) { this.treinamento = value; }
  @Column(name = "instrutor", nullable = false, length = 150)
  private String instrutor;
  public String getInstrutor() { return instrutor; }
  public void setInstrutor(String value) { this.instrutor = value; }
  @Column(name = "data_agendada", nullable = false)
  private LocalDate dataAgendada;
  public LocalDate getDataAgendada() { return dataAgendada; }
  public void setDataAgendada(LocalDate value) { this.dataAgendada = value; }
  @Column(name = "vagas", nullable = false)
  private Integer vagas;
  public Integer getVagas() { return vagas; }
  public void setVagas(Integer value) { this.vagas = value; }
  @Column(name = "status", nullable = false, length = 20)
  private String status;
  public String getStatus() { return status; }
  public void setStatus(String value) { this.status = value; }
}
