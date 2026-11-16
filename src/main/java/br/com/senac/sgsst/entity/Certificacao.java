package br.com.senac.sgsst.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "certificacoes", schema = "public")
public class Certificacao {
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
  @Column(name = "instituicao", nullable = false, length = 150)
  private String instituicao;
  public String getInstituicao() { return instituicao; }
  public void setInstituicao(String value) { this.instituicao = value; }
  @Column(name = "carga_horaria", nullable = false, length = 30)
  private String cargaHoraria;
  public String getCargaHoraria() { return cargaHoraria; }
  public void setCargaHoraria(String value) { this.cargaHoraria = value; }
  @Column(name = "emitida_em", nullable = false)
  private LocalDate emitidaEm;
  public LocalDate getEmitidaEm() { return emitidaEm; }
  public void setEmitidaEm(LocalDate value) { this.emitidaEm = value; }
  @Column(name = "validade", nullable = false)
  private LocalDate validade;
  public LocalDate getValidade() { return validade; }
  public void setValidade(LocalDate value) { this.validade = value; }
  @Column(name = "arquivo_url", length = 300)
  private String arquivoUrl;
  public String getArquivoUrl() { return arquivoUrl; }
  public void setArquivoUrl(String value) { this.arquivoUrl = value; }
}
