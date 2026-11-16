package br.com.senac.sgsst.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "parametros", schema = "public")
public class Parametro {
  @Id
  @Column(name = "chave", length = 60)
  private String chave;
  public String getChave() { return chave; }
  public void setChave(String value) { this.chave = value; }
  @Column(name = "valor", nullable = false, length = 255)
  private String valor;
  public String getValor() { return valor; }
  public void setValor(String value) { this.valor = value; }
  @Column(name = "descricao", nullable = false, length = 255)
  private String descricao;
  public String getDescricao() { return descricao; }
  public void setDescricao(String value) { this.descricao = value; }
}
