package br.com.senac.sgsst.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "regras_alerta", schema = "public")
public class RegraAlerta {
  @Id
  @Column(name = "codigo", length = 40)
  private String codigo;
  public String getCodigo() { return codigo; }
  public void setCodigo(String value) { this.codigo = value; }
  @Column(name = "nome_regra", nullable = false, length = 120)
  private String nomeRegra;
  public String getNomeRegra() { return nomeRegra; }
  public void setNomeRegra(String value) { this.nomeRegra = value; }
  @Column(name = "descricao_regra", nullable = false, length = 255)
  private String descricaoRegra;
  public String getDescricaoRegra() { return descricaoRegra; }
  public void setDescricaoRegra(String value) { this.descricaoRegra = value; }
  @Column(name = "ativa", nullable = false)
  private Boolean ativa;
  public Boolean getAtiva() { return ativa; }
  public void setAtiva(Boolean value) { this.ativa = value; }
}
